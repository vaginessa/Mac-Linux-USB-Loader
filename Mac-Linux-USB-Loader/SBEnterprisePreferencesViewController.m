//
//  SBEnterprisePreferencesViewController.m
//  Mac Linux USB Loader
//
//  Created by SevenBits on 2/14/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import "SBEnterprisePreferencesViewController.h"
#import "SBEnterpriseSourceLocation.h"
#import "SBAppDelegate.h"
#import "SBGlobals.h"

@interface SBEnterprisePreferencesViewController ()

@property (strong) NSMutableArray *listOfArrayKeys;

@end

@implementation SBEnterprisePreferencesViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
		self.enterpriseSourceLocationsDictionary = [[NSApp delegate] enterpriseInstallLocations];
		self.listOfArrayKeys = [[NSMutableArray alloc] initWithCapacity:[self.enterpriseSourceLocationsDictionary count]];

		for (NSString *title in self.enterpriseSourceLocationsDictionary) {
			[self.listOfArrayKeys addObject:title];
		}
    }
    return self;
}

- (void)awakeFromNib {
	[self.tableView setDataSource:self];
	[self.tableView setDelegate:self];
}

- (NSString*)identifier{
    return NSStringFromClass(self.class);
}

- (NSImage*)toolbarItemImage{
    return [NSImage imageNamed:@"UEFILogo"];
}

- (NSString*)toolbarItemLabel{
    return NSLocalizedString(@"Enterprise", nil);
}

#pragma mark - Table View Delegates

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [self.enterpriseSourceLocationsDictionary count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	NSString *cellTitle = [aTableColumn.headerCell stringValue];
	SBEnterpriseSourceLocation *loc = self.enterpriseSourceLocationsDictionary[self.listOfArrayKeys[rowIndex]];

	if ([cellTitle isEqualToString:@"Installation Path"]) {
		return loc.name;
	} else if ([cellTitle isEqualToString:@"Version"]) {
		if ([loc.version isEqualToString:@""] || loc.version == nil) {
			return @"N/A";
		} else {
			return loc.version;
		}
	}
	return @"N/A";
}

@end
