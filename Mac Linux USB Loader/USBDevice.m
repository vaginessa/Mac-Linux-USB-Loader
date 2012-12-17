//
//  USBDevice.m
//  Mac Linux USB Loader
//
//  Created by SevenBits on 11/26/12.
//  Copyright (c) 2012 SevenBits. All rights reserved.
//

#import "USBDevice.h"

@implementation USBDevice

NSString *volumePath;
NSWindow *window;

- (void)setWindow:(NSWindow *) win {
    window = win;
}

- (BOOL)prepareUSB:(NSString *)path {
    NSString *bootLoaderPath = [[NSBundle mainBundle] pathForResource:@"bootX64" ofType:@"efi" inDirectory:@""];
    NSString *finalPath = [NSString stringWithFormat:@"%@/efi/boot/bootX64.efi", path];
    NSString *tempPath = [NSString stringWithFormat:@"%@/efi/boot", path];
    
    // Check if the EFI bootloader already exists.
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:finalPath];
    
    if (fileExists == YES) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"Abort"];
        [alert setMessageText:@"Failed to create bootable USB."];
        [alert setInformativeText:@"There is already EFI firmware on this device. If it is from a previous run of Mac Linux USB Loader, you must delete the EFI folder on the USB drive and then run this tool."];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
        return NO;
    }
    
    [[NSFileManager new] createDirectoryAtPath:tempPath withIntermediateDirectories:YES attributes:nil error:nil];
    
    // Copy the EFI bootloader.
    if ([[NSFileManager new] copyItemAtPath:bootLoaderPath toPath:finalPath error:nil] == NO) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"Abort"];
        [alert setMessageText:@"Failed to create bootable USB."];
        [alert setInformativeText:@"Could not copy the EFI bootloader to the USB device."];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
        return NO;
    }
    else {
        return YES;
    }
}


- (BOOL)copyISO:(NSString *)path:(NSString *)isoFile {
    NSString *finalPath = [NSString stringWithFormat:@"%@/efi/boot/boot.iso", path];
    
    // Check if the Linux distro ISO already exists.
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:finalPath];
    
    if (fileExists == YES) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"Abort"];
        [alert setMessageText:@"Failed to create bootable USB."];
        [alert setInformativeText:@"There is already a Linux distro ISO on this device. If it is from a previous run of Mac Linux USB Loader, you must delete the EFI folder on the USB drive and then run this tool."];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
        return NO;
    }
    
    NSLog(@"Writing from %@.", isoFile);
    
    NSString *iconPath = [[NSBundle mainBundle] pathForResource:@"bootup" ofType:@"icns" inDirectory:@""];
    NSString *finalIconPath = [NSString stringWithFormat:@"%@/._.VolumeIcon.icns", path];
    if ([[NSFileManager new] copyItemAtPath:[[NSURL URLWithString:iconPath] path] toPath:finalIconPath error:nil] == NO) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"Abort"];
        [alert setMessageText:@"Failed to create bootable USB."];
        [alert setInformativeText:@"Could not copy the Linux ISO to the USB device."];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
        return NO;
    }
    
    // Copy the Linux distro ISO.
    if ([[NSFileManager new] copyItemAtPath:[[NSURL URLWithString:isoFile] path] toPath:finalPath error:nil] == NO) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"Abort"];
        [alert setMessageText:@"Failed to create bootable USB."];
        [alert setInformativeText:@"Could not copy the Linux ISO to the USB device."];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
        return NO;
    }
    else {
        NSProcessInfo *pinfo = [NSProcessInfo processInfo];
        NSArray *myarr = [[pinfo operatingSystemVersionString] componentsSeparatedByString:@" "];
        NSString *version = [@"Mac OS X " stringByAppendingString:[myarr objectAtIndex:1]];
        
        if ([version rangeOfString:@"Mac OS X 10.8"].location != NSNotFound) {
            NSUserNotification *notification = [[NSUserNotification alloc] init];
            notification.title = @"Finished Making Live USB";
            notification.informativeText = @"The live USB has been made successfully.";
            notification.soundName = NSUserNotificationDefaultSoundName;
            
            [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
        }
        
        return YES;
    }
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    // Empty because under normal processing we need not do anything here.
}

@end