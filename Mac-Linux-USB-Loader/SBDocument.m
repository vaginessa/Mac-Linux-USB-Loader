//
//  SBDocument.m
//  Mac-Linux-USB-Loader
//
//  Created by SevenBits on 1/13/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import "SBDocument.h"
#import "SBAppDelegate.h"
#import "NSFileManager+Extensions.h"
#import "SBGlobals.h"

@implementation SBDocument {
	NSMutableDictionary *dict;
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
	/* STEP 1: Setup UI components. */
	// Get an NSFileManager object.
	NSFileManager *manager = [NSFileManager defaultManager];

	// Get the names of files.
	NSString *targetUSBName = [self.installationDriveSelector objectValueOfSelectedItem];
	NSString *installDirectory = [targetUSBName stringByAppendingString:@"/efi/boot/"];

	NSString *enterpriseInstallFileName = [installDirectory stringByAppendingString:@"bootX64.efi"];
	SBLogObject(enterpriseInstallFileName);

	// Set the size of the file to be the max value of the progress bar.
	[self.installationProgressBar setMaxValue:[[manager sizeOfFileAtPath:self.fileURL.path] doubleValue]];

	// Disable UI components.
	[sender setEnabled:NO];
	[self.installationDriveSelector setEnabled:NO];
	[self.installationProgressBar setIndeterminate:NO];
	[self.installationProgressBar setDoubleValue:0.0];
	SBLogObject(self.installationProgressBar);
	[self.automaticSetupCheckBox setEnabled:NO];

	/* STEP 2: Get user permission to install files. We'll only need to do this once. */
	NSURL *outURL = [manager setupSecurityScopedBookmarkForUSBAtPath:@"" withWindowForSheet:[self windowForSheet]];

	if (!outURL) {
		NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:NSLocalizedString(@"Okay", nil)];
        [alert setMessageText:NSLocalizedString(@"Couldn't get security scoped bookmarks.", nil)];
        [alert setInformativeText:NSLocalizedString(@"Couldn't access the USB device because the system denied access to the resource.", nil)];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert beginSheetModalForWindow:self.windowForSheet modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
		return;
	}

	/* STEP 3: Start copying files. */
	[outURL startAccessingSecurityScopedResource];

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		SBUSBDevice *usbDevice = [[NSApp delegate] usbDictionary][targetUSBName];
		[usbDevice copyInstallationFiles:self];

		dispatch_async(dispatch_get_main_queue(), ^{
			/* STEP 4: Restore access to the disabled buttons. */
			[sender setEnabled:YES];
			[self.installationDriveSelector setEnabled:YES];
			[self.installationProgressBar setDoubleValue:0.0];
			[self.automaticSetupCheckBox setEnabled:YES];

			[outURL stopAccessingSecurityScopedResource];
		});
	});
}

#pragma mark - Delegates
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    // Empty
}

@end
