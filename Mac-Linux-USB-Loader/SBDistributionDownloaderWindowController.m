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
#import "SBDistributionDownloaderDownloadsDataSource.h"
#import "SBDistributionDownloaderTableCellView.h"

#define SBAccessoryViewEdgeOffset 25

@interface SBDistributionDownloaderWindowController ()

@property (strong) IBOutlet NSView *accessoryView;
@property (weak) IBOutlet NSTableView *tableView;
@property (strong) IBOutlet NSPanel *downloadSettingsPanel;
@property (weak) IBOutlet NSPopUpButton *distroMirrorCountrySelector;
@property (weak) IBOutlet NSImageView *distroImageView;
@property (weak) IBOutlet NSTextField *distroNameLabel;
@property (weak) IBOutlet NSButton *downloadDistroButton;
@property (weak) IBOutlet NSButton *accessoryViewButton;

@property (strong) IBOutlet NSPopover *downloadQueuePopover;
@property (strong) IBOutlet SBDistributionDownloaderDownloadsDataSource *downloadQueueDataSource;
@property (weak) IBOutlet NSTableView *downloadQueueTableView;

@property (strong) id activity;
@property (strong) NSUserDefaults *defaults;

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
		// Setup our operation queues and get default values.
		self.defaults = [NSUserDefaults standardUserDefaults];
		NSInteger concurrentOperationsCount = [self.defaults integerForKey:@"SimultaneousDownloadOperationsNumber"];

		self.downloadQueue = [[NSOperationQueue alloc] init];
		self.downloadQueue.maxConcurrentOperationCount = concurrentOperationsCount;
	}
	return self;
}

- (void)awakeFromNib {
	// Setup the UI.
	[self.downloadDistroButton setEnabled:NO];
	[self.downloadQueuePopover setBehavior:NSPopoverBehaviorTransient];
	[self.downloadQueueDataSource setPrefsViewController:self];
	[self.downloadQueueDataSource setTableView:self.downloadQueueTableView];
	[self.tableView setDoubleAction:@selector(tableViewDoubleClickAction)];

	// Check if enough time has elapsed to where we need to download new JSON.
	NSInteger JSONUpdateInterval = [[NSUserDefaults standardUserDefaults] integerForKey:@"UpdateMirrorListInterval"];
	NSDate *lastCheckedDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"LastMirrorUpdateCheckTime"];
	if (lastCheckedDate) {
		// We have a saved date.
		NSInteger interval = (NSInteger)abs([lastCheckedDate timeIntervalSinceNow]);
		if (interval > JSONUpdateInterval) {
			// Enough time has elapsed to where it is now time to update the JSON mirrors.
			// We do this in the background without a lot of pomp so it is transparent to the user.
			NSLog(@"%ld seconds have elapsed, updating JSON.", (long)interval);
			[self downloadJSON];

			[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"LastMirrorUpdateCheckTime"];
		} else {
			[self loadCachedJSON];
		}
	} else {
		// We are missing the saved date, so re-save it and update the JSON mirrors.
		// We do this in the background without a lot of pomp so it is transparent to the user.
		[self downloadJSON];

		[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"LastMirrorUpdateCheckTime"];
	}
}

- (void)loadCachedJSON {
	NSString *cacheDirectory = [[NSFileManager defaultManager] cacheDirectory];
	__block NSString *tempFileName;

	for (NSString *distroName in [(SBAppDelegate *)[NSApp delegate] supportedDistributions]) {
		// Grab our JSON, but do it on a background thread so we don't slow down the GUI.
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		    NSError *err;
		    tempFileName = [NSString stringWithFormat:@"%@/%@.json", cacheDirectory, [distroName stringByReplacingOccurrencesOfString:@" " withString:@"-"]];
		    NSURL *url = [NSURL fileURLWithPath:tempFileName];

		    NSString *strCon = [NSString stringWithContentsOfURL:url encoding:NSASCIIStringEncoding error:&err];
		    if (strCon) {
		        //NSLog(@"Recieved JSON data: %@", strCon);
		        [self processJSON:strCon forDistributionNamed:distroName downloadContent:NO];
			} else {
		        dispatch_async(dispatch_get_main_queue(), ^{
		            NSAlert *alert = [NSAlert alertWithError:err];
		            [alert runModal];
				});
			}
		});
	}
}

- (void)downloadJSON {
	// Check if we have an Internet connection.
	SCNetworkReachabilityRef target;
	SCNetworkConnectionFlags flags = 0;
	Boolean canReachInternet;
	target = SCNetworkReachabilityCreateWithName(NULL, "google.com");
	canReachInternet = SCNetworkReachabilityGetFlags(target, &flags);
	CFRelease(target);

	if (!(canReachInternet && (flags & kSCNetworkFlagsReachable) && !(flags & kSCNetworkFlagsConnectionRequired))) {
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:NSLocalizedString(@"Okay", nil)];
		[alert setMessageText:NSLocalizedString(@"No network connection.", nil)];
		[alert setInformativeText:NSLocalizedString(@"Mac Linux USB Loader cannot download the mirror lists because you are not connected to the Internet.", nil)];
		[alert setAlertStyle:NSWarningAlertStyle];
		[alert runModal];

		return;
	}

	// We have an Internet connection, so proceed by downloading the JSON.
	for (NSString *distroName in [(SBAppDelegate *)[NSApp delegate] supportedDistributions]) {
		// Grab our JSON, but do it on a background thread so we don't slow down the GUI.
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		    NSError *err;
		    NSString *temp = [NSString stringWithFormat:@"https://github.com/SevenBits/mlul-iso-mirrors/raw/master/mirrors/%@.json", [distroName stringByReplacingOccurrencesOfString:@" " withString:@"-"]];
		    NSURL *url = [NSURL URLWithString:temp];

		    NSString *strCon = [NSString stringWithContentsOfURL:url encoding:NSASCIIStringEncoding error:&err];
		    if (strCon) {
		        //NSLog(@"Recieved JSON data: %@", strCon);
		        [self processJSON:strCon forDistributionNamed:distroName downloadContent:YES];
			} else {
		        dispatch_async(dispatch_get_main_queue(), ^{
		            NSAlert *alert = [NSAlert alertWithError:err];
		            [alert runModal];
				});
			}
		});
	}
}

- (void)processJSON:(NSString *)json forDistributionNamed:(NSString *)distroName downloadContent:(BOOL)downloadImages {
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
		[self.idLock lock];
		NSString *convertedName = [distroName stringByReplacingOccurrencesOfString:@" " withString:@"-"];

		NSImage *img;

		// Fetch the image from the web if we are to download them; otherwise, grab it from the cache.
		if (downloadImages) {
			NSURL *imgSourceURL = [NSURL URLWithString:self.downloadDistroModel.imageURL];
			img = [[NSImage alloc] initWithContentsOfURL:imgSourceURL];
		} else {
			// Grab the images from the cache.
			NSString *cacheDirectory = [[NSFileManager defaultManager] cacheDirectory];
			NSString *imgFilePath = [[cacheDirectory stringByAppendingPathComponent:convertedName] stringByAppendingString:@".png"];
			img = [[NSImage alloc] initWithContentsOfFile:imgFilePath];
		}

		if (img) {
			self.imageDictionary[convertedName] = img;

			if (downloadImages) {
				[img saveAsPNGWithName:[[[[NSFileManager defaultManager] cacheDirectory] stringByAppendingPathComponent:convertedName] stringByAppendingString:@".png"]]; // Cache the image to a file.
			}
		}
		[self.idLock unlock];

		if (downloadImages) {
			[json writeToFile:[[[[NSFileManager defaultManager] cacheDirectory] stringByAppendingPathComponent:convertedName] stringByAppendingString:@".json"] atomically:YES encoding:NSUTF8StringEncoding error:nil]; // Cache the JSON to a file.
		}

		if (self.downloadDistroModel) self.modelDictionary[convertedName] = self.downloadDistroModel;
	}

	self.numberOfFinishedJsonRequests++;
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
	//[self placeAccessoryView];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return [[(SBAppDelegate *)[NSApp delegate] supportedDistributions] count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	if ([[[aTableColumn headerCell] stringValue] isEqualToString:NSLocalizedString(@"Distribution Name", nil)]) {
		return [[(SBAppDelegate *)[NSApp delegate] supportedDistributions] objectAtIndex:rowIndex];
	} else if ([[[aTableColumn headerCell] stringValue] isEqualToString:NSLocalizedString(@"Current Version", nil)]) {
		NSString *distribution = [[(SBAppDelegate *)[NSApp delegate] supportedDistributions] objectAtIndex:rowIndex];
		return [[(SBAppDelegate *)[NSApp delegate] supportedDistributionsAndVersions] objectForKey:distribution];
	} else {
		return @"N/A";
	}
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	return NO;
}

- (void)tableViewDoubleClickAction {
	// Get the table view selection and make sure that they selected something.
	NSInteger row = [self.tableView selectedRow];
	if (row == -1) {
		return;
	}

	// Construct the name and path of the downloaded ISO.
	NSString *distribution = [[(SBAppDelegate *)[NSApp delegate] supportedDistributions] objectAtIndex:[self.tableView selectedRow]];
	NSString *path = [[[NSFileManager defaultManager] applicationSupportDirectory] stringByAppendingPathComponent:@"/Downloads/"];
	path = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-%@.iso",
	                                             [[(SBAppDelegate *)[NSApp delegate] supportedDistributions] objectAtIndex:[self.tableView selectedRow]],
	                                             [[(SBAppDelegate *)[NSApp delegate] supportedDistributionsAndVersions] objectForKey:distribution]]];

	// Open the URL.
	NSURL *url = [NSURL fileURLWithPath:path];
	[[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:url display:YES completionHandler: ^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error) {}
	 ];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
	NSInteger row = [self.tableView selectedRow];
	[self.downloadDistroButton setEnabled:(row != -1)];

	if (row == -1) {
		[self.distroNameLabel setStringValue:@""];
		[self.distroImageView setImage:nil];
		return;
	}

	NSString *distribution = [[(SBAppDelegate *)[NSApp delegate] supportedDistributions] objectAtIndex:row];
	[self.distroNameLabel setStringValue:[NSString stringWithFormat:@"%@ %@",
	                                      [[(SBAppDelegate *)[NSApp delegate] supportedDistributions] objectAtIndex:row],
	                                      [[(SBAppDelegate *)[NSApp delegate] supportedDistributionsAndVersions] objectForKey:distribution]]];


	NSString *convertedName = [distribution stringByReplacingOccurrencesOfString:@" " withString:@"-"];
	NSImage *img = self.imageDictionary[convertedName];
	if (img) self.distroImageView.image = img;
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	// Empty
}

#pragma mark - UI
- (void)placeAccessoryView {
	NSOperatingSystemVersion opVer = [[NSProcessInfo processInfo] operatingSystemVersion];
	if (opVer.minorVersion <= 9) {
		NSView *themeFrame = [[self.window contentView] superview];
		NSRect c = [themeFrame frame];  // c for "container"
		NSRect aV = [self.accessoryView frame]; // aV for "accessory view"

		// If the user is running pre-Yosemite, nudge the button to the left to account for the fullscreen button.
		NSRect newFrame = NSMakeRect(c.size.width - aV.size.width - SBAccessoryViewEdgeOffset, // x position
							  c.size.height - aV.size.height, // y position
							  aV.size.width, // width
							  aV.size.height); // height

		[self.accessoryView setFrame:newFrame];
		[self.accessoryView setNeedsDisplay:YES];
	} else {
		NSLog(@"Using new method");
		NSTitlebarAccessoryViewController *titleBarViewController = [[NSTitlebarAccessoryViewController alloc] init];
		titleBarViewController.view = self.accessoryViewButton;
		titleBarViewController.layoutAttribute = NSLayoutAttributeRight;
		[self.window addTitlebarAccessoryViewController:titleBarViewController];
	}
}

- (IBAction)viewInFinderButtonClicked:(id)sender {
	// Get the table view selection and make sure that they selected something.
	NSInteger row = [self.tableView clickedRow];
	if (row == -1) {
		return;
	}

	// Construct the name and path of the downloaded ISO.
	NSString *distribution = [[(SBAppDelegate *)[NSApp delegate] supportedDistributions] objectAtIndex:[self.tableView selectedRow]];
	NSString *path = [[[NSFileManager defaultManager] applicationSupportDirectory] stringByAppendingPathComponent:@"/Downloads/"];
	path = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-%@.iso",
												 [[(SBAppDelegate *)[NSApp delegate] supportedDistributions] objectAtIndex:[self.tableView selectedRow]],
												 [[(SBAppDelegate *)[NSApp delegate] supportedDistributionsAndVersions] objectForKey:distribution]]];

	// Open the URL.
	[[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:path];
}

- (IBAction)downloadDistroButtonPressed:(id)sender {
	NSInteger selectedDistro = [self.tableView selectedRow];

	NSString *temp = [[(SBAppDelegate *)[NSApp delegate] supportedDistributions] objectAtIndex:selectedDistro];
	temp = [temp stringByReplacingOccurrencesOfString:@" " withString:@"-"];

	if (!self.modelDictionary[temp]) {
		// Ideally, we'd support the new sheet API, but we need to still support 10.8...
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:NSLocalizedString(@"Okay", nil)];
		[alert setMessageText:NSLocalizedString(@"Can't download this distribution.", nil)];
		[alert setInformativeText:NSLocalizedString(@"You cannot download this distribution because Mac USB Linux Loader has not finished downloading its list of mirrors.", nil)];
		[alert setAlertStyle:NSWarningAlertStyle];
		[alert beginSheetModalForWindow:self.window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];

		return;
	}

	self.downloadDistroModel = self.modelDictionary[temp];
	[self.distroMirrorCountrySelector removeAllItems];

	for (SBDownloadMirrorModel *model in[self.downloadDistroModel mirrors]) {
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

	NSString *distribution = [[(SBAppDelegate *)[NSApp delegate] supportedDistributions] objectAtIndex:[self.tableView selectedRow]];
	NSString *path = [[[NSFileManager defaultManager] applicationSupportDirectory] stringByAppendingPathComponent:@"/Downloads/"];
	path = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-%@.iso",
	                                             [[(SBAppDelegate *)[NSApp delegate] supportedDistributions] objectAtIndex:[self.tableView selectedRow]],
	                                             [[(SBAppDelegate *)[NSApp delegate] supportedDistributionsAndVersions] objectForKey:distribution]]];

	// Inform the system that we are starting this operation.
	if ([[NSProcessInfo processInfo] respondsToSelector:@selector(beginActivityWithOptions:reason:)]) {
		if (!self.activity) {
			self.activity = [[NSProcessInfo processInfo] beginActivityWithOptions:NSActivityUserInitiated reason:@"ISO Download"];
		}
	}

	self.numberOfActiveDownloadOperations++;
	SBDownloadMirrorModel *model = self.downloadDistroModel.mirrors[selectedItem];
	NSURL *url = [NSURL URLWithString:model.url];
	DownloadOperation *downloadOperation = [[DownloadOperation alloc] initWithURL:url path:path];
	downloadOperation.downloadCompletionBlock = ^(DownloadOperation *operation, BOOL success, NSError *error) {
		if (error) {
			NSLog(@"%s: downloadCompletionBlock error: %@", __FUNCTION__, error);
		} else {
			/* The download was completed successfully. TODO: Show a notification. */

			// Open the downloaded ISO file.
			NSInteger completionOperation = [self.defaults integerForKey:@"DefaultOperationUponISODownloadCompletion"];
			if (completionOperation == 0) {
				NSURL *url = [NSURL fileURLWithPath:operation.path];
				[[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:url display:YES completionHandler: ^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error) {}
				];
			} else if (completionOperation == 1) {
				[[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:path];
			}
		}

		self.numberOfActiveDownloadOperations--;

		if ([[NSProcessInfo processInfo] respondsToSelector:@selector(beginActivityWithOptions:reason:)]) {
			if (self.numberOfActiveDownloadOperations == 0) {
				[[NSProcessInfo processInfo] endActivity:self.activity];
			}
		}
	};
	downloadOperation.downloadProgressBlock = ^(DownloadOperation *operation, long long progressContentLength, long long expectedContentLength) {
		CGFloat progress = (expectedContentLength > 0 ? (CGFloat)progressContentLength / (CGFloat)expectedContentLength : (progressContentLength % 1000000l) / 1000000.0f);
		//NSLog(@"%@: %f", operation, progress);

		NSInteger row = operation.correspondingTableViewRow;
		SBDistributionDownloaderTableCellView *cellView = [self.downloadQueueTableView viewAtColumn:0 row:row makeIfNecessary:YES];
		[cellView.progressBar setDoubleValue:progress * 100];
	};
	downloadOperation.correspondingTableViewRow = self.numberOfActiveDownloadOperations - 1;

	[self.downloadQueue addOperation:downloadOperation];
	[self closeDownloadDistroSheetPressed:nil];
	[self.downloadQueueTableView reloadData];
}

- (IBAction)viewInProgressDownloads:(id)sender {
	[self.downloadQueuePopover showRelativeToRect:[self.accessoryViewButton bounds] ofView:self.accessoryViewButton preferredEdge:NSMaxYEdge];
	/*NSAlert *alert = [NSAlert alertWithMessageText:@"Do you really want to delete this item?"
	                                 defaultButton:@"Delete"
	                               alternateButton:@"Learn more"
	                                   otherButton:@"Cancel"
	                     informativeTextWithFormat:@"Deleting this item will erase all associated data in the database. Click learn more if you need additional information."];

	   [alert runAsPopoverForView:self.accessoryViewButton withCompletionBlock:^(NSInteger result) {
	    // handle result
	   }];*/
}

@end
