//
//  SBAppDelegate.m
//  Mac Linux USB Loader
//
//  Created by SevenBits on 1/13/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import "SBAppDelegate.h"
#import "SBGeneralPreferencesViewController.h"

@implementation SBAppDelegate
@synthesize window;
@synthesize operationsTableView;
@synthesize applicationVersionString;

#pragma mark - Object Setup

- (id)init {
    self = [super init];
    if (self) {
		// Setup code goes here.
    }
    return self;
}

#pragma mark - Application Setup

- (void)applicationDidFinishLaunching: (NSNotification *)aNotification {
	/* Set window properties. */
	// Make the window background white.
	[self.window setBackgroundColor:[NSColor whiteColor]];

	// Set window resize behavior.
	[[self.window standardWindowButton:NSWindowZoomButton] setHidden:YES];
	[[self.window standardWindowButton:NSWindowMiniaturizeButton] setHidden:YES];
	[self.window setShowsResizeIndicator:NO];
	[self.window setResizeIncrements:NSMakeSize(MAXFLOAT, MAXFLOAT)];

	// Remove the title.
	[self.window setTitle:@""];

	/* Make the table respond to our double click operations. */
	[self.operationsTableView setDoubleAction:@selector(userSelectedOperationFromTable)];

	/* Set the application version label string. */
	[self.applicationVersionString setStringValue:
	 [NSString stringWithFormat:@"Version %@",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]]];

	/* Setup the rest of the application. */
	[self applicationSetup];
}

- (void)applicationSetup {
	// Register default defaults.
	NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"defaults" ofType:@"plist"]];
	[[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];

	// Detect all available USB drives.
	[self detectAndSetupUSBs];
}

- (void)detectAndSetupUSBs {
	if (!self.usbDictionary) {
		self.usbDictionary = [[NSMutableDictionary alloc] initWithCapacity:10];
	}

	NSArray *volumes = [[NSWorkspace sharedWorkspace] mountedLocalVolumePaths];
    BOOL isRemovable, isWritable, isUnmountable;
    NSString *description, *volumeType;

	BOOL acceptHFSDrives = [[NSUserDefaults standardUserDefaults] boolForKey:@"AcceptHFSDrives"];

	for (NSString *usbDeviceMountPoint in volumes) {
		if ([[NSWorkspace sharedWorkspace] getFileSystemInfoForPath:usbDeviceMountPoint isRemovable:&isRemovable isWritable:&isWritable isUnmountable:&isUnmountable description:&description type:&volumeType]) {
			if (isRemovable && isWritable && isUnmountable) {
				NSLog(@"Detected eligible volume at %@. Type: %@", usbDeviceMountPoint, volumeType);

				if ([usbDeviceMountPoint isEqualToString:@"/"]) {
					// Don't include the root partition in the list of USBs.
					continue;
				} else {
					if ([volumeType isEqualToString:@"msdos"] ||
						([volumeType isEqualToString:@"hfs"] && acceptHFSDrives)) {
						SBUSBDevice *usbDevice = [[SBUSBDevice alloc] init];
						usbDevice.path = usbDeviceMountPoint;
						usbDevice.name = [usbDeviceMountPoint lastPathComponent];
						
						self.usbDictionary[[usbDeviceMountPoint lastPathComponent]] = usbDevice;
					}
				}
			}
		}
	}
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender {
    [self.window makeKeyAndOrderFront:nil];
    return YES;
}

#pragma mark - IBActions

- (IBAction)showPreferencesWindow:(id)sender {
	if (!self.preferencesWindowController) {
		SBGeneralPreferencesViewController *generalPreferences = [[SBGeneralPreferencesViewController alloc] initWithNibName:@"SBGeneralPreferencesViewController" bundle:nil];

		NSArray *controllers = [NSArray arrayWithObjects:generalPreferences,
                                [RHPreferencesWindowController flexibleSpacePlaceholderController],
                                nil];
		self.preferencesWindowController = [[RHPreferencesWindowController alloc] initWithViewControllers:controllers andTitle:NSLocalizedString(@"Preferences", nil)];
	}

	[self.preferencesWindowController showWindow:self];
}

- (IBAction)showAboutWindow:(id)sender {
	self.aboutWindowController = [[SBAboutWindowController alloc] initWithWindowNibName:@"SBAboutWindowController"];
	[self.aboutWindowController showWindow:nil];
}

- (IBAction)showMoreOptionsPopover:(id)sender {
	[self.moreOptionsPopover showRelativeToRect:[sender bounds]
										 ofView:sender
								  preferredEdge:NSMaxYEdge];
}

- (IBAction)hideMoreOptionsPopover:(id)sender {
	[self.moreOptionsPopover close];
}

- (IBAction)showProjectWebsite:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://sevenbits.github.io/projects/mlul.html"]];
	[self hideMoreOptionsPopover:nil];
}

- (IBAction)reportBug:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://sevenbits.github.io/tools/bugs/report-mlul.html"]];
	[self hideMoreOptionsPopover:nil];
}

#pragma mark - Table View Delegates

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return 4;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSTableCellView *result = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
	switch (row) {
		case 0:
			result.imageView.image = [[NSImage imageNamed:@"AppIcon"] copy];
			result.textField.stringValue = NSLocalizedString(@"Create Live USB", nil);
			break;

		case 1:
			result.imageView.image = [[NSImage imageNamed:@"USB"] copy];
			result.textField.stringValue = NSLocalizedString(@"Setup USB Device", nil);
			break;

		case 2:
			result.imageView.image = [[NSImage imageNamed:@"Persistence"] copy];
			result.textField.stringValue = NSLocalizedString(@"Persistence Manager", nil);
			break;

		case 3:
			result.imageView.image = [[NSImage imageNamed:@"DistributionDownloader"] copy];
			result.textField.stringValue = NSLocalizedString(@"Distribution Downloader", nil);
			break;

		default:
			break;
	}
    return result;
}

- (void)userSelectedOperationFromTable {
    NSInteger clickedRow = [self.operationsTableView clickedRow];
	[self hideMoreOptionsPopover:nil];

	if (clickedRow != -1) { // We've selected a valid table entry.
		[self.window orderOut:nil];

		switch (clickedRow) {
			case 0:
				[[NSDocumentController sharedDocumentController] openDocument:nil];
				break;

			case 1:
				if (!self.usbSetupWindowController) {
					self.usbSetupWindowController = [[SBUSBSetupWindowController alloc]
													 initWithWindowNibName:@"SBUSBSetupWindowController"];
				}

				[self.usbSetupWindowController showWindow:nil];
				break;

			case 2:
				if (!self.persistenceSetupWindowController) {
					self.persistenceSetupWindowController = [[SBPersistenceManagerWindowController alloc]
															 initWithWindowNibName:@"SBPersistenceManagerWindowController"];
				}

				[self.persistenceSetupWindowController showWindow:nil];
				break;

			default:
				NSLog(@"Selected table index %ld is not valid.", (long)clickedRow);
				break;
		}
	}
}
@end
