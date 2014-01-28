//
//  SBDocument.m
//  Mac-Linux-USB-Loader
//
//  Created by SevenBits on 1/13/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import "SBDocument.h"
#import "SBAppDelegate.h"
#import "SBGlobals.h"

@implementation SBDocument {
	NSMutableDictionary *dict;
	NSOpenPanel *spanel;
}

#pragma mark - Document class crap
- (id)init {
    self = [super init];
    if (self) {
		// Add your subclass-specific initialization here.
    }
    return self;
}

- (NSString *)windowNibName {
	return @"SBDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
	[super windowControllerDidLoadNib:aController];

	// If the user opens the document by dragging the file from the Dock, the main screen will still be open.
	// We hide it here for a better user experience.
	[[[NSApp delegate] window] orderOut:nil];

	// Grab the list of USB devices from the App Delegate.
	// Setup the USB selector.
	dict = [NSMutableDictionary dictionaryWithDictionary:[[NSApp delegate] usbDictionary]];
	NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:[dict count]];

	for (NSString *usb in dict) {
		[array insertObject:[dict[usb] name] atIndex:0];
	}

    [self.popupValues addObjects:array];

	[self.installationDriveSelector addItemWithObjectValue:@"---"];
	[self.installationDriveSelector setStringValue:@"---"];
	[self.installationDriveSelector addItemsWithObjectValues:array];
	//[self.installationDriveSelector setDelegate:self];
}

#pragma mark - Document Plumbing
+ (BOOL)autosavesInPlace {
    return YES;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
	return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
	return YES;
}

#pragma mark - Installation Code
- (IBAction)performInstallation:(id)sender {
	/* STEP 1: Disable UI components. */
	[sender setEnabled:NO];
	[self.installationDriveSelector setEnabled:NO];
	[self.installationProgressBar setDoubleValue:0.0];
	[self.automaticSetupCheckBox setEnabled:NO];

	/* STEP 2: Get user permission to install files. We'll only need to do this once. */
	//NSURL *fileURL = [self fileURL];
	NSString *targetUSBName = [self.installationDriveSelector objectValueOfSelectedItem];
	NSString *enterpriseInstallFileName = [targetUSBName stringByAppendingString:@"/efi/boot/bootX64.efi"];
	SBLogObject(enterpriseInstallFileName);

	spanel = [NSOpenPanel openPanel];
	[spanel setMessage:NSLocalizedString(@"Click Open below to authorize the creation of the boot folder.", nil)];
	[spanel setDirectoryURL:[NSURL URLWithString:
							 [@"/Volumes/" stringByAppendingString:[self.installationDriveSelector objectValueOfSelectedItem]]]];
	[spanel setNameFieldStringValue:@""];
    [spanel setCanChooseDirectories:YES];
    [spanel setCanSelectHiddenExtension:NO];
    [spanel setTreatsFilePackagesAsDirectories:NO];
    [spanel beginSheetModalForWindow:[self windowForSheet] completionHandler:^(NSInteger result) {
		// Create a security scoped bookmark here so we don't ask the user again.
		NSURL *url = [spanel URL];
        NSData *data = [url bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope includingResourceValuesForKeys:nil relativeToURL:nil error:nil];
        if (data) {
            NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
            [prefs setObject:data forKey:[targetUSBName stringByAppendingString:@"_USBSecurityBookmarkTarget"]];
            [prefs synchronize];
        }
	}];
}

@end
