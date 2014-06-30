//
//  SBDocument.m
//  Mac-Linux-USB-Loader
//
//  Created by SevenBits on 1/13/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import "SBDocument.h"
#import "SBAppDelegate.h"
#import "SBEnterpriseSourceLocation.h"
#import "SBUSBDevice.h"
#import "SBUSBDeviceCollectionViewRepresentation.h"
#import "NSFileManager+Extensions.h"
#import "NSString+Extensions.h"

@implementation SBDocument {
	NSMutableDictionary *usbDictionary;
	NSMutableDictionary *enterpriseSourcesDictionary;
}

#pragma mark - Document class crap
- (id)init {
	self = [super init];
	if (self) {
		// Add your subclass-specific initialization here.
		self.usbArrayForContentView = [[NSMutableArray alloc] init];
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

	[self setupUSBDriveSelector];

	[self.performInstallationButton setEnabled:NO];
}

- (void)setupUSBDriveSelector {
	// Grab the list of USB devices from the App Delegate and setup the USB selector.
	usbDictionary = [NSMutableDictionary dictionaryWithDictionary:[[NSApp delegate] usbDictionary]];
	NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:[usbDictionary count]];

	for (NSString *usb in usbDictionary) {
		SBUSBDeviceCollectionViewRepresentation *rep = [[SBUSBDeviceCollectionViewRepresentation alloc] init];
		SBUSBDevice *deviceRep = usbDictionary[usb];
		rep.name = deviceRep.name;

		[array addObject:deviceRep];
	}

	[arrayController addObjects:array];

	// Grab the Enterprise sources from the App Delegate.
	[array removeAllObjects];
	enterpriseSourcesDictionary = [NSMutableDictionary dictionaryWithDictionary:[[NSApp delegate] enterpriseInstallLocations]];
	for (NSString *usb in enterpriseSourcesDictionary) {
		[array insertObject:[enterpriseSourcesDictionary[usb] name] atIndex:0];
	}

	[self.enterpriseSourceSelector addItemsWithTitles:array];
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
- (void)comboBoxSelectionDidChange:(NSNotification *)notification {
	/*if (notification.object == self.installationDriveSelector) {
	    if ([self.installationDriveSelector indexOfSelectedItem] == 0) {
	        [self.performInstallationButton setEnabled:NO];
	    } else {
	        [self.performInstallationButton setEnabled:YES];
	    }
	   }*/
}

- (IBAction)performInstallation:(id)sender {
	/* STEP 1: Setup UI components. */
	NSIndexSet *indexSet = [self.usbDriveSelector selectionIndexes];
	SBUSBDevice *selectedUSBDrive;

	if (indexSet && [indexSet firstIndex] != NSNotFound) {
		selectedUSBDrive = self.usbArrayForContentView[[indexSet firstIndex]];
	} else {
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:NSLocalizedString(@"Okay", nil)];
		[alert setMessageText:NSLocalizedString(@"No USB drive selected.", nil)];
		[alert setInformativeText:NSLocalizedString(@"You need to select the USB drive to install to.", nil)];
		[alert setAlertStyle:NSWarningAlertStyle];
		[alert beginSheetModalForWindow:self.windowForSheet modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
		return;
	}

	// Check to make sure that the user has selected an Enterprise source.
	NSInteger selectedEnterpriseSourceIndex = [self.enterpriseSourceSelector indexOfSelectedItem];
	SBUSBDevice *selectedEnterpriseSource = self.usbArrayForContentView[selectedEnterpriseSourceIndex];

	if (selectedEnterpriseSourceIndex == -1 || selectedEnterpriseSource == nil) {
		if ([selectedEnterpriseSource.name isEqualToString:@""]) {
			NSAlert *alert = [[NSAlert alloc] init];
			[alert addButtonWithTitle:NSLocalizedString(@"Okay", nil)];
			[alert setMessageText:NSLocalizedString(@"No Enterprise source file selected.", nil)];
			[alert setInformativeText:NSLocalizedString(@"You need to select the source of the Enterprise binaries that will be copied to this USB drive.", nil)];
			[alert setAlertStyle:NSWarningAlertStyle];
			[alert beginSheetModalForWindow:self.windowForSheet modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
			return;
		}
	}

	// Get an NSFileManager object.
	NSFileManager *manager = [NSFileManager defaultManager];

	// Get the names of files.
	NSString *targetUSBName = selectedUSBDrive.name;
	NSString *targetUSBMountPoint = [@"/Volumes/" stringByAppendingString : targetUSBName];
	NSString *installDirectory = [targetUSBMountPoint stringByAppendingString:@"/efi/boot/"];

	//NSString *enterpriseInstallFileName = [installDirectory stringByAppendingString:@"bootX64.efi"];

	// Set the size of the file to be the max value of the progress bar.
	[self.installationProgressBar setMaxValue:[[manager sizeOfFileAtPath:self.fileURL.path] doubleValue]];

	// Disable UI components.
	[sender setEnabled:NO];
	[self.installationProgressBar setIndeterminate:NO];
	[self.installationProgressBar setDoubleValue:0.0];
	[self.automaticSetupCheckBox setEnabled:NO];

	/* STEP 2: Get user permission to install files. We'll only need to do this once. */
	NSURL *outURL = [manager setupSecurityScopedBookmarkForUSBAtPath:targetUSBMountPoint withWindowForSheet:[self windowForSheet]];

	if (!outURL) {
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:NSLocalizedString(@"Okay", nil)];
		[alert setMessageText:NSLocalizedString(@"Couldn't get security scoped bookmarks.", nil)];
		[alert setInformativeText:NSLocalizedString(@"The USB device that you have selected cannot be accessed because the system denied access to the resource.", nil)];
		[alert setAlertStyle:NSWarningAlertStyle];
		[alert beginSheetModalForWindow:self.windowForSheet modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];

		// Restore access to the disabled buttons.
		[sender setEnabled:YES];
		[self.installationProgressBar setDoubleValue:0.0];
		[self.automaticSetupCheckBox setEnabled:YES];

		// Bail.
		return;
	} else {
		NSLog(@"Obtained security scoped bookmark for USB %@.", targetUSBName);
	}

	/* STEP 3: Start copying files. */
	[outURL startAccessingSecurityScopedResource];

	// Disable GUI elements.
	[self.usbDriveSelector setHidden:YES];
	[self.enterpriseSourceSelector setEnabled:NO];

	// Create the required directories on the USB drive.
	NSError *error;
	BOOL result = [manager createDirectoryAtPath:installDirectory withIntermediateDirectories:YES attributes:nil error:&error];
	if (!result || error) {
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:NSLocalizedString(@"Okay", nil)];
		[alert setMessageText:[error localizedDescription]];
		[alert setInformativeText:[error localizedFailureReason]];
		[alert setAlertStyle:NSWarningAlertStyle];
		[alert beginSheetModalForWindow:self.windowForSheet modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];

		// Restore access to the disabled buttons.
		[sender setEnabled:YES];
		[self.installationProgressBar setDoubleValue:0.0];
		[self.automaticSetupCheckBox setEnabled:YES];

		// Enable GUI elements.
		[self.usbDriveSelector setHidden:NO];
		[self.enterpriseSourceSelector setEnabled:YES];

		// Bail.
		return;
	}

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
	    [selectedUSBDrive copyInstallationFiles:self toUSBDrive:selectedUSBDrive];

	    dispatch_async(dispatch_get_main_queue(), ^{
	        /* STEP 4: Restore access to the disabled buttons. */
	        [sender setEnabled:YES];
	        [self.installationProgressBar setDoubleValue:0.0];
	        [self.installationProgressBar setHidden:YES];
	        [self.automaticSetupCheckBox setEnabled:YES];

	        // Enable GUI elements.
	        [self.usbDriveSelector setHidden:NO];
	        [self.enterpriseSourceSelector setEnabled:YES];

	        [outURL stopAccessingSecurityScopedResource];
		});
	});
}

- (IBAction)refreshUSBListing:(id)sender {
	[self.usbArrayForContentView removeAllObjects];

	[[NSApp delegate] detectAndSetupUSBs];
	[self setupUSBDriveSelector];
}

#pragma mark - Delegates
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	// Empty
}

@end
