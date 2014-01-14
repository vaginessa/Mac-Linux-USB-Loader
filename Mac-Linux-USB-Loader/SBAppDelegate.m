//
//  SBAppDelegate.m
//  Mac Linux USB Loader
//
//  Created by SevenBits on 1/13/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import "SBAppDelegate.h"

@implementation SBAppDelegate
@synthesize window;
@synthesize operationsTableView;
@synthesize applicationVersionString;

#pragma mark - Object Setup

- (id)init {
    self = [super init];
    if (self) {
		// Setup code goes here.
    }
    return self;
}

#pragma mark - Application Setup

- (void)applicationDidFinishLaunching: (NSNotification *)aNotification {
	/* Set window properties. */
	[self.window setBackgroundColor:[NSColor whiteColor]];

	// Set window resize behavior.
	[[self.window standardWindowButton:NSWindowZoomButton] setHidden:YES];
	[[self.window standardWindowButton:NSWindowMiniaturizeButton] setHidden:YES];
	[self.window setShowsResizeIndicator:NO];
	[self.window setResizeIncrements:NSMakeSize(MAXFLOAT, MAXFLOAT)];

	[self.window setTitle:@""]; // Remove the title.

	/* Make the table respond to our double click operations. */
	[self.operationsTableView setDoubleAction:@selector(userSelectedOperationFromTable)];

	/* Set the application version label string. */
	[self.applicationVersionString setStringValue:
	 [NSString stringWithFormat:@"Version %@",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]]];
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender {
    [self.window makeKeyAndOrderFront:nil];
    return YES;
}

#pragma mark - Table View Delegates

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return 4;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSTableCellView *result = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
	switch (row) {
		case 0:
			result.imageView.image = [[NSImage imageNamed:@"AppIcon"] copy];
			result.textField.stringValue = NSLocalizedString(@"Create Live USB", nil);
			break;

		case 1:
			result.imageView.image = [[NSImage imageNamed:@"AppIcon"] copy];
			result.textField.stringValue = NSLocalizedString(@"Setup USB Device", nil);
			break;

		case 2:
			result.imageView.image = [[NSImage imageNamed:@"AppIcon"] copy];
			result.textField.stringValue = NSLocalizedString(@"Persistence Manager", nil);
			break;

		case 3:
			result.imageView.image = [[NSImage imageNamed:@"AppIcon"] copy];
			result.textField.stringValue = NSLocalizedString(@"Distribution Downloader", nil);
			break;

		default:
			break;
	}
    return result;
}

- (void)userSelectedOperationFromTable {
    NSInteger clickedRow = [self.operationsTableView clickedRow];

	if (clickedRow != -1) { // We've selected a valid table entry.
		[self.window orderOut:nil];

		switch (clickedRow) {
			case 0:
				[[NSDocumentController sharedDocumentController] openDocument:nil];
				break;

			default:
				[self.window makeKeyAndOrderFront:nil];
				break;
		}
	}
}

@end
