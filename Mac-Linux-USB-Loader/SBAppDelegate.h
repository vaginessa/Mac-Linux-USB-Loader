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

@interface SBAppDelegate : NSObject {
	__unsafe_unretained NSWindow *window;
	__weak NSTableView *operationsTableView;
	__weak NSTextField *applicationVersionString;
}

@property (unsafe_unretained) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTableView *operationsTableView;
@property (weak) IBOutlet NSTextField *applicationVersionString;
@property (weak) IBOutlet NSPopover *moreOptionsPopover;

@property (nonatomic, strong) NSMutableDictionary *usbDictionary;

@property (nonatomic, strong) SBUSBSetupWindowController *usbSetupWindowController;
@property (nonatomic, strong) SBPersistenceManagerWindowController *persistenceSetupWindowController;

- (IBAction)showMoreOptionsPopover:(id)sender;
- (IBAction)hideMoreOptionsPopover:(id)sender;
- (IBAction)showProjectWebsite:(id)sender;
- (IBAction)reportBug:(id)sender;

@end
