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

@property (weak) IBOutlet NSTableView *tableView;
@property (weak) IBOutlet NSButton *updateSettingsButton;
@property (weak) IBOutlet NSButton *addSourceLocationButton;
@property (weak) IBOutlet NSButton *deleteSourceLocationButton;

@property (weak) NSMutableDictionary *enterpriseSourceLocationsDictionary;

@end
