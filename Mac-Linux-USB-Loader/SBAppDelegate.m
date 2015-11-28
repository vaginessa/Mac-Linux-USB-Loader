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
#import "SBUpdatePreferencesViewController.h"
#import "SBEnterpriseSourceLocation.h"

#define SBClearAllMenuItemTag 552345

const NSString *SBBundledEnterpriseVersionNumber = @"0.3.2";

@interface SBAppDelegate ()
// These need to be here so that we can write to readonly variables within
// this file, but prohibit others from being able to do so.
@property (nonatomic, strong) NSMutableDictionary *usbDictionary;
@property (nonatomic, strong) NSMutableDictionary *enterpriseInstallLocations;
@property (nonatomic, strong) NSString *pathToApplicationSupportDirectory;
@property (nonatomic, strong) NSDictionary *supportedDistributionsAndVersions;
@property (nonatomic, strong) NSArray *supportedDistributions;

@property (nonatomic, strong) SBUSBSetupWindowController *usbSetupWindowController;
@property (nonatomic, strong) SBPersistenceManagerWindowController *persistenceSetupWindowController;
@property (nonatomic, strong) SBAboutWindowController *aboutWindowController;
@property (nonatomic, strong) SBDistributionDownloaderWindowController *downloaderWindowController;
@property (nonatomic, strong) RHPreferencesWindowController *preferencesWindowController;

@property (weak) IBOutlet NSTableView *operationsTableView;
@property (weak) IBOutlet NSTextField *applicationVersionString;
@property (weak) IBOutlet NSPopover *moreOptionsPopover;
@property (weak) IBOutlet NSMenu *registeredDevicesMenu;
@end

@implementation SBAppDelegate
@synthesize window;

#pragma mark - Object Setup

- (instancetype)init {
	self = [super init];
	if (self) {
		// Setup code goes here.
		self->fileManager = [NSFileManager defaultManager];
		self.pathToApplicationSupportDirectory = [self->fileManager applicationSupportDirectory];

		self.supportedDistributions = @[@"Ubuntu", @"Linux Mint", @"Elementary OS", @"Zorin OS", @"Kali Linux"];
		self.supportedDistributionsAndVersions = @{ @"Ubuntu": @"15.10",
			                                        @"Linux Mint": @"17.2",
			                                        @"Elementary OS": @"Freya",
			                                        @"Zorin OS": @"10",
													@"Kali Linux": @"" };
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

	// Remove the title.
	[self.window setTitle:@""];

	/* Make the table respond to our double click operations. */
	[self.operationsTableView setDoubleAction:@selector(userSelectedOperationFromTable)];

	/* Set the application version label string. */
	[self.applicationVersionString setStringValue:
	[NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Version", nil), [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]]];

	/* Setup the rest of the application. */
	[self applicationSetup];
}

- (void)applicationSetup {
	// Register default defaults.
	NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"defaults" ofType:@"plist"]];
	[[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];

	// Load the list of Enterprise installation sources
	[self setupEnterpriseInstallationLocations];

	// Scan for saved USBs.
	[self scanForSavedUSBs];

	// Check if enough time has passed to where we need to clear all caches, but only if the user has indicated
	// that they want this behavior to happen.
	BOOL shouldClearCaches = [[NSUserDefaults standardUserDefaults] boolForKey:@"PeriodicallyClearCaches"];
	if (shouldClearCaches) {
		const NSInteger clearCachesUpdateInterval = 5184000; // 60 days (i.e two months) in seconds
		NSDate *lastCheckedDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"LastCacheClearCheckTime"];
		if (lastCheckedDate) {
			// We have a previous date.
			NSInteger interval = (NSInteger)fabs([lastCheckedDate timeIntervalSinceNow]);
			if (interval > clearCachesUpdateInterval) {
				// Delete all caches.
				NSLog(@"Clearing all caches and old ISO downloads...");
				[NSThread detachNewThreadSelector:@selector(purgeCachesAndOldFiles) toTarget:self withObject:nil];

				// Save the date now as the starting point for the two-month count to clear caches.
				[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"LastCacheClearCheckTime"];
			}
		} else {
			// User has just opened the application or has cleared defaults. Save the date now as the starting
			// point for the two-month count to clear caches.
			[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"LastCacheClearCheckTime"];
		}
	}
}

- (void)scanForSavedUSBs {
	NSInteger detectedKeys = 0;
	[self.registeredDevicesMenu removeAllItems];
	NSDictionary *preferences = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
	NSEnumerator *keys = [preferences keyEnumerator];

	// Add the 'Clear All' menu item and separator.
	NSMenuItem *clearAllMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Clear All", nil) action:@selector(deleteStoredUSBDevice:) keyEquivalent:@""];
	clearAllMenuItem.tag = SBClearAllMenuItemTag;
	[self.registeredDevicesMenu addItem:clearAllMenuItem];
	[self.registeredDevicesMenu addItem:[NSMenuItem separatorItem]];

	// Enumerate and find all registered USBs.
	NSString *key;
	while ((key = [keys nextObject])) {
		if ([key hasSuffix:@"_USBSecurityBookmarkTarget"]) {
			// create the menu item with the USB's title.
			// we don't have to worry about getting an NSNotFound here because we already
			// know that the target string exists
			NSRange s = [key rangeOfString:@"_USBSecurityBookmarkTarget"];
			NSString *usbTitle = [key substringToIndex:s.location];
			NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:usbTitle action:@selector(deleteStoredUSBDevice:) keyEquivalent:@""];
			[self.registeredDevicesMenu addItem:item];
			detectedKeys++;
		}
	}

	// Tell the user if there are no detected devices.
	if (detectedKeys == 0) {
		NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"No Registered Devices", nil) action:NULL keyEquivalent:@""];
		[self.registeredDevicesMenu addItem:item];
	}
}

- (void)purgeCachesAndOldFiles {
	/* First, purge all caches and unneeded data that we can re-obtain. */
	NSString *path = [self->fileManager cacheDirectory];
	NSFileManager *fm = [[NSFileManager alloc] init];
	NSDirectoryEnumerator *en = [fm enumeratorAtPath:path];
	NSError *err = nil;
	BOOL res;

	// Deal with caches.
	NSString *file;
	NSString *completePath;
	while (file = [en nextObject]) {
		if (![[path stringByAppendingPathComponent:file] hasSuffix:@".json"]) {
			res = [fm removeItemAtPath:[path stringByAppendingPathComponent:file] error:&err];
			if (!res && err) {
				NSLog(@"Couldn't erase cached file at path: %@", err.localizedFailureReason);
			}
		}
	}

	// Deal with old ISOs.
	path = [self->fileManager applicationSupportDirectory];
	en = [fm enumeratorAtPath:path];
	while (file = [en nextObject]) {
		BOOL shouldDelete = YES;
		completePath = [path stringByAppendingPathComponent:file];
		for (NSString *dn in self.supportedDistributions) {
			NSString *shortFileName = [[completePath lastPathComponent] stringByReplacingOccurrencesOfString:@" " withString:@"-"];
			NSString *distroName = [dn stringByReplacingOccurrencesOfString:@" " withString:@"-"];
			if ([shortFileName containsSubstring:distroName] || [shortFileName isEqualToString:@"Downloads"]) {
				//NSLog(@"Not deleting file %@ because it matches pattern: %@", shortFileName, distroName);
				shouldDelete = NO;
				break;
			}
		}

		if (shouldDelete) {
			[fm removeItemAtPath:completePath error:&err];
			if (err) {
				NSLog(@"Couldn't erase cached file at path: %@", err.localizedFailureReason);
			}
		}
	}
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender {
	[self.window makeKeyAndOrderFront:nil];
	return YES;
}

- (void)setupEnterpriseInstallationLocations {
	NSString *filePath = [self.pathToApplicationSupportDirectory stringByAppendingPathComponent:@"/EnterpriseInstallationLocations.plist"];
	BOOL exists = [self->fileManager fileExistsAtPath:filePath];

	if (!exists) {
		NSLog(@"Couldn't find dictionary of Enterprise source file locations. Is this the first run? Creating one now...");
		self.enterpriseInstallLocations = [[NSMutableDictionary alloc] initWithCapacity:5]; // A rather arbitary number.

		// Add the Enterprise installation located in Mac Linux USB Loader's bundle to the list of available
		// Enterprise installations.
		NSString *defaultPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/Enterprise/"];
		SBEnterpriseSourceLocation *loc = [[SBEnterpriseSourceLocation alloc] initWithName:@"Included With Application"
		                                                                           andPath:defaultPath
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
	@try {
		self.enterpriseInstallLocations = [NSKeyedUnarchiver unarchiveObjectWithFile:path];

		/*
		 * Even though the path to the default Enterprise source is already set when the configuration file is
		 * written to disk, if the user moves the application bundle there is a chance that the path won't
		 * be updated, resulting in errors. So we update it here so that this won't happen.
		 */
		NSString *defaultPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/Enterprise/"];
		SBEnterpriseSourceLocation *source = self.enterpriseInstallLocations[@"Included With Application"];

		if (!source) {
			NSLog(@"The path of the bundled Enterprise source could not have its source path updated. Perhaps there is a problem with the cached Enterprise sources list. This will almost certainly cause problems (if you're a user seeing this message, file a bug)!");
		} else {
			// If the path stored in the Enterprise source is not the one in our app bundle (i.e, the application
			// has been fixed, fix this by setting it to the correct path and writing to disk.
			if (![source.path isEqualToString:defaultPath]) {
				source.path = defaultPath;
				//SBLogObject(source.path);
				[self writeEnterpriseSourceLocationsToDisk:path];
			}
		}
	} @catch (NSException *exception) {
		NSLog(@"Couldn't decode Enterprise source file locations.");
	}
}

- (void)detectAndSetupUSBs {
	if (!self.usbDictionary) {
		self.usbDictionary = [[NSMutableDictionary alloc] initWithCapacity:10];
	} else {
		[self.usbDictionary removeAllObjects];
	}

	NSArray *volumes = [self->fileManager mountedVolumeURLsIncludingResourceValuesForKeys:nil options:0];
	BOOL isRemovable, isWritable, isUnmountable;
	NSString *description, *volumeType;

	BOOL acceptHFSDrives = [[NSUserDefaults standardUserDefaults] boolForKey:@"AcceptHFSDrives"];

	for (NSURL *mountURL in volumes) {
		NSString *usbDeviceMountPoint = [mountURL path];
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
						usbDevice.fileSystem = [volumeType isEqualToString:@"msdos"] ? SBUSBDriveFileSystemFAT32 : SBUSBDriveFileSystemHFS;
						usbDevice.uuid = [SBAppDelegate uuidForDeviceName:usbDeviceMountPoint];

						self.usbDictionary[usbDevice.name] = usbDevice;
					}
				}
			} else {
				NSLog(@"Volume at %@ is not eligible. Type: %@", usbDeviceMountPoint, volumeType);
			}
		} else {
			NSLog(@"Couldn't get file system info for USB %@", [usbDeviceMountPoint lastPathComponent]);
		}
	}
}

#pragma mark - IBActions

- (IBAction)deleteStoredUSBDevice:(NSMenuItem *)sender {
	if (sender.tag == SBClearAllMenuItemTag) {
		// delete all registered USB devices.
		NSDictionary *preferences = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
		NSEnumerator *keys = [preferences keyEnumerator];

		NSString *key;
		while ((key = [keys nextObject])) {
			if ([key hasSuffix:@"_USBSecurityBookmarkTarget"]) {
				[[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
			}
		}
	} else {
		// get the name of the preferences key to delete based on the USB's name.
		NSString *preferencesKeyToDelete = [sender.title stringByAppendingString:@"_USBSecurityBookmarkTarget"];
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:preferencesKeyToDelete];
	}

	// re-build the list of USBs.
	[self scanForSavedUSBs];
}

- (IBAction)showPreferencesWindow:(id)sender {
	if (!self.preferencesWindowController) {
		SBGeneralPreferencesViewController *generalPreferences = [[SBGeneralPreferencesViewController alloc] initWithNibName:@"SBGeneralPreferencesViewController" bundle:nil];
		SBEnterprisePreferencesViewController *enterprisePreferences = [[SBEnterprisePreferencesViewController alloc] initWithNibName:@"SBEnterprisePreferencesViewController" bundle:nil];
		SBDistributionDownloaderPreferencesViewController *downloaderPreferences = [[SBDistributionDownloaderPreferencesViewController alloc] initWithNibName:@"SBDistributionDownloaderPreferencesViewController" bundle:nil];
		SBUpdatePreferencesViewController *updaterPreferences = [[SBUpdatePreferencesViewController alloc] initWithNibName:@"SBUpdatePreferencesViewController" bundle:nil];

		NSArray *controllers = @[generalPreferences, enterprisePreferences, downloaderPreferences, updaterPreferences,
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
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://sevenbits.github.io/Mac-Linux-USB-Loader/"]];
}

- (IBAction)showDonatePage:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://sevenbits.github.io/donate.html"]];
}

- (IBAction)reportBug:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://sevenbits.github.io/tools/bugs/report-mlul.html"]];
}

- (IBAction)showHelp:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/SevenBits/Mac-Linux-USB-Loader/wiki"]];
}

#pragma mark - Table View Delegates

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView __attribute__((const)) {
	return 4;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	NSTableCellView *result = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
	switch (row) {
		case 0:
			result.imageView.image = [NSImage imageNamed:@"AppIcon"];
			result.textField.stringValue = NSLocalizedString(@"Create Live USB", nil);
			break;

		case 1:
			result.imageView.image = [NSImage imageNamed:@"USB"];
			result.textField.stringValue = NSLocalizedString(@"Setup USB Device", nil);
			break;

		case 2:
			result.imageView.image = [NSImage imageNamed:@"Persistence"];
			result.textField.stringValue = NSLocalizedString(@"Persistence Manager", nil);
			break;

		case 3:
			result.imageView.image = [NSImage imageNamed:@"DistributionDownloader"];
			result.textField.stringValue = NSLocalizedString(@"Distribution Downloader", nil);
			break;

		default:
			break;
	}
	return result;
}

- (void)userSelectedOperationFromTable {
	NSInteger clickedRow = [self.operationsTableView clickedRow];

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

+ (SBLinuxDistribution)distributionEnumForEqualivalentName:(NSString *)name __attribute__((pure)) {
	if ([name isEqualToString:@"Ubuntu"]) {
		return SBDistributionUbuntu;
	} else if ([name isEqualToString:@"Debian"]) {
		return SBDistributionDebian;
	} else if ([name isEqualToString:@"Kali"]) {
		return SBDistributionKali;
	} else if ([name isEqualToString:@"Tails"]) {
		return SBDistributionTails;
	} else {
		return SBDistributionUnknown;
	}
}

+ (NSString *)distributionStringForEquivalentEnum:(SBLinuxDistribution)dist __attribute__((const)) {
	switch (dist) {
		case SBDistributionUbuntu:
			return @"Ubuntu";
			break;
		case SBDistributionDebian:
			return @"Debian";
			break;
		case SBDistributionTails:
			return @"Tails";
			break;
		case SBDistributionKali:
			return @"Kali";
			break;
		case SBDistributionUnknown:
		default:
			return @"Other";
			break;
	}
}

+ (SBLinuxDistribution)distributionTypeForISOName:(NSString *)path __attribute__((pure)) {
	NSString *fileName = [[path lowercaseString] lastPathComponent];
	if ([fileName containsSubstring:@"tails"]) {
		return SBDistributionTails;
	} else if ([fileName containsSubstring:@"ubuntu"] ||
			   [fileName containsSubstring:@"mint"] ||
			   [fileName containsSubstring:@"elementary"]) {
		return SBDistributionUbuntu;
	} else if ([fileName containsSubstring:@"kali"]) {
		return SBDistributionKali;
	}

	return SBDistributionUnknown;
}

@end
