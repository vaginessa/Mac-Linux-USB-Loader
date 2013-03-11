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
    progressIndicator = spinner;
    
    [super windowControllerDidLoadNib:controller];
    usbs = [[NSMutableDictionary alloc]initWithCapacity:10]; //A maximum capacity of 10 is fine, nobody has that many ports anyway.
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
    // Fetch the NSArray of strings of mounted media from the shared workspace.
    NSArray *volumes = [[NSWorkspace sharedWorkspace] mountedRemovableMedia];
    
    // Setup target variables for the data to be put into.
    BOOL isRemovable, isWritable, isUnmountable;
    NSString *description, *volumeType;
    
    [usbDriveDropdown removeAllItems]; // Clear the dropdown list.
    [usbs removeAllObjects];           // Clear the dictionary of the list of USB drives.
    
    // Iterate through the array using fast enumeration.
    for (NSString *volumePath in volumes) {
        // Get filesystem info about each of the mounted volumes.
        if ([[NSWorkspace sharedWorkspace] getFileSystemInfoForPath:volumePath isRemovable:&isRemovable isWritable:&isWritable isUnmountable:&isUnmountable description:&description type:&volumeType]) {
            if ([volumeType isEqualToString:@"msdos"] && isWritable && [volumePath rangeOfString:@"/Volumes/"].location != NSNotFound) {
                // We have a valid mounted media - not necessarily a USB though.
                NSString * title = [NSString stringWithFormat:@"Install to: Drive at %@ of type %@", volumePath, volumeType];
                
#if (MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_8)
                usbs[title] = volumePath; // Add the path of the usb to a dictionary so later we can tell what USB
                                          // they are refering to when they select one from a drop down.
#elif
                [usbs setObject:volumePath forKey:title];
#endif
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
    // Exit.
}

- (IBAction)updateDeviceList:(id)sender {
    [self getUSBDeviceList];
}

- (IBAction)makeLiveUSB:(id)sender {
    [[NSApp delegate] setCanQuit:NO];
    
    __block BOOL failure = false;
    //isoFilePath = [[self fileURL] absoluteString];
    isoFilePath = [[self fileURL] path];
    
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
        
        [[NSApp delegate] setCanQuit:YES]; // We're done, the user can quit the program.
        
        return;
    }
    
    NSString* directoryName = [usbDriveDropdown titleOfSelectedItem];
    NSString* usbRoot = [usbs valueForKey:directoryName];
    NSString* finalPath = [NSString stringWithFormat:@"%@/efi/boot/", usbRoot];
    
    [indeterminate setUsesThreadedAnimation:YES];
    [indeterminate startAnimation:self];
    
    [spinner setUsesThreadedAnimation:YES];
    [spinner setIndeterminate:YES];
    [spinner setDoubleValue:0.0];
    [spinner startAnimation:self];
    
    // Check if the Linux distro ISO already exists.
    NSString *temp = [NSString stringWithFormat:@"%@/efi/boot/boot.iso", usbRoot];
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:temp];
    
    if (fileExists == YES) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"Abort"];
        [alert setMessageText:@"Failed to create bootable USB."];
        [alert setInformativeText:@"There is already a Linux distro ISO on this device. If it is from a previous run of Mac Linux USB Loader, you must delete the EFI folder on the USB drive and then run this tool."];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(regularAlertDidEnd:returnCode:contextInfo:) contextInfo:nil];
        return;
    }

    // Now progress with the copy.
    [[NSApp delegate] setCanQuit:NO]; // The user can't quit while we're copying.
    if ([device prepareUSB:usbRoot] == YES) {
        [spinner setIndeterminate:NO];
        [spinner setUsesThreadedAnimation:YES];
            
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        // Use the NSFileManager to obtain the size of our source file in bytes.
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSDictionary *sourceAttributes = [fileManager fileAttributesAtPath:[[self fileURL] path] traverseLink:YES];
        NSNumber *sourceFileSize;
            
        if ((sourceFileSize = [sourceAttributes objectForKey:NSFileSize])) {
            // Set the max value to our source file size
            [progressIndicator setMaxValue:(double)[sourceFileSize unsignedLongLongValue]];
        } else {
            // Couldn't get the file size so we need to bail.
            NSLog(@"Unable to obtain size of file being copied.");
            return;
        }
        [spinner setDoubleValue:0.0];
            
        // Get the current run loop and schedule our callback
        CFRunLoopRef runLoop = CFRunLoopGetCurrent();
        FSFileOperationRef fileOp = FSFileOperationCreate(kCFAllocatorDefault);
            
        OSStatus status = FSFileOperationScheduleWithRunLoop(fileOp, runLoop, kCFRunLoopDefaultMode);
        if(status) {
            NSLog(@"Failed to schedule operation with run loop: %d", status);
            return;
        }
             
        // Create a filesystem ref structure for the source and destination and
        // populate them with their respective paths from our NSTextFields.
        FSRef source;
        FSRef destination;
            
        FSPathMakeRef( (const UInt8 *)[[[self fileURL] path] fileSystemRepresentation], &source, NULL );
            
        Boolean isDir = true;
        FSPathMakeRef( (const UInt8 *)[finalPath fileSystemRepresentation], &destination, &isDir );
        
        // Start the async copy.
        status = FSCopyObjectAsync(fileOp,
                                    &source,
                                    &destination, // Full path to destination dir
                                    NULL, // Use the same filename as source
                                    kFSFileOperationDefaultOptions,
                                    copyStatusCallback,
                                    0.5, /* how often to fire our callback */
                                    NULL);
        
        CFRelease(fileOp);
        
        if(status) {
            NSLog(@"Failed to begin asynchronous object copy: %d", status);
        }
        
        #pragma clang diagnostic warning "-Wdeprecated-declarations"
            
        [spinner setDoubleValue:100.0];
        [spinner stopAnimation:self];
        
        [indeterminate stopAnimation:self];
        [spinner stopAnimation:self];
    } else {
        // Some form of setup failed. Alert the user.
        failure = YES;
    }
        
    [[NSApp delegate] setCanQuit:YES]; // We're done, the user can quit the program.
    
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
    } else {
#if (MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_8)
        // Show a notification for Mountain Lion users.
        NSProcessInfo *pinfo = [NSProcessInfo processInfo];
        NSArray *myarr = [[pinfo operatingSystemVersionString] componentsSeparatedByString:@" "];
        NSString *version = [myarr objectAtIndex:1];
        
        // Ensure that we are running 10.8 before we display the notification as we still support Lion, which does not have
        // them.
        if ([version rangeOfString:@"10.8"].location != NSNotFound) {
            NSUserNotification *notification = [[NSUserNotification alloc] init];
            notification.title = @"Finished Making Live USB";
            notification.informativeText = @"The live USB has been made successfully.";
            notification.soundName = NSUserNotificationDefaultSoundName;
            
            [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
        } else {
            [NSApp requestUserAttention:NSCriticalRequest];
        }
#else
        [NSApp requestUserAttention:NSCriticalRequest];
#endif
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
            BOOL eraseDidSucceed;
            
            // Recursively erase the efi folder.
            NSString *file;
            while (file = [en nextObject]) { // While there are files to remove...
                eraseDidSucceed = [fm removeItemAtPath:[tempPath stringByAppendingPathComponent:file] error:&err]; // Delete.
                if (!eraseDidSucceed && err) { // If there was an error...
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

static void copyStatusCallback (FSFileOperationRef fileOp, const FSRef *currentItem, FSFileOperationStage stage, OSStatus error,
                            CFDictionaryRef statusDictionary, void *info) {
    NSLog(@"Callback got called.");
    
    // If the status dictionary is valid, we can grab the current values to display status changes, or in our case to
    // update the progress indicator.
    if (statusDictionary)
    {
        CFNumberRef bytesCompleted;
        
        bytesCompleted = (CFNumberRef) CFDictionaryGetValue(statusDictionary, kFSOperationBytesCompleteKey);
        
        CGFloat floatBytesCompleted;
        CFNumberGetValue (bytesCompleted, kCFNumberMaxType, &floatBytesCompleted);
        
        NSLog(@"Copied %lld bytes so far.", (unsigned long long)floatBytesCompleted);
        
        [progressIndicator setDoubleValue:(double)floatBytesCompleted];
        [progressIndicator displayIfNeeded];
    }
}

