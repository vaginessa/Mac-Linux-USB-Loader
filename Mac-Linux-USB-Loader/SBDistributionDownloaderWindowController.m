//
//  SBDistributionDownloaderWindowController.m
//  Mac Linux USB Loader
//
//  Created by SevenBits on 5/9/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import "SBDistributionDownloaderWindowController.h"
#import "SBAppDelegate.h"

@interface SBDistributionDownloaderWindowController ()

@property (strong) IBOutlet NSView *accessoryView;
@property (weak) IBOutlet NSTableView *tableView;

@end

@implementation SBDistributionDownloaderWindowController

#pragma mark - Object Setup
- (id)initWithWindow:(NSWindow *)window {
	self = [super initWithWindow:window];
	if (self) {
		// Initialization code here.
	}
	return self;
}

- (void)windowDidLoad {
	[super windowDidLoad];

	// Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
	[self.window setDelegate:self];

	// Setup the accessory view.
	[self placeAccessoryView];

	NSView *themeFrame = [[self.window contentView] superview];
	[themeFrame addSubview:self.accessoryView];

	// Setup delegates.
	[self.tableView setDataSource:self];
	[self.tableView setDelegate:self];
}

#pragma mark - Delegates
- (void)windowDidResize:(NSNotification *)notification {
	// Keep the accessory view in the right place in the window.
	[self placeAccessoryView];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return [[[NSApp delegate] supportedDistributions] count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	if ([[[aTableColumn headerCell] stringValue] isEqualToString:NSLocalizedString(@"Distribution Name", nil)]) {
		return [[[NSApp delegate] supportedDistributions] objectAtIndex:rowIndex];
	} else if ([[[aTableColumn headerCell] stringValue] isEqualToString:NSLocalizedString(@"Current Version", nil)]) {
		NSString *distribution = [[[NSApp delegate] supportedDistributions] objectAtIndex:rowIndex];
		return [[[NSApp delegate] supportedDistributionsAndVersions] objectForKey:distribution];
	} else {
		return @"N/A";
	}
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	return NO;
}

#pragma mark - UI
- (void)placeAccessoryView {
	NSView *themeFrame = [[self.window contentView] superview];
	NSRect c = [themeFrame frame];  // c for "container"
	NSRect aV = [self.accessoryView frame]; // aV for "accessory view"
	NSRect newFrame = NSMakeRect(c.size.width - aV.size.width - 25, // x position
	                             c.size.height - aV.size.height, // y position
	                             aV.size.width, // width
	                             aV.size.height); // height
	[self.accessoryView setFrame:newFrame];
	[self.accessoryView setNeedsDisplay:YES];
}

@end
