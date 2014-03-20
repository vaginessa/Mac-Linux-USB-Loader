//
//  SBDocument.h
//  Mac-Linux-USB-Loader
//
//  Created by SevenBits on 1/13/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SBDocument : NSDocument <NSComboBoxDelegate, NSControlTextEditingDelegate> {
	IBOutlet NSArrayController *arrayController;
}

@property (strong) NSMutableArray *usbDictionaryDropdownPopupValues;

@property (weak) IBOutlet NSImageView *imageIcon;
@property (weak) IBOutlet NSProgressIndicator *installationProgressBar;
@property (weak) IBOutlet NSCollectionView *usbDriveSelector;
@property (weak) IBOutlet NSComboBox *enterpriseSourceSelector;
@property (weak) IBOutlet NSButton *automaticSetupCheckBox;
@property (weak) IBOutlet NSButton *performInstallationButton;

@property (nonatomic, assign) BOOL automaticSetupCheckBoxChecked;

- (IBAction)performInstallation:(id)sender;

@end
