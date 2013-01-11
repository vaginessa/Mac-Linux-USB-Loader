//
//  Document.m
//  Mac Linux USB Loader
//
//  Created by SevenBits on 11/26/12.
//  Copyright (c) 2012 SevenBits. All rights reserved.
//

#import "Document.h"
#import "USBDevice.h"

#import "RHPreferences/RHPreferences.h"
#import "RHPreferences/RHPreferencesWindowController.h"

#import "RHAppDelegate.h"
#import "RHAboutViewController.h"
#import "RHAccountsViewController.h"
#import "RHWideViewController.h"

@implementation Document

@synthesize usbDriveDropdown;
@synthesize window;
@synthesize makeUSBButton;
@synthesize indeterminate;
@synthesize spinner;
@synthesize prefsWindow;
@synthesize preferencesWindowController=_preferencesWindowController;

NSMutableDictionary *usbs;
NSString *isoFilePath;
USBDevice *device;

- (id)init
{
    self = [super init];
    if (self) {
        // EMPTY
    }
    return self;
}

- (NSString *)windowNibName
{
    return @"Document";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)controller
{
    [super windowControllerDidLoadNib:controller];
    usbs = [[NSMutableDictionary alloc]initWithCapacity:10]; //A maximum capacity of 10 is fine, nobody has that many ports anyway
    device = [USBDevice new];
    [device setWindow:window];
    
    isoFilePath = [[self fileURL] absoluteString];
    
    if (isoFilePath == nil) {
        [makeUSBButton setEnabled:NO];
    }
    
    [self getUSBDeviceList];
}

- (void)getUSBDeviceList
{
    // Fetch the NSArray of strings of mounted media from the shared workspace
    NSArray *volumes = [[NSWorkspace sharedWorkspace] mountedRemovableMedia];
    
    // Setup target variables for the data to be put into
    BOOL isRemovable, isWritable, isUnmountable;
    NSString *description, *volumeType;
    
    [usbDriveDropdown removeAllItems]; // Clear the dropdown list.
    [usbs removeAllObjects];           // Clear the dictionary of the list of USB drives.
    
    // Iterate through the array using fast enumeration
    for (NSString *volumePath in volumes) {
        // Get filesystem info about each of the mounted volumes
        if ([[NSWorkspace sharedWorkspace] getFileSystemInfoForPath:volumePath isRemovable:&isRemovable isWritable:&isWritable isUnmountable:&isUnmountable description:&description type:&volumeType]) {
            if ([volumeType isEqualToString:@"msdos"]) {
                NSString * title = [NSString stringWithFormat:@"Drive type %@ at %@", volumeType, volumePath];
                usbs[title] = volumePath; // Add the path of the usb to a dictionary so later we can tell what USB
                                          // they are refering to when they select one from a drop down.
                [usbDriveDropdown addItemWithTitle:title];
            }
        }
    }
    
    // NSLog(@"There are %li items.", [usbDriveDropdown numberOfItems]);
    
    if (isoFilePath != nil && [usbDriveDropdown numberOfItems] != 1) {
        [makeUSBButton setEnabled:YES];
    }
    else if ([usbDriveDropdown numberOfItems] == 0) { // There are no detected USB ports, at least those formatted as FAT.
        [makeUSBButton setEnabled:NO];
    }
    // Exit
}

- (IBAction)updateDeviceList:(id)sender {
    [self getUSBDeviceList];
}

- (IBAction)makeLiveUSB:(id)sender {
    __block BOOL failure = false;
    isoFilePath = [[self fileURL] absoluteString];
    
    if ([usbDriveDropdown numberOfItems] == 0 || isoFilePath == nil) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"Okay"];
        [alert setMessageText:@"No USB devices detected."];
        [alert setInformativeText:@"There are no detected USB devices."];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(regularAlertDidEnd:returnCode:contextInfo:) contextInfo:nil];
        
        [makeUSBButton setEnabled:NO];
        
        return;
    }
    
    NSString* directoryName = [usbDriveDropdown titleOfSelectedItem];
    NSString* usbRoot = [usbs valueForKey:directoryName];
    
    [indeterminate setUsesThreadedAnimation:YES];
    [indeterminate startAnimation:self];
    
    [spinner setUsesThreadedAnimation:YES];
    [spinner setIndeterminate:YES];
    [spinner setDoubleValue:0.0];
    [spinner startAnimation:self];
    
    // Use Grand Central Dispatch (GCD) to copy the files in another thread.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if ([device prepareUSB:usbRoot] == YES) {
            [spinner setIndeterminate:NO];
            [spinner setDoubleValue:50.0];
            
            if ([device copyISO:usbRoot:isoFilePath] != YES) {
                failure = YES;
            }
            
            [spinner setDoubleValue:100.0];
            [spinner stopAnimation:self];
            
            [indeterminate stopAnimation:self];
            [spinner stopAnimation:self];
        }
        else {
            // Some form of setup failed. Alert the user.
            failure = YES;
        }
    }); // End of GCD block
    
    if (failure) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"Yes"];
        [alert addButtonWithTitle:@"No"];
        [alert setMessageText:@"Failed to create bootable USB."];
        [alert setInformativeText:@"Do you erase the incomplete EFI boot?"];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(copyAlertDidEnd:returnCode:contextInfo:) contextInfo:nil];
    }
}

- (IBAction)openGithubPage:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/SevenBits/Mac-Linux-USB-Loader"]];
}

- (IBAction)reportBug:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/SevenBits/Mac-Linux-USB-Loader/issues/new"]];
}

+ (BOOL)autosavesInPlace
{
    return NO;
}

+ (BOOL)isEntireFileLoaded {
    return YES;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    // If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
    return YES;
}

- (IBAction)openDiskUtility:(id)sender {
    [[NSWorkspace sharedWorkspace] launchApplication:@"/Applications/Utilities/Disk Utility.app"];
}

- (IBAction)eraseLiveBoot:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"No"];
    [alert addButtonWithTitle:@"Yes"];
    [alert setMessageText:@"Are you sure that you want to erase the live boot?"];
    [alert setInformativeText:@"This will recover space, but is unrecoverable."];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(eraseAlertDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

-(IBAction)showPreferences:(id)sender{
    //if we have not created the window controller yet, create it now
    if (!_preferencesWindowController) {
        RHAccountsViewController *accounts = [[RHAccountsViewController alloc] init];
        RHAboutViewController *about = [[RHAboutViewController alloc] init];
        RHWideViewController *wide = [[RHWideViewController alloc] init];
        
        NSArray *controllers = [NSArray arrayWithObjects:accounts, wide,
                                [RHPreferencesWindowController flexibleSpacePlaceholderController], about, nil];
        
        _preferencesWindowController = [[RHPreferencesWindowController alloc] initWithViewControllers:controllers andTitle:NSLocalizedString(@"Preferences", @"Preferences Window Title")];
    }
    
    [_preferencesWindowController showWindow:self];
}

- (void)copyAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertFirstButtonReturn) {
        NSLog(@"Will erase USB device.");
    }
}

- (void)regularAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    // Do nothing.
}

- (void)eraseAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    if (returnCode != NSAlertFirstButtonReturn) {
        // NSLog(@"Will erase!");
        if ([usbDriveDropdown numberOfItems] != 0) {
            NSString *directoryName = [usbDriveDropdown titleOfSelectedItem];
            NSString *usbRoot = [usbs valueForKey:directoryName];
            NSString *tempPath = [NSString stringWithFormat:@"%@/efi", usbRoot];
            
            NSFileManager* fm = [[NSFileManager alloc] init];
            NSDirectoryEnumerator* en = [fm enumeratorAtPath:tempPath];
            NSError *err = nil;
            BOOL res;
            
            NSString *file;
            while (file = [en nextObject]) {
                res = [fm removeItemAtPath:[tempPath stringByAppendingPathComponent:file] error:&err];
                if (!res && err) {
                    NSString *text = [NSString stringWithFormat:@"Error: %@", err];
                    NSAlert *alert = [[NSAlert alloc] init];
                    [alert addButtonWithTitle:@"Okay"];
                    [alert setMessageText:@"Failed to erase live USB."];
                    [alert setInformativeText:text];
                    [alert setAlertStyle:NSWarningAlertStyle];
                    [alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(regularAlertDidEnd:returnCode:contextInfo:) contextInfo:nil];
                    NSLog(@"Could not delete: %@", err);
                }
            }
        }
    }
}

@end
