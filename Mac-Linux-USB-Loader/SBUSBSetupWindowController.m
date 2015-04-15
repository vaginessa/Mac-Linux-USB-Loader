//
//  SBUSBSetupWindowController.m
//  Mac Linux USB Loader
//
//  Created by SevenBits on 1/18/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import "SBUSBSetupWindowController.h"
#import "SBAppDelegate.h"
#import "SBUSBDevice.h"

@interface SBUSBSetupWindowController ()

@property (strong) NSDictionary *usbDictionary;
@property (strong) NSMutableArray *usbIconArray;
@property (weak) IBOutlet NSTableView *tableView;
@property (weak) IBOutlet NSButton *enableStartupDiskButton;
@property (weak) IBOutlet NSImageView *usbImageView;
@property (weak) IBOutlet NSTextField *usbNameLabel;

@property (strong) NSMutableArray *usbArray;

@end

@implementation SBUSBSetupWindowController

- (id)initWithWindow:(NSWindow *)window {
	self = [super initWithWindow:window];
	if (self) {
		// Initialization code here.
		self.usbDictionary = [(SBAppDelegate *)[NSApp delegate] usbDictionary];
		self.usbIconArray = [[NSMutableArray alloc] init];
		self.usbArray = [[NSMutableArray alloc] initWithCapacity:[self.usbDictionary count]];
	}
	return self;
}

- (void)showWindow:(id)sender {
	[super showWindow:sender];

	[self.enableStartupDiskButton setEnabled:NO];
	[self loadUSBDeviceList:nil];
	[self.usbNameLabel setStringValue:@""];
}

- (IBAction)loadUSBDeviceList:(id)sender {
	[(SBAppDelegate *)[NSApp delegate] detectAndSetupUSBs];
	[self.usbArray removeAllObjects];
	[self.usbIconArray removeAllObjects];

	self.usbDictionary = [(SBAppDelegate *)[NSApp delegate] usbDictionary];
	[self.usbDictionary enumerateKeysAndObjectsUsingBlock:^(id key, SBUSBDevice *object, BOOL *stop) {
		//NSLog(@"%@ = %@", key, object);
		[self.usbArray addObject:object];

		NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:object.path];
		icon.size = NSMakeSize(512, 512);
		[self.usbIconArray addObject:icon];
	}];

	[self.tableView reloadData];
}

#pragma mark - Button Delegates

- (IBAction)chooseStartupDiskButtonPressed:(id)sender {
	[[NSWorkspace sharedWorkspace] openFile:@"/System/Library/PreferencePanes/StartupDisk.prefPane"];
}

- (IBAction)enableStartupSupportButtonPressed:(id)sender {
	if ([self.tableView selectedRow] != -1) {
		SBUSBDevice *selectedDrive = self.usbArray[[self.tableView selectedRow]];
		NSFileManager *manager = [NSFileManager defaultManager];
		NSString *path = selectedDrive.path;
		NSURL *outURL = [manager setupSecurityScopedBookmarkForUSBAtPath:path withWindowForSheet:nil];

		if (outURL) {
			if (selectedDrive.fileSystem != SBUSBDriveFileSystemHFS) {
				NSAlert *alert = [[NSAlert alloc] init];
				[alert addButtonWithTitle:NSLocalizedString(@"Okay", nil)];
				[alert setMessageText:NSLocalizedString(@"Cannot use this USB as a startup disk.", nil)];
				[alert setInformativeText:NSLocalizedString(@"This USB drive cannot be used as a startup disk because OS X only recognizes startup disks with an HFS+ file system.", nil)];
				[alert setAlertStyle:NSWarningAlertStyle];
				[alert beginSheetModalForWindow:self.window modalDelegate:self didEndSelector:@selector(regularSheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
				return;
			}

			[outURL startAccessingSecurityScopedResource];
			[selectedDrive enableStartupDiskSupport];
			[outURL stopAccessingSecurityScopedResource];
		}
	}
}

#pragma mark - Table View Delegates
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
	NSInteger row = [self.tableView selectedRow];

	[self.enableStartupDiskButton setEnabled:(row != -1)];
	self.usbImageView.image = (row != -1 ? self.usbIconArray[row] : nil);
	self.usbNameLabel.stringValue = (row != -1 ? [(SBUSBDevice *)self.usbArray[row] name] : @"");
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return [self.usbArray count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	SBUSBDevice *device = self.usbArray[rowIndex];
	return device.name;
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	return NO;
}

#pragma mark - Misc. Delegates
- (void)regularSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	// Empty
}

@end
