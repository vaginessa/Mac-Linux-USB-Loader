//
//  SBAppDelegate.m
//  Mac Linux USB Loader
//
//  Created by SevenBits on 1/13/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import "SBAppDelegate.h"
#import "SBGeneralPreferencesViewController.h"
#import "SBEnterprisePreferencesViewController.h"
#import "SBDistributionDownloaderPreferencesViewController.h"
#import "SBEnterpriseSourceLocation.h"

#import "NSFileManager+Extensions.h"
#import "NSFileManager+DirectoryLocations.h"

@implementation SBAppDelegate
@synthesize window;
@synthesize operationsTableView;
@synthesize applicationVersionString;

#pragma mark - Object Setup

- (id)init {
	self = [super init];
	if (self) {
		// Setup code goes here.
		self.fileManager = [NSFileManager defaultManager];
		self.pathToApplicationSupportDirectory = [self.fileManager applicationSupportDirectory];

		self.supportedDistributions = @[@"Ubuntu", @"Linux Mint", @"Elementary OS", @"Zorin OS", @"Kali Linux"];
		self.supportedDistributionsAndVersions = @{ @"Ubuntu": @"14.04-LTS",
			                                        @"Linux Mint": @"17",
			                                        @"Elementary OS": @"Luna",
			                                        @"Zorin OS": @"8" };
	}
	return self;
}

#pragma mark - Application Setup

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	/* Set window properties. */
	// Make the window background white.
	[self.window setBackgroundColor:[NSColor whiteColor]];
	[self.window setMovableByWindowBackground:NO];

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
	 [NSString stringWithFormat:@"Version %@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]]];

	/* Setup the rest of the application. */
	[self applicationSetup];
}

- (void)applicationSetup {
	// Register default defaults.
	NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"defaults" ofType:@"plist"]];
	[[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];

	// Detect all available USB drives.
	[self setupEnterpriseInstallationLocations];
	[self detectAndSetupUSBs];
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender {
	[self.window makeKeyAndOrderFront:nil];
	return YES;
}

- (void)setupEnterpriseInstallationLocations {
	NSString *filePath = [self.pathToApplicationSupportDirectory stringByAppendingString:@"/EnterpriseInstallationLocations.plist"];
	BOOL exists = [self.fileManager fileExistsAtPath:filePath];

	if (!exists) {
		NSLog(@"Couldn't find dictionary of Enterprise source file locations. Is this the first run? Creating one now...");
		self.enterpriseInstallLocations = [[NSMutableDictionary alloc] initWithCapacity:5]; // A rather arbitary number.

		// Add the Enterprise installation located in Mac Linux USB Loader's bundle to the list of available
		// Enterprise installations.
		SBEnterpriseSourceLocation *loc = [[SBEnterpriseSourceLocation alloc] initWithName:@"Included With Application"
		                                                                           andPath:@""
		                                                                  shouldBeVolatile:NO];
		self.enterpriseInstallLocations[@"Included With Application"] = loc;

		BOOL success = [self writeEnterpriseSourceLocationsToDisk:filePath];
		if (!success) {
			NSLog(@"Failed to create a file containing the Enterprise source locations. Check the logs for more information.");
		}
	}
	else {
		NSLog(@"Found dictionary of Enterprise source file locations.");
		[self readEnterpriseSourceLocationsFromDisk:filePath];
	}
}

- (BOOL)writeEnterpriseSourceLocationsToDisk:(NSString *)path {
	// Write the file to disk.
	BOOL success = [NSKeyedArchiver archiveRootObject:self.enterpriseInstallLocations toFile:path];
	return success;
}

- (void)readEnterpriseSourceLocationsFromDisk:(NSString *)path {
	self.enterpriseInstallLocations = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
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
				}
				else {
					if ([volumeType isEqualToString:@"msdos"] ||
					    ([volumeType isEqualToString:@"hfs"] && acceptHFSDrives)) {
						SBUSBDevice *usbDevice = [[SBUSBDevice alloc] init];
						usbDevice.path = usbDeviceMountPoint;
						usbDevice.name = [usbDeviceMountPoint lastPathComponent];
						[SBAppDelegate uuidForDeviceName:usbDeviceMountPoint];

						self.usbDictionary[usbDevice.name] = usbDevice;
					}
				}
			}
		}
	}
}

#pragma mark - IBActions

- (IBAction)showPreferencesWindow:(id)sender {
	if (!self.preferencesWindowController) {
		SBGeneralPreferencesViewController *generalPreferences = [[SBGeneralPreferencesViewController alloc] initWithNibName:@"SBGeneralPreferencesViewController" bundle:nil];
		SBEnterprisePreferencesViewController *enterprisePreferences = [[SBEnterprisePreferencesViewController alloc] initWithNibName:@"SBEnterprisePreferencesViewController" bundle:nil];
		SBDistributionDownloaderPreferencesViewController *downloaderPreferences = [[SBDistributionDownloaderPreferencesViewController alloc] initWithNibName:@"SBDistributionDownloaderPreferencesViewController" bundle:nil];

		NSArray *controllers = @[generalPreferences, enterprisePreferences, downloaderPreferences,
		                         [RHPreferencesWindowController flexibleSpacePlaceholderController]];
		self.preferencesWindowController = [[RHPreferencesWindowController alloc] initWithViewControllers:controllers andTitle:NSLocalizedString(@"Preferences", nil)];
	}

	[self.preferencesWindowController showWindow:self];
}

- (IBAction)showAboutWindow:(id)sender {
	[self.aboutWindowController.window performClose:nil]; // This works because messages can be sent to nil.

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

- (IBAction)showHelp:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/SevenBits/Mac-Linux-USB-Loader/wiki"]];
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

			case 3:
				if (!self.downloaderWindowController) {
					self.downloaderWindowController = [[SBDistributionDownloaderWindowController alloc]
					                                   initWithWindowNibName:@"SBDistributionDownloaderWindowController"];
				}

				[self.downloaderWindowController showWindow:nil];
				break;

			default:
				NSLog(@"Selected table index %ld is not valid.", (long)clickedRow);
				break;
		}
	}
}

#pragma mark - Utility Functions

+ (NSUUID *)uuidForDeviceName:(NSString *)name {
	DADiskRef disk = NULL;
	CFDictionaryRef descDict;
	DASessionRef session = DASessionCreate(NULL);
	if (session) {
		const char *mountPoint = [name cStringUsingEncoding:NSASCIIStringEncoding];
		CFURLRef url = CFURLCreateFromFileSystemRepresentation(NULL, (const UInt8 *)mountPoint, strlen(mountPoint), TRUE);
		disk = DADiskCreateFromVolumePath(NULL, session, url);
		if (disk) {
			descDict = DADiskCopyDescription(disk);
			if (descDict) {
				CFTypeRef value = (CFTypeRef)CFDictionaryGetValue(descDict,
				                                                  CFSTR("DAVolumeUUID"));
				CFStringRef strValue = CFStringCreateWithFormat(NULL, NULL,
				                                                CFSTR("%@"), value);
				//NSLog(@"%@", strValue);
				CFRelease(descDict);

				NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:CFBridgingRelease(strValue)];
				//SBLogObject([uuid UUIDString]);
				return uuid;
			} else {
				NSLog(@"Sorry, no Disk Arbitration description.");
			}
			CFRelease(disk);
		} else {
			NSLog(@"Sorry, no Disk Arbitration disk.");
		}
	} else {
		NSLog(@"Sorry, no Disk Arbitration session.");
	}

	return nil;
}

@end
