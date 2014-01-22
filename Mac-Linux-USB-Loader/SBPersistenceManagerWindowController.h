//
//  SBPersistenceManagerWindowController.h
//  Mac Linux USB Loader
//
//  Created by SevenBits on 1/22/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SBPersistenceManagerWindowController : NSWindowController <NSComboBoxDelegate, NSControlTextEditingDelegate>

@property (assign) IBOutlet NSArrayController *popupValues;
@property (weak) IBOutlet NSComboBox *usbSelectorPopup;

@property (weak) IBOutlet NSBox *persistenceOptionsSetupBox;
@property (weak) IBOutlet NSSlider *persistenceVolumeSizeSlider;
@property (weak) IBOutlet NSTextField *persistenceVolumeSizeTextField;

- (IBAction)createPersistenceButtonPressed:(id)sender;

@end
