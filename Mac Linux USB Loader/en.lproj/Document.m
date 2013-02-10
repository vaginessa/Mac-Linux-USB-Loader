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
#import "RHNotificationViewController.h"

@implementation Document

@synthesize usbDriveDropdown;
@synthesize window;
@synthesize makeUSBButton;
@synthesize eraseUSBButton;
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
        // No initilization needed here.
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
        [eraseUSBButton setEnabled:NO];
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
            if ([volumeType isEqualToString:@"msdos"] && isWritable && [volumePath rangeOfString:@"/Volumes/"].location != NSNotFound) {
                // We have a valid mounted media - not necessarily a USB though.
                NSString * title = [NSString stringWithFormat:@"Install to: Drive %@ of type %@", volumePath, volumeType];
                usbs[title] = volumePath; // Add the path of the usb to a dictionary so later we can tell what USB
                                          // they are refering to when they select one from a drop down.
                [usbDriveDropdown addItemWithTitle:title]; // Add to the dropdown list.
            }
        }
    }
    
    // NSLog(@"There are %li items.", [usbDriveDropdown numberOfItems]);
    
    /*
     Basically, this makes sure that you can't make the live USB if you don't have a file open (shouldn't happen, but a
     precaution), or if there are no mounted volumes we can use. If we have a mounted volume, though, and we have an ISO,
     then they can make the live USB.
     */
    if (isoFilePath != nil && [usbDriveDropdown numberOfItems] != 1) {
        [makeUSBButton setEnabled:YES];
        [eraseUSBButton setEnabled:YES];
    }
    else if ([usbDriveDropdown numberOfItems] == 0) { // There are no detected USB ports, at least those formatted as FAT.
        [makeUSBButton setEnabled:NO];
        [eraseUSBButton setEnabled:NO];
    }
    // Exit
}

- (IBAction)updateDeviceList:(id)sender {
    [self getUSBDeviceList];
}

- (IBAction)makeLiveUSB:(id)sender {
    __block BOOL failure = false;
    isoFilePath = [[self fileURL] absoluteString];
    
    // If no USBs available, or if no ISO open, display an error and return.
    if ([usbDriveDropdown numberOfItems] == 0 || isoFilePath == nil) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"Okay"];
        [alert setMessageText:@"No USB devices detected."];
        [alert setInformativeText:@"There are no detected USB devices."];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(regularAlertDidEnd:returnCode:contextInfo:) contextInfo:nil];
        
        [makeUSBButton setEnabled:NO];
        [eraseUSBButton setEnabled:NO];
        
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
    
    // Use Grand Central Dispatch (GCD) to copy the files in another thread. Otherwise, the OS may mark our app as
    // unresponsive, when it's actually in the middle of a large copy operation.
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
        } else {
            // Some form of setup failed. Alert the user.
            failure = YES;
        }
    }); // End of GCD block
    
    // We have to do this because NSAlerts cannot be shown in a GCD block as NSAlert is not thread safe.
    if (failure) {
        [spinner setIndeterminate:NO];
        [spinner setDoubleValue:0.0];
        [spinner stopAnimation:self];
        
        [indeterminate stopAnimation:self];
        [spinner stopAnimation:self];
        
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"No"];
        [alert addButtonWithTitle:@"Yes"];
        [alert setMessageText:@"Failed to create bootable USB."];
        [alert setInformativeText:@"Do you erase the incomplete EFI boot?"];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(eraseAlertDidEnd:returnCode:contextInfo:) contextInfo:nil]; // Offer to erase the EFI boot since we never completed.
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
    [alert addButtonWithTitle:@"Yes"];
    [alert addButtonWithTitle:@"No"];
    [alert setMessageText:@"Are you sure that you want to erase the live boot?"];
    [alert setInformativeText:@"This will recover space by erasing everything in the EFI folder on the USB drive, but is unrecoverable."];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(eraseAlertDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)regularAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    // Do nothing.
}

- (void)eraseAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertFirstButtonReturn) {
        // NSLog(@"Will erase!");
        if ([usbDriveDropdown numberOfItems] != 0) {
            // Construct the path of the efi folder that we're going to nuke.
            NSString *directoryName = [usbDriveDropdown titleOfSelectedItem];
            NSString *usbRoot = [usbs valueForKey:directoryName];
            NSString *tempPath = [NSString stringWithFormat:@"%@/efi", usbRoot];
            
            // Need these to recursively delete the folder, because UNIX can't erase a folder without erasing its
            // contents first, apparently.
            NSFileManager* fm = [[NSFileManager alloc] init];
            NSDirectoryEnumerator* en = [fm enumeratorAtPath:tempPath];
            NSError *err = nil;
            BOOL res;
            
            // Recursively erase the efi folder.
            NSString *file;
            while (file = [en nextObject]) { // While there are files to remove...
                res = [fm removeItemAtPath:[tempPath stringByAppendingPathComponent:file] error:&err]; // Delete.
                if (!res && err) { // If there was an error...
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
