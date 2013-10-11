//
//  USBDevice.m
//  Mac Linux USB Loader
//
//  Created by SevenBits on 11/26/12.
//  Copyright (c) 2012 SevenBits. All rights reserved.
//

#import "USBDevice.h"

@implementation USBDevice

- (BOOL)prepareUSB:(NSString *)path {
    // Construct our strings that we need.
    NSString *bootLoaderPath = [[NSBundle mainBundle] pathForResource:@"bootX64" ofType:@"efi" inDirectory:@""];
    NSString *finalPath = [path stringByAppendingPathComponent:@"/efi/boot/bootX64.efi"];
    NSString *tempPath = [path stringByAppendingPathComponent:@"/efi/boot"];
    
    // Check if the EFI bootloader already exists.
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:finalPath];
    
    // Should be relatively self-explanatory. If there's already an EFI executable, show an error message.
    if (fileExists == YES) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"Abort"];
        [alert setMessageText:@"Failed to create bootable USB."];
        [alert setInformativeText:@"There is already EFI firmware on this device. If it is from a previous run of Mac Linux USB Loader, you must delete the EFI folder on the USB drive and then run this tool."];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert beginSheetModalForWindow:_window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
        return NO;
        
        [[NSApp delegate] setCanQuit:YES];
    }
    
    // Make the folder to hold the EFI executable and ISO to boot.
    [[NSFileManager new] createDirectoryAtPath:tempPath withIntermediateDirectories:YES attributes:nil error:nil];
    
    // Copy the EFI bootloader.
    if ([[NSFileManager new] copyItemAtPath:bootLoaderPath toPath:finalPath error:nil] == NO) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"Abort"];
        [alert setMessageText:@"Failed to create bootable USB."];
        [alert setInformativeText:@"Could not copy the EFI bootloader to the USB device."];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert beginSheetModalForWindow:_window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
        return NO;
    }
    else {
        return YES;
    }
}

- (void)markUsbAsLive:(NSString*)path {
    NSLog(@"Marking this USB as a live USB...");
    NSMutableDictionary *infoDictionary = [NSMutableDictionary new];
    
    // Add various items to the dictionary, like the chosen Linux distribution, etc.
    [infoDictionary setObject:NSUserName() forKey:@"Creator User Name"];
    [infoDictionary setObject:@"Ubuntu or Derivatives" forKey:@"Distribution Name"];
    [infoDictionary setObject:@"Unknown" forKey:@"Distribution Version"];
    [infoDictionary setObject:@"" forKey:@"Necessary Boot Options"];
    
    // Write the dictionary to the file as an XML file.
    // Enterprise will use this file to set up boot options.
    NSString *filePath = [path stringByAppendingPathComponent:@"/efi/boot/.MLUL-Live-USB"];
    [infoDictionary writeToFile:filePath atomically:NO];
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    // Empty because under normal processing we need not do anything here.
}

@end
