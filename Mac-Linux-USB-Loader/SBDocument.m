//
//  SBDocument.m
//  Mac-Linux-USB-Loader
//
//  Created by SevenBits on 1/13/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import "SBDocument.h"
#import "SBAppDelegate.h"
#import "SBEnterpriseConfigurationWriter.h"
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
	[[(SBAppDelegate *)[NSApp delegate] window] orderOut:nil];

	[self setupUSBDriveSelector];
	[self detectDistributionFamily];
	[self distributionTypePopupChanged:self.distributionSelectorPopup];

	[self.enterpriseSourceSelector selectItemWithTitle:[[NSUserDefaults standardUserDefaults] stringForKey:@"DefaultEnterpriseSourceLocation"]];

	[self.performInstallationButton setEnabled:NO];
}

- (void)detectDistributionFamily {
	SBLinuxDistribution family = [SBUSBDevice distributionTypeForISOName:self.fileURL.absoluteString];
	switch (family) {
		case SBDistributionUbuntu:
			[self.distributionSelectorPopup selectItemWithTitle:@"Ubuntu"];
			break;
		case SBDistributionDebian:
		case SBDistributionTails:
			[self.distributionSelectorPopup selectItemWithTitle:@"Debian"];
			break;
		case SBDistributionUnknown:
		default:
			[self.distributionSelectorPopup selectItemWithTitle:@"Other"];
			break;
	}

	if ([[[self.fileURL path] lastPathComponent] containsString:@"+mac"]) {
		[self.isMacVersionCheckBox setState:NSOnState];
	} else {
		[self.isMacVersionCheckBox setState:NSOffState];
	}
}

- (void)setupUSBDriveSelector {
	// Grab the list of USB devices from the App Delegate and setup the USB selector.
	usbDictionary = [NSMutableDictionary dictionaryWithDictionary:[(SBAppDelegate *)[NSApp delegate] usbDictionary]];
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
	enterpriseSourcesDictionary = [NSMutableDictionary dictionaryWithDictionary:[(SBAppDelegate *)[NSApp delegate] enterpriseInstallLocations]];
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
	NSString *selectedEnterpriseSourceName = [self.enterpriseSourceSelector titleOfSelectedItem];
	SBEnterpriseSourceLocation *sourceLocation = [(SBAppDelegate *)[NSApp delegate] enterpriseInstallLocations][selectedEnterpriseSourceName];

	if (selectedEnterpriseSourceIndex == -1 || sourceLocation == nil) {
		if ([sourceLocation.name isEqualToString:@""]) {
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
	NSString *enterprisePath = [sourceLocation.path stringByAppendingPathComponent:@"bootx64.efi"];
	NSString *grubPath = [sourceLocation.path stringByAppendingPathComponent:@"boot.efi"];
	if (![manager fileExistsAtPath:enterprisePath isDirectory:NULL] || ![manager fileExistsAtPath:grubPath isDirectory:NULL]) {
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:NSLocalizedString(@"Okay", nil)];
		[alert setMessageText:NSLocalizedString(@"Can't install to this USB device.", nil)];
		[alert setInformativeText:NSLocalizedString(@"The installation failed because the Enterprise source that you have selected is either incomplete or missing.", nil)];
		[alert setAlertStyle:NSWarningAlertStyle];
		[alert beginSheetModalForWindow:self.windowForSheet modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];

		// Restore access to the disabled buttons.
		[sender setEnabled:YES];
		[self.installationProgressBar setDoubleValue:0.0];
		[self.automaticSetupCheckBox setEnabled:YES];

		// Bail.
		return;
	}

	double fileSize = [[manager sizeOfFileAtPath:self.fileURL.path] doubleValue] + [[manager sizeOfFileAtPath:grubPath] doubleValue] + [[manager sizeOfFileAtPath:enterprisePath] doubleValue];
	[self.installationProgressBar setMaxValue:fileSize];

	// Disable UI components.
	[sender setEnabled:NO];
	[self.installationProgressBar setIndeterminate:NO];
	[self.installationProgressBar setDoubleValue:0.0];
	[self.automaticSetupCheckBox setEnabled:NO];
	[self.distributionSelectorPopup setEnabled:NO];
	[self.isMacVersionCheckBox setEnabled:NO];
	[self.isLegacyUbuntuVersionCheckBox setEnabled:NO];

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
		[self.distributionSelectorPopup setEnabled:YES];
		[self.isMacVersionCheckBox setEnabled:YES];
		[self.isLegacyUbuntuVersionCheckBox setEnabled:YES];

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

	SBLinuxDistribution distribution = [SBAppDelegate distributionEnumForEqualivalentName:[self.distributionSelectorPopup titleOfSelectedItem]];
	[SBEnterpriseConfigurationWriter writeConfigurationFileAtUSB:selectedUSBDrive distributionFamily:distribution isMacUbuntu:[self.isMacVersionCheckBox state] == NSOnState containsLegacyUbuntuVersion:[self.isLegacyUbuntuVersionCheckBox state] == NSOnState];

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
		[self.distributionSelectorPopup setEnabled:YES];
		[self.isMacVersionCheckBox setEnabled:YES];
		[self.isLegacyUbuntuVersionCheckBox setEnabled:YES];

		// Bail.
		return;
	}

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		SBEnterpriseSourceLocation *sourceLocation = [(SBAppDelegate *)[NSApp delegate] enterpriseInstallLocations][selectedEnterpriseSourceName];
		[selectedUSBDrive copyEnterpriseFiles:self withEnterpriseSource:sourceLocation];
	    [selectedUSBDrive copyInstallationFiles:self];

	    dispatch_async(dispatch_get_main_queue(), ^{
	        /* STEP 4: Restore access to the disabled buttons. */
	        [sender setEnabled:YES];
	        [self.installationProgressBar setDoubleValue:0.0];
	        [self.installationProgressBar setHidden:YES];
	        [self.automaticSetupCheckBox setEnabled:YES];

	        // Enable GUI elements.
	        [self.usbDriveSelector setHidden:NO];
	        [self.enterpriseSourceSelector setEnabled:YES];
			[self.distributionSelectorPopup setEnabled:YES];
			[self.isMacVersionCheckBox setEnabled:YES];
			[self.isLegacyUbuntuVersionCheckBox setEnabled:YES];

			// Stop accessing the security bookmark.
	        [outURL stopAccessingSecurityScopedResource];

			// Tell the user.
			NSAlert *alert = [[NSAlert alloc] init];
			[alert addButtonWithTitle:NSLocalizedString(@"Okay", nil)];
			[alert setMessageText:NSLocalizedString(@"Finished Making Live USB.", nil)];
			[alert setInformativeText:NSLocalizedString(@"The operation completed successfully.", nil)];
			[alert setAlertStyle:NSWarningAlertStyle];
			[alert beginSheetModalForWindow:self.windowForSheet modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];

			
			NSUserNotification *userNotification = [[NSUserNotification alloc] init]; \
			userNotification.title = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Finished Installing: ", nil), [[self.fileURL.path lastPathComponent] stringByDeletingPathExtension]];
			userNotification.informativeText = NSLocalizedString(@"You are now ready to use your USB drive!", nil);
			[[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:userNotification];
		});
	});
}

- (IBAction)refreshUSBListing:(id)sender {
	// Refresh the list of USBs.
	[self.usbArrayForContentView removeAllObjects];

	[(SBAppDelegate *)[NSApp delegate] detectAndSetupUSBs];
	[self setupUSBDriveSelector];

	// Refresh the list of Enterprise sources.
	NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:3];
	enterpriseSourcesDictionary = [NSMutableDictionary dictionaryWithDictionary:[(SBAppDelegate *)[NSApp delegate] enterpriseInstallLocations]];
	for (NSString *usb in enterpriseSourcesDictionary) {
		[array insertObject:[enterpriseSourcesDictionary[usb] name] atIndex:0];
	}

	[self.enterpriseSourceSelector removeAllItems];
	[self.enterpriseSourceSelector addItemsWithTitles:array];
}

#pragma mark - Delegates
- (IBAction)distributionTypePopupChanged:(id)sender {
	NSString *selectedItem = [(NSPopUpButton *)sender titleOfSelectedItem];
	BOOL isUbuntuSelected = [selectedItem isEqualToString:@"Ubuntu"];
	[self.isMacVersionCheckBox setTransparent:(isUbuntuSelected ? NO : YES)];
	[self.isMacVersionCheckBox setEnabled:isUbuntuSelected];
	[self.isLegacyUbuntuVersionCheckBox setTransparent:(isUbuntuSelected ? NO : YES)];
	[self.isLegacyUbuntuVersionCheckBox setEnabled:isUbuntuSelected];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	// Empty
}

@end
