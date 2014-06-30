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

@property (nonatomic, strong) id jsonRecieved;
@property (nonatomic, strong) SBDownloadableDistributionModel *downloadDistroModel;
@property (nonatomic, strong) NSOperationQueue *downloadQueue;
@property NSInteger numberOfActiveDownloadOperations;

@end

@implementation SBDistributionDownloaderWindowController

#pragma mark - Object Setup
- (id)initWithWindow:(NSWindow *)window {
	self = [super initWithWindow:window];
	if (self) {
		// First things first. Grab the JSON.
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		    // Grab our JSON, but do it on a background thread so we don't slow down the GUI.
		    [self setupJSON];
		});

		// Setup our operation queues.
		self.downloadQueue = [[NSOperationQueue alloc] init];
		self.downloadQueue.maxConcurrentOperationCount = 4; // Slightly arbitrary
	}
	return self;
}

- (void)setupJSON {
	NSURL *url = [NSURL URLWithString:@"https://github.com/SevenBits/mlul-iso-mirrors/raw/master/mirrors/Linux-Mint.json"];

	NSError *err;
	NSString *strCon = [NSString stringWithContentsOfURL:url encoding:NSASCIIStringEncoding error:&err];
	if (!err) {
		//NSLog(@"Recieved JSON data: %@", strCon);
		[self processJSON:strCon];
	} else {
		dispatch_async(dispatch_get_main_queue(), ^{
		    NSAlert *alert = [NSAlert alertWithError:err];
		    [alert runModal];
		});
	}
}

- (void)processJSON:(NSString *)json {
	JSONModelError *error;
	self.downloadDistroModel = [[SBDownloadableDistributionModel alloc] initWithString:json error:&error];
	if (error) {
		dispatch_async(dispatch_get_main_queue(), ^{
		    NSAlert *alert = [NSAlert alertWithError:error];
		    [alert runModal];
		});
	}
	else {
		//SBLogObject(self.downloadDistroModel);
		self.distroImageView.image = [[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:self.downloadDistroModel.imageURL]];
	}
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

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
	NSString *distribution = [[[NSApp delegate] supportedDistributions] objectAtIndex:row];
	[self.distroNameLabel setStringValue:[NSString stringWithFormat:@"%@ %@",
	                                      [[[NSApp delegate] supportedDistributions] objectAtIndex:row],
	                                      [[[NSApp delegate] supportedDistributionsAndVersions] objectForKey:distribution]]];
	return YES;
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
	}
	else {
		newFrame = NSMakeRect(c.size.width - aV.size.width - 5, // x position
		                      c.size.height - aV.size.height, // y position
		                      aV.size.width, // width
		                      aV.size.height); // height
	}

	[self.accessoryView setFrame:newFrame];
	[self.accessoryView setNeedsDisplay:YES];
}

- (IBAction)downloadDistroButtonPressed:(id)sender {
	// Ideally, we'd support the new sheet API, but we need to still support 10.8...
	[NSApp beginSheet:self.downloadSettingsPanel modalForWindow:self.window modalDelegate:nil didEndSelector:nil contextInfo:nil];
	[self.distroMirrorCountrySelector removeAllItems];

	for (SBDownloadMirrorModel *model in [self.downloadDistroModel mirrors]) {
		[self.distroMirrorCountrySelector addItemWithTitle:model.countryLong];
	}
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
