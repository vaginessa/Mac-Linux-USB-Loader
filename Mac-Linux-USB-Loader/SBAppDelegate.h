//
//  SBAppDelegate.h
//  Mac Linux USB Loader
//
//  Created by SevenBits on 1/13/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RHPreferences/RHPreferences.h>
#import <DiskArbitration/DiskArbitration.h>
#import "SBUSBSetupWindowController.h"
#import "SBPersistenceManagerWindowController.h"
#import "SBUSBDevice.h"
#import "SBAboutWindowController.h"
#import "SBDistributionDownloaderWindowController.h"

@interface SBAppDelegate : NSObject {
	__unsafe_unretained NSWindow *window;
	__weak NSTableView *operationsTableView;
	__weak NSTextField *applicationVersionString;

	RHPreferencesWindowController *_preferencesWindowController;
}

@property (unsafe_unretained) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTableView *operationsTableView;
@property (weak) IBOutlet NSTextField *applicationVersionString;
@property (weak) IBOutlet NSPopover *moreOptionsPopover;

/// A dictionary containing the keys of plugged in USB devices with the values of those keys being instances of SBUSBDevice.
@property (nonatomic, strong) NSMutableDictionary *usbDictionary;
/// A dictionary containing the keys of registered Enterprise source locations with the values of those keys being instances
/// of SBEnterpriseSourceLocation. This dictionary's contents are stored on-disk.
@property (nonatomic, strong) NSMutableDictionary *enterpriseInstallLocations;

/// The path to the application's application support directory.
@property (nonatomic, strong) NSString *pathToApplicationSupportDirectory;
/// An instance of NSFileManager to be used by this instance.
@property (nonatomic, strong) NSFileManager *fileManager;
/// A dictionary containing a list of supported distributions and their minimum supported versions.
@property (nonatomic, strong) NSDictionary *supportedDistributionsAndVersions;
/// An array of supported distributions to be used as keys for the supportedDistributionsAndVersions property.
@property (nonatomic, strong) NSArray *supportedDistributions;

@property (nonatomic, strong) SBUSBSetupWindowController *usbSetupWindowController;
@property (nonatomic, strong) SBPersistenceManagerWindowController *persistenceSetupWindowController;
@property (nonatomic, strong) SBAboutWindowController *aboutWindowController;
@property (nonatomic, strong) SBDistributionDownloaderWindowController *downloaderWindowController;
@property (nonatomic, strong) RHPreferencesWindowController *preferencesWindowController;

- (BOOL)writeEnterpriseSourceLocationsToDisk:(NSString *)path;
- (void)readEnterpriseSourceLocationsFromDisk:(NSString *)path;

- (void)detectAndSetupUSBs;

- (void)purgeCachesAndOldFiles;

- (IBAction)showPreferencesWindow:(id)sender;
- (IBAction)showAboutWindow:(id)sender;
- (IBAction)showHelp:(id)sender;
- (IBAction)showProjectWebsite:(id)sender;
- (IBAction)showMoreOptionsPopover:(id)sender;
- (IBAction)hideMoreOptionsPopover:(id)sender;
- (IBAction)reportBug:(id)sender;

+ (NSUUID *)uuidForDeviceName:(NSString *)name;

@end
