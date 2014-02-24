//
//  SBAppDelegate.h
//  Mac Linux USB Loader
//
//  Created by SevenBits on 1/13/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RHPreferences/RHPreferences.h>
#import "SBUSBSetupWindowController.h"
#import "SBPersistenceManagerWindowController.h"
#import "SBUSBDevice.h"
#import "SBAboutWindowController.h"

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

@property (nonatomic, strong) NSMutableDictionary *usbDictionary;
@property (nonatomic, strong) NSMutableDictionary *enterpriseInstallLocations;

/// The path to the application's application support directory.
@property (nonatomic, strong) NSString *pathToApplicationSupportDirectory;
/// An instance of NSFileManager to be used by this instance.
@property (nonatomic, strong) NSFileManager *fileManager;

@property (nonatomic, strong) SBUSBSetupWindowController *usbSetupWindowController;
@property (nonatomic, strong) SBPersistenceManagerWindowController *persistenceSetupWindowController;
@property (nonatomic, strong) SBAboutWindowController *aboutWindowController;
@property (nonatomic, strong) RHPreferencesWindowController *preferencesWindowController;

- (BOOL)writeEnterpriseSourceLocationsToDisk:(NSString *)path;
- (void)readEnterpriseSourceLocationsFromDisk:(NSString *)path;

- (IBAction)showPreferencesWindow:(id)sender;
- (IBAction)showAboutWindow:(id)sender;
- (IBAction)showMoreOptionsPopover:(id)sender;
- (IBAction)hideMoreOptionsPopover:(id)sender;
- (IBAction)showProjectWebsite:(id)sender;
- (IBAction)reportBug:(id)sender;

@end
