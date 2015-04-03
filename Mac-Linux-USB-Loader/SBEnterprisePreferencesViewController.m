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
		self.enterpriseSourceLocationsDictionary = [(SBAppDelegate *)[NSApp delegate] enterpriseInstallLocations];
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
	[self.sourceVersionTextField setStringValue:SBBundledEnterpriseVersionNumber];
}

- (NSString *)identifier {
	return NSStringFromClass(self.class);
}

- (NSImage *)toolbarItemImage {
	return [NSImage imageNamed:@"EnterpriseLogo"];
}

- (NSString *)toolbarItemLabel {
	return NSLocalizedString(@"Enterprise", nil);
}

#pragma mark - Table View Delegates

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return [self.enterpriseSourceLocationsDictionary count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	NSString *cellTitle = aTableColumn.identifier;
	SBEnterpriseSourceLocation *loc = self.enterpriseSourceLocationsDictionary[self.listOfArrayKeys[rowIndex]];

	if ([cellTitle isEqualToString:@"nameCol"]) {
		return loc.name;
	} else if ([cellTitle isEqualToString:@"versionCol"]) {
		if ([loc.version isEqualToString:@""] || loc.version == nil) {
			return @"N/A";
		} else {
			// If we're dealing with the bundled Enterprise, return the global string representing the version number of
			// the bundled Enterprise rather than the value stored in the object, as this value will not be updated when
			// Mac Linux USB Loader ships with an updated copy of Enterprise.
			if (!loc.deletable && [loc.name isEqualToString:@"Included With Application"]) {
				return SBBundledEnterpriseVersionNumber;
			} else {
				return loc.version;
			}
		}
	}
	return @"N/A";
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	SBEnterpriseSourceLocation *loc = self.enterpriseSourceLocationsDictionary[self.listOfArrayKeys[rowIndex]];
	NSString *cellTitle = [aTableColumn.headerCell stringValue];

	if (![loc deletable]) {
		return NO;
	}
	if ([cellTitle isEqualToString:NSLocalizedString(@"Version", nil)]) {
		return NO;
	}

	return YES;
}

- (NSCell *)tableView:(NSTableView *)tableView dataCellForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex {
	NSFileManager *manager = [NSFileManager defaultManager];
	SBEnterpriseSourceLocation *loc = self.enterpriseSourceLocationsDictionary[self.listOfArrayKeys[rowIndex]];
	[loc.securityScopedBookmark startAccessingSecurityScopedResource];
	NSTextFieldCell *cell = [tableColumn dataCell];
	if (!loc.deletable && [self.tableView selectedRow] != rowIndex) {
		[cell setTextColor:[NSColor darkGrayColor]];
	} else if (![manager fileExistsAtPath:loc.path] && loc.securityScopedBookmark) {
		[cell setTextColor:[NSColor redColor]];
	} else {
		[cell setTextColor:[NSColor blackColor]];
	}

	[loc.securityScopedBookmark stopAccessingSecurityScopedResource];
	return cell;
}

#pragma mark - IBActions

- (IBAction)addSourceLocationButtonPressed:(id)sender {
	[NSApp beginSheet:self.addNewEnterpriseSourcePanel modalForWindow:[self.view window] modalDelegate:self didEndSelector:NULL contextInfo:nil];
}

- (IBAction)hideSourceLocationButtonPressed:(id)sender {
	[self.addNewEnterpriseSourcePanel orderOut:nil];
	[NSApp endSheet:self.addNewEnterpriseSourcePanel];
}

- (IBAction)removeSourceLocationButtonPressed:(id)sender {
	NSInteger selectedRow = [self.tableView selectedRow];
	SBEnterpriseSourceLocation *deviceHere = [(SBAppDelegate *)[NSApp delegate] enterpriseInstallLocations][self.listOfArrayKeys[selectedRow]];
	if (!deviceHere.deletable) {
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:NSLocalizedString(@"Okay", nil)];
		[alert setMessageText:NSLocalizedString(@"This source can't be deleted.", nil)];
		[alert setInformativeText:NSLocalizedString(@"This source can't be deleted because it is included with Mac Linux USB Loader.", nil)];
		[alert setAlertStyle:NSWarningAlertStyle];
		[alert beginSheetModalForWindow:[self.view window] modalDelegate:self didEndSelector:@selector(regularSheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
		return;
	}

	[[(SBAppDelegate *)[NSApp delegate] enterpriseInstallLocations] removeObjectForKey:self.listOfArrayKeys[selectedRow]];
	[self.listOfArrayKeys removeAllObjects];
	for (NSString *title in self.enterpriseSourceLocationsDictionary) {
		[self.listOfArrayKeys addObject:title];
	}

	// Write source locations to disk.
	NSString *filePath = [[(SBAppDelegate *)[NSApp delegate] pathToApplicationSupportDirectory] stringByAppendingString:@"/EnterpriseInstallationLocations.plist"];
	[(SBAppDelegate *)[NSApp delegate] writeEnterpriseSourceLocationsToDisk:filePath];

	// Update user preferences.
	[[NSUserDefaults standardUserDefaults] setObject:@"Included With Application" forKey:@"DefaultEnterpriseSourceLocation"];

	// Reload the table with our new data.
	[self.tableView reloadData];
	[self hideSourceLocationButtonPressed:nil];
}

- (IBAction)showSourcePathSelectorDialog:(id)sender {
	enterpriseSourceLocationOpenPanel = [NSOpenPanel openPanel];
	[enterpriseSourceLocationOpenPanel setMessage:NSLocalizedString(@"Please select the directory containing Enterprise files.", nil)];
	[enterpriseSourceLocationOpenPanel setCanChooseDirectories:YES];
	[enterpriseSourceLocationOpenPanel setCanChooseFiles:NO];
	[enterpriseSourceLocationOpenPanel beginSheetModalForWindow:self.addNewEnterpriseSourcePanel completionHandler: ^(NSInteger result) {
	    if (result == NSFileHandlingPanelOKButton) {
			NSString *enteredPath = [[enterpriseSourceLocationOpenPanel URL] path];
			__block NSString *localizedPath = [NSString string];
			localizedPath = [localizedPath stringByAppendingPathComponent:@"/"];
			NSArray *localizedPathComponents = [[NSFileManager defaultManager] componentsToDisplayForPath:enteredPath];
			[localizedPathComponents enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
				// Exclude the name of the hard disk.
				if (![obj isEqualToString:@"Macintosh HD"]) {
					localizedPath = [localizedPath stringByAppendingPathComponent:(NSString *)obj];
				}
			}];

	        [self.sourceLocationPathTextField setStringValue:localizedPath];
		}
	}

	];
}

- (IBAction)confirmSourceLocationInformation:(id)sender {
	NSString *name = [self.sourceNameTextField stringValue];
	NSString *version = [self.sourceVersionTextField stringValue];
	NSString *location = [[[self.sourceLocationPathTextField stringValue] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] componentsJoinedByString:@""];

	if ([location isEqualToString:@""]) {
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:NSLocalizedString(@"Okay", nil)];
		[alert setMessageText:NSLocalizedString(@"No source location path entered.", nil)];
		[alert setInformativeText:NSLocalizedString(@"You need to enter a path to a folder containing a valid set of Enterprise binaries.", nil)];
		[alert setAlertStyle:NSWarningAlertStyle];
		[alert beginSheetModalForWindow:self.addNewEnterpriseSourcePanel modalDelegate:self didEndSelector:@selector(regularSheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
		return;
	} else if ([name isEqualToString:@""]) {
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:NSLocalizedString(@"Okay", nil)];
		[alert setMessageText:NSLocalizedString(@"No source location name entered.", nil)];
		[alert setInformativeText:NSLocalizedString(@"You need to enter a name for this Enterprise installation source.", nil)];
		[alert setAlertStyle:NSWarningAlertStyle];
		[alert beginSheetModalForWindow:self.addNewEnterpriseSourcePanel modalDelegate:self didEndSelector:@selector(regularSheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
		return;
	} else if ([version isEqualToString:@""]) {
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:NSLocalizedString(@"Okay", nil)];
		[alert setMessageText:NSLocalizedString(@"No source location version entered.", nil)];
		[alert setInformativeText:NSLocalizedString(@"You need to enter the version of this Enterprise installation source.", nil)];
		[alert setAlertStyle:NSWarningAlertStyle];
		[alert beginSheetModalForWindow:self.addNewEnterpriseSourcePanel modalDelegate:self didEndSelector:@selector(regularSheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
		return;
	} else if ([(SBAppDelegate *)[NSApp delegate] enterpriseInstallLocations][name]) {
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:NSLocalizedString(@"Okay", nil)];
		[alert setMessageText:NSLocalizedString(@"Invalid location name entered.", nil)];
		[alert setInformativeText:NSLocalizedString(@"The name that you have entered for this Enterprise source already exists. Please enter a different name.", nil)];
		[alert setAlertStyle:NSWarningAlertStyle];
		[alert beginSheetModalForWindow:self.addNewEnterpriseSourcePanel modalDelegate:self didEndSelector:@selector(regularSheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
		return;
	}

	NSURL *bookmark = [[NSFileManager defaultManager] createSecurityScopedBookmarkForPath:enterpriseSourceLocationOpenPanel.URL];
	if (bookmark) {
		SBEnterpriseSourceLocation *loc = [[SBEnterpriseSourceLocation alloc] initWithName:name withPath:enterpriseSourceLocationOpenPanel.URL.path withVersionNumber:version withSecurityScopedBookmark:bookmark shouldBeVolatile:YES];

		if (![self verifyEnterpriseInstallationDirectory:loc.path]) {
			NSAlert *alert = [[NSAlert alloc] init];
			[alert addButtonWithTitle:NSLocalizedString(@"Okay", nil)];
			[alert setMessageText:NSLocalizedString(@"The source that you entered is not valid.", nil)];
			[alert setInformativeText:NSLocalizedString(@"The source that you have selected is not valid because one or more of the Enterprise binaries are missing.", nil)];
			[alert setAlertStyle:NSWarningAlertStyle];
			[alert beginSheetModalForWindow:self.addNewEnterpriseSourcePanel modalDelegate:self didEndSelector:@selector(regularSheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
			return;
		}

		// Add the newly-created object to our list of Enterprise source locations.
		[(SBAppDelegate *)[NSApp delegate] enterpriseInstallLocations][name] = loc;
		self.enterpriseSourceLocationsDictionary[name] = loc;
		[self.listOfArrayKeys removeAllObjects];
		for (NSString *title in self.enterpriseSourceLocationsDictionary) {
			[self.listOfArrayKeys addObject:title];
		}

		// Write source locations to disk.
		NSString *filePath = [[(SBAppDelegate *)[NSApp delegate] pathToApplicationSupportDirectory] stringByAppendingString:@"/EnterpriseInstallationLocations.plist"];
		[(SBAppDelegate *)[NSApp delegate] writeEnterpriseSourceLocationsToDisk : filePath];

		// Reload the table with our new data.
		[self.tableView reloadData];
		[self hideSourceLocationButtonPressed:nil];
	} else {
		NSLog(@"No permissions!");
	}
}

- (BOOL)verifyEnterpriseInstallationDirectory:(NSString *)path {
	NSFileManager *manager = [NSFileManager defaultManager];
	BOOL isValid = [manager fileExistsAtPath:[path stringByAppendingPathComponent:@"boot.efi"]] && [manager fileExistsAtPath:[path stringByAppendingPathComponent:@"bootX64.efi"]];
	return isValid;
}

- (IBAction)updateSettingsButtonPressed:(id)sender {
	NSInteger selectedRow = [self.tableView selectedRow];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *enterpriseLocations = [(SBAppDelegate *)[NSApp delegate] enterpriseInstallLocations];
	NSString *selectedSourceTitle = [enterpriseLocations[self.listOfArrayKeys[selectedRow]] name];

	[defaults setObject:selectedSourceTitle forKey:@"DefaultEnterpriseSourceLocation"];
}

#pragma mark - Delegates
- (void)regularSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	// Empty
}

@end
