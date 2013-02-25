//
//  Document.h
//  Mac Linux USB Loader
//
//  Created by SevenBits on 11/26/12.
//  Copyright (c) 2012 SevenBits. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RHPreferences/RHPreferences.h"

@interface Document : NSDocument
@property (strong) IBOutlet NSWindow *window;
@property (strong) IBOutlet NSPanel *prefsWindow;
@property (unsafe_unretained) IBOutlet NSButton *makeUSBButton;
@property (unsafe_unretained) IBOutlet NSButton *eraseUSBButton;
@property (unsafe_unretained) IBOutlet NSProgressIndicator *spinner;
@property (weak) IBOutlet NSProgressIndicator *indeterminate;
@property (retain) RHPreferencesWindowController *preferencesWindowController;
@property (unsafe_unretained) IBOutlet NSPopUpButton *usbDriveDropdown;
- (IBAction)openDiskUtility:(id)sender;
- (IBAction)eraseLiveBoot:(id)sender;
- (void)getUSBDeviceList;
- (void)regularAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (IBAction)updateDeviceList:(id)sender;
- (IBAction)makeLiveUSB:(id)sender;
- (IBAction)openGithubPage:(id)sender;
- (IBAction)reportBug:(id)sender;

// A (C!) callback to get the progress of the copy operation.
static void copyStatusCallback(FSFileOperationRef fileOp, const FSRef *currentItem, FSFileOperationStage stage, OSStatus error,
                            CFDictionaryRef statusDictionary, void *info);


@end
