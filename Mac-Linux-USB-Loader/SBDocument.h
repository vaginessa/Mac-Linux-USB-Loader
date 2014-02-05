//
//  SBDocument.h
//  Mac-Linux-USB-Loader
//
//  Created by SevenBits on 1/13/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SBDocument : NSDocument <NSComboBoxDelegate, NSControlTextEditingDelegate>

@property (assign) IBOutlet NSArrayController *popupValues;

@property (weak) IBOutlet NSImageView *imageIcon;
@property (weak) IBOutlet NSProgressIndicator *installationProgressBar;
@property (weak) IBOutlet NSComboBox *installationDriveSelector;
@property (weak) IBOutlet NSButton *automaticSetupCheckBox;
@property (weak) IBOutlet NSButton *performInstallationButton;

- (IBAction)performInstallation:(id)sender;

@end
