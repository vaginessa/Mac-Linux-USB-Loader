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

@implementation SBEnterprisePreferencesViewController {
	NSOpenPanel *enterpriseSourceLocationOpenPanel;
}

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

#pragma mark - IBActions

- (IBAction)addSourceLocationButtonPressed:(id)sender {
	[NSApp beginSheet:self.addNewEnterpriseSourcePanel modalForWindow:[self.view window] modalDelegate:self didEndSelector:NULL contextInfo:nil];
}

- (IBAction)hideSourceLocationButtonPressed:(id)sender {
	[self.addNewEnterpriseSourcePanel orderOut:nil];
    [NSApp endSheet:self.addNewEnterpriseSourcePanel];
}

- (IBAction)showSourcePathSelectorDialog:(id)sender {
	enterpriseSourceLocationOpenPanel = [NSOpenPanel openPanel];
	[enterpriseSourceLocationOpenPanel setMessage:NSLocalizedString(@"Please select the directory containing Enterprise files.", nil)];
    [enterpriseSourceLocationOpenPanel setCanChooseDirectories:YES];
    [enterpriseSourceLocationOpenPanel setCanChooseFiles:NO];
    [enterpriseSourceLocationOpenPanel beginSheetModalForWindow:self.addNewEnterpriseSourcePanel completionHandler:^(NSInteger result) {
		[self.sourceLocationPathTextField setStringValue:[[enterpriseSourceLocationOpenPanel URL] path]];
    }];
}

- (IBAction)confirmSourceLocationInformation:(id)sender {
	NSString *name = [self.sourceNameTextField stringValue];
	NSString *version = [self.sourceVersionTextField stringValue];
	NSLog(@"%@, %@", name, version);

	NSURL *bookmark = [[NSFileManager defaultManager] createSecurityScopedBookmarkForPath:enterpriseSourceLocationOpenPanel.URL];
	if (bookmark) {
		SBEnterpriseSourceLocation *loc = [[SBEnterpriseSourceLocation alloc] initWithName:name withPath:enterpriseSourceLocationOpenPanel.URL.path withVersionNumber:version withSecurityScopedBookmark:bookmark shouldBeVolatile:YES];

		// Add the newly-created object to our list of Enterprise source locations.
		[[NSApp delegate] enterpriseInstallLocations][name] = loc;
		self.enterpriseSourceLocationsDictionary[name] = loc;
		[self.listOfArrayKeys removeAllObjects];
		for (NSString *title in self.enterpriseSourceLocationsDictionary) {
			[self.listOfArrayKeys addObject:title];
		}

		// Write source locations to disk.
		NSString *filePath = [[[NSApp delegate] pathToApplicationSupportDirectory] stringByAppendingString:@"/EnterpriseInstallationLocations.plist"];
		[[NSApp delegate] writeEnterpriseSourceLocationsToDisk:filePath];

		// Reload the table with our new data.
		[self.tableView reloadData];
		[self hideSourceLocationButtonPressed:nil];
	} else {
		NSLog(@"No permissions!");
	}
}
@end
