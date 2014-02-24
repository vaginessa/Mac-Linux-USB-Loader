//
//  SBEnterprisePreferencesViewController.h
//  Mac Linux USB Loader
//
//  Created by SevenBits on 2/14/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <RHPreferences/RHPreferences.h>

@interface SBEnterprisePreferencesViewController : NSViewController <RHPreferencesViewControllerProtocol, NSTableViewDataSource, NSTableViewDelegate>

@property (strong) IBOutlet NSWindow *addNewEnterpriseSourcePanel;

@property (weak) IBOutlet NSTableView *tableView;
@property (weak) IBOutlet NSButton *updateSettingsButton;
@property (weak) IBOutlet NSButton *addSourceLocationButton;
@property (weak) IBOutlet NSButton *deleteSourceLocationButton;
@property (weak) IBOutlet NSTextField *sourceLocationPathTextField;
@property (weak) IBOutlet NSTextField *sourceVersionTextField;
@property (weak) IBOutlet NSTextField *sourceNameTextField;

@property (weak) NSMutableDictionary *enterpriseSourceLocationsDictionary;

- (IBAction)addSourceLocationButtonPressed:(id)sender;
- (IBAction)hideSourceLocationButtonPressed:(id)sender;
- (IBAction)showSourcePathSelectorDialog:(id)sender;
- (IBAction)confirmSourceLocationInformation:(id)sender;

@end
