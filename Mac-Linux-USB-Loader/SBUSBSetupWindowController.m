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

@property (weak) NSDictionary *usbDictionary;
@property (weak) IBOutlet NSTableView *tableView;

@property (strong) NSMutableArray *usbArray;

@end

@implementation SBUSBSetupWindowController

- (id)initWithWindow:(NSWindow *)window {
	self = [super initWithWindow:window];
	if (self) {
		// Initialization code here.
		self.usbDictionary = [(SBAppDelegate *)[NSApp delegate] usbDictionary];
		SBLogObject(self.usbDictionary);

		self.usbArray = [[NSMutableArray alloc] initWithCapacity:[self.usbDictionary count]];
		for (SBUSBDevice *device in self.usbDictionary) {
			[self.usbArray addObject:device];
		}

		SBLogObject(self.usbArray);
	}
	return self;
}

- (void)windowDidLoad {
	[super windowDidLoad];
}

- (IBAction)chooseStartupDiskButtonPressed:(id)sender {
	[[NSWorkspace sharedWorkspace] openFile:@"/System/Library/PreferencePanes/StartupDisk.prefPane"];
}

#pragma mark - Table View Delegates
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return [self.usbArray count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	SBUSBDevice *device = self.usbArray[rowIndex];
	return device;
}

@end
