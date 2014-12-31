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

@property (strong) NSMutableArray *usbArrayForContentView;
@property NSInteger indexOfSelectedTab;

@property (weak) IBOutlet NSTabView *tabView;
@property (weak) IBOutlet NSImageView *imageIcon;
@property (weak) IBOutlet NSProgressIndicator *installationProgressBar;
@property (weak) IBOutlet NSCollectionView *usbDriveSelector;
@property (weak) IBOutlet NSPopUpButton *enterpriseSourceSelector;
@property (weak) IBOutlet NSButton *automaticSetupCheckBox;
@property (weak) IBOutlet NSButton *performInstallationButton;
@property (weak) IBOutlet NSPopUpButton *distributionSelectorPopup;
@property (weak) IBOutlet NSButton *isMacVersionCheckBox;
@property (weak) IBOutlet NSButton *isLegacyUbuntuVersionCheckBox;

@property (nonatomic, assign) BOOL automaticSetupCheckBoxChecked;

- (IBAction)performInstallation:(id)sender;
- (IBAction)refreshUSBListing:(id)sender;

@end
