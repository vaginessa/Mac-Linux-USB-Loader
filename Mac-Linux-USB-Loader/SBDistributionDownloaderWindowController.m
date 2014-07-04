//
//  SBDistributionDownloaderWindowController.m
//  Mac Linux USB Loader
//
//  Created by SevenBits on 5/9/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import "DownloadOperation.h"
#import "SBDistributionDownloaderWindowController.h"
#import "SBAppDelegate.h"
#import "SBDownloadMirrorModel.h"
#import "SBDownloadableDistributionModel.h"

#define SBAccessoryViewEdgeOffset 25

@interface SBDistributionDownloaderWindowController ()

@property (strong) IBOutlet NSView *accessoryView;
@property (weak) IBOutlet NSTableView *tableView;
@property (strong) IBOutlet NSPanel *downloadSettingsPanel;
@property (weak) IBOutlet NSPopUpButton *distroMirrorCountrySelector;
@property (weak) IBOutlet NSImageView *distroImageView;
@property (weak) IBOutlet NSTextField *distroNameLabel;
@property (weak) IBOutlet NSButton *downloadDistroButton;

@property (atomic, strong) id jsonRecieved;
@property NSInteger numberOfFinishedJsonRequests;
@property (atomic, strong) SBDownloadableDistributionModel *downloadDistroModel;
@property (atomic, strong) NSMutableDictionary *modelDictionary;
@property (strong) NSLock *mdLock;
@property (atomic, strong) NSMutableDictionary *imageDictionary;
@property (strong) NSLock *idLock;

@property (nonatomic, strong) NSOperationQueue *downloadQueue;
@property NSInteger numberOfActiveDownloadOperations;

@end

@implementation SBDistributionDownloaderWindowController

#pragma mark - Object Setup
- (id)initWithWindow:(NSWindow *)window {
	self = [super initWithWindow:window];
	self.modelDictionary = [[NSMutableDictionary alloc] initWithCapacity:5];
	self.imageDictionary = [[NSMutableDictionary alloc] initWithCapacity:5];
	self.mdLock = [[NSLock alloc] init];
	self.idLock = [[NSLock alloc] init];
	if (self) {
		// First things first. Grab the JSON.
		[self setupJSON];

		// Setup our operation queues.
		self.downloadQueue = [[NSOperationQueue alloc] init];
		self.downloadQueue.maxConcurrentOperationCount = 4; // Slightly arbitrary
	}
	return self;
}

- (void)awakeFromNib {
	[self.downloadDistroButton setEnabled:NO];
}

- (void)setupJSON {
	for (NSString *distroName in [[NSApp delegate] supportedDistributions]) {
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			NSError *err;
		    // Grab our JSON, but do it on a background thread so we don't slow down the GUI.
			NSString *temp = [NSString stringWithFormat:@"https://github.com/SevenBits/mlul-iso-mirrors/raw/master/mirrors/%@.json", [distroName stringByReplacingOccurrencesOfString:@" " withString:@"-"]];
			NSURL *url = [NSURL URLWithString:temp];

			NSString *strCon = [NSString stringWithContentsOfURL:url encoding:NSASCIIStringEncoding error:&err];
			if (!err || strCon) {
				//NSLog(@"Recieved JSON data: %@", strCon);
				[self processJSON:strCon forDistributionNamed:distroName];
			} else {
				dispatch_async(dispatch_get_main_queue(), ^{
					NSAlert *alert = [NSAlert alertWithError:err];
					[alert runModal];
				});
			}
		});
	}
}

- (void)processJSON:(NSString *)json forDistributionNamed:(NSString *)distroName {
	[self.mdLock lock];
	JSONModelError *error;
	self.downloadDistroModel = [[SBDownloadableDistributionModel alloc] initWithString:json error:&error];
	if (error) {
		dispatch_async(dispatch_get_main_queue(), ^{
			NSLog(@"%@: %@", distroName, [error localizedDescription]);
		    NSAlert *alert = [NSAlert alertWithError:error];
		    [alert runModal];
		});
	} else {
		//SBLogObject(self.downloadDistroModel);
		[self.idLock lock];
		NSString *convertedName = [distroName stringByReplacingOccurrencesOfString:@" " withString:@"-"];
		NSImage *img = [[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:self.downloadDistroModel.imageURL]];
		if (img) self.imageDictionary[convertedName] = img;
		[self.idLock unlock];

		if (self.downloadDistroModel) self.modelDictionary[convertedName] = self.downloadDistroModel;
	}

	self.numberOfFinishedJsonRequests++;

	if (self.numberOfFinishedJsonRequests == [[[NSApp delegate] supportedDistributions] count]) {
		[self.downloadDistroButton setEnabled:YES];
	}
	[self.mdLock unlock];
}

- (void)windowDidLoad {
	[super windowDidLoad];

	// Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
	[self.window setDelegate:self];

	// Setup the accessory view.
	[self placeAccessoryView];

	NSView *themeFrame = [[self.window contentView] superview];
	[themeFrame addSubview:self.accessoryView];

	// Setup delegates.
	[self.tableView setDataSource:self];
	[self.tableView setDelegate:self];
}

#pragma mark - Delegates
- (void)windowDidResize:(NSNotification *)notification {
	// Keep the accessory view in the right place in the window.
	[self placeAccessoryView];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return [[[NSApp delegate] supportedDistributions] count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	if ([[[aTableColumn headerCell] stringValue] isEqualToString:NSLocalizedString(@"Distribution Name", nil)]) {
		return [[[NSApp delegate] supportedDistributions] objectAtIndex:rowIndex];
	}
	else if ([[[aTableColumn headerCell] stringValue] isEqualToString:NSLocalizedString(@"Current Version", nil)]) {
		NSString *distribution = [[[NSApp delegate] supportedDistributions] objectAtIndex:rowIndex];
		return [[[NSApp delegate] supportedDistributionsAndVersions] objectForKey:distribution];
	}
	else {
		return @"N/A";
	}
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	return NO;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
	NSInteger row = [self.tableView selectedRow];
	if (row == -1) {
		[self.distroNameLabel setStringValue:@""];
		[self.distroImageView setImage:nil];
		return;
	}

	NSString *distribution = [[[NSApp delegate] supportedDistributions] objectAtIndex:row];
	[self.distroNameLabel setStringValue:[NSString stringWithFormat:@"%@ %@",
	                                      [[[NSApp delegate] supportedDistributions] objectAtIndex:row],
	                                      [[[NSApp delegate] supportedDistributionsAndVersions] objectForKey:distribution]]];


	NSString *convertedName = [distribution stringByReplacingOccurrencesOfString:@" " withString:@"-"];
	NSImage *img = self.imageDictionary[convertedName];
	if (img) self.distroImageView.image = img;
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	// Empty
}

#pragma mark - UI
- (void)placeAccessoryView {
	NSView *themeFrame = [[self.window contentView] superview];
	NSRect c = [themeFrame frame];  // c for "container"
	NSRect aV = [self.accessoryView frame]; // aV for "accessory view"
	NSRect newFrame;


	// If the user is running pre-Yosemite, nudge the button to the left to account for the fullscreen button.
	NSOperatingSystemVersion opVer = [[NSProcessInfo processInfo] operatingSystemVersion];
	if (opVer.minorVersion <= 9) {
		newFrame = NSMakeRect(c.size.width - aV.size.width - SBAccessoryViewEdgeOffset, // x position
		                      c.size.height - aV.size.height,    // y position
		                      aV.size.width,    // width
		                      aV.size.height);    // height
	} else {
		newFrame = NSMakeRect(c.size.width - aV.size.width - 5, // x position
		                      c.size.height - aV.size.height, // y position
		                      aV.size.width, // width
		                      aV.size.height); // height
	}

	[self.accessoryView setFrame:newFrame];
	[self.accessoryView setNeedsDisplay:YES];
}

- (IBAction)downloadDistroButtonPressed:(id)sender {
	NSInteger selectedDistro = [self.tableView selectedRow];
	if (selectedDistro == -1) {
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:NSLocalizedString(@"Okay", nil)];
		[alert setMessageText:NSLocalizedString(@"No distribution selected.", nil)];
		[alert setInformativeText:NSLocalizedString(@"You must select the distribution that you wish to download.", nil)];
		[alert setAlertStyle:NSWarningAlertStyle];
		[alert beginSheetModalForWindow:self.window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];

		return;
	}

	NSString *temp = [[[NSApp delegate] supportedDistributions] objectAtIndex:selectedDistro];
	temp = [temp stringByReplacingOccurrencesOfString:@" " withString:@"-"];
	SBLogObject(temp);
	
	if (!self.modelDictionary[temp]) {
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:NSLocalizedString(@"Okay", nil)];
		[alert setMessageText:NSLocalizedString(@"Can't download this distribution.", nil)];
		[alert setInformativeText:NSLocalizedString(@"You cannot download this distribution because Mac USB Linux Loader has not finished downloading its list of mirrors.", nil)];
		[alert setAlertStyle:NSWarningAlertStyle];
		[alert beginSheetModalForWindow:self.window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];

		return;
	}
	// Ideally, we'd support the new sheet API, but we need to still support 10.8...
	self.downloadDistroModel = self.modelDictionary[temp];
	[self.distroMirrorCountrySelector removeAllItems];

	for (SBDownloadMirrorModel *model in [self.downloadDistroModel mirrors]) {
		[self.distroMirrorCountrySelector addItemWithTitle:model.countryLong];
	}

	[NSApp beginSheet:self.downloadSettingsPanel modalForWindow:self.window modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

- (IBAction)closeDownloadDistroSheetPressed:(id)sender {
	[NSApp endSheet:self.downloadSettingsPanel];
	[self.downloadSettingsPanel orderOut:nil];
}

- (IBAction)commenceDownload:(id)sender {
	NSInteger selectedItem = [self.distroMirrorCountrySelector indexOfSelectedItem];
	NSAssert(selectedItem != -1, @"Selected item is %ld", (long)selectedItem);

	NSString *distribution = [[[NSApp delegate] supportedDistributions] objectAtIndex:[self.tableView selectedRow]];
	NSString *path = [[[NSFileManager defaultManager] applicationSupportDirectory] stringByAppendingString:@"/Downloads/"];
	path = [path stringByAppendingString:[NSString stringWithFormat:@"%@-%@.iso",
	                                                                 [[[NSApp delegate] supportedDistributions] objectAtIndex:[self.tableView selectedRow]],
	                                                                 [[[NSApp delegate] supportedDistributionsAndVersions] objectForKey:distribution]]];

	SBDownloadMirrorModel *model = self.downloadDistroModel.mirrors[selectedItem];
	NSURL *url = [NSURL URLWithString:model.url];
	DownloadOperation *downloadOperation = [[DownloadOperation alloc] initWithURL:url path:path];
	downloadOperation.downloadCompletionBlock = ^(DownloadOperation *operation, BOOL success, NSError *error) {
		if (error) {
			NSLog(@"%s: downloadCompletionBlock error: %@", __FUNCTION__, error);
		} else {
			/* The download was completed successfully. TODO: Show a notification. */

			// Open the downloaded ISO file.
			NSURL *url = [NSURL fileURLWithPath:operation.path];
			[[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:url display:YES completionHandler:^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error) {}];
		}

		self.numberOfActiveDownloadOperations--;
	};
	downloadOperation.downloadProgressBlock = ^(DownloadOperation *operation, long long progressContentLength, long long expectedContentLength) {
		CGFloat progress = (expectedContentLength > 0 ? (CGFloat)progressContentLength / (CGFloat)expectedContentLength : (progressContentLength % 1000000l) / 1000000.0f);
		NSLog(@"%@: %f", operation, progress);
	};

	[self.downloadQueue addOperation:downloadOperation];
	[self closeDownloadDistroSheetPressed:nil];
	self.numberOfActiveDownloadOperations++;
}

@end
