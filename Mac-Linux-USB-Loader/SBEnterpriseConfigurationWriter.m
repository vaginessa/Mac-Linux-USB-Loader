//
//  SBEnterpriseConfigurationWriter.m
//  Mac Linux USB Loader
//
//  Created by SevenBits on 10/24/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import "SBEnterpriseConfigurationWriter.h"
#import "SBAppDelegate.h"
#import <sys/xattr.h>

@implementation SBEnterpriseConfigurationWriter

/// This is a private method.
+ (BOOL)toggleVisibilityForFile:(NSString *)filename isDirectory:(BOOL)isDirectory
{
	// Convert the pathname to HFS+
	FSRef fsRef;
	CFURLRef url = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)filename, kCFURLPOSIXPathStyle, isDirectory);

	if (!url)
	{
		NSLog(@"Error creating CFURL for %@.", filename);
		return NO;
	}

	if (!CFURLGetFSRef(url, &fsRef))
	{
		NSLog(@"Error creating FSRef for %@.", filename);
		CFRelease(url);
		return NO;
	}

	CFRelease(url);

	// Get the file's catalog info
	FSCatalogInfo *catalogInfo = (FSCatalogInfo *)malloc(sizeof(FSCatalogInfo));

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	OSErr err = FSGetCatalogInfo(&fsRef, kFSCatInfoFinderInfo, catalogInfo, NULL, NULL, NULL);
#pragma clang diagnostic pop

	if (err != noErr)
	{
		NSLog(@"Error getting catalog info for %@. The error returned was: %d", filename, err);
		free(catalogInfo);
		return NO;
	}

	// Extract the Finder info from the FSRef's catalog info
	FInfo *info = (FInfo *)(&catalogInfo->finderInfo[0]);

	// Toggle the invisibility flag
	if (info->fdFlags & kIsInvisible)
		info->fdFlags &= ~kIsInvisible;
	else
		info->fdFlags |= kIsInvisible;

	// Update the file's visibility
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	err = FSSetCatalogInfo(&fsRef, kFSCatInfoFinderInfo, catalogInfo);
#pragma clang diagnostic pop

	if (err != noErr)
	{
		NSLog(@"Error setting visibility bit for %@. The error returned was: %d", filename, err);
		free(catalogInfo);
		return NO;
	}

	free(catalogInfo);
	return YES;
}

+ (void)writeConfigurationFileAtUSB:(SBUSBDevice *)device distributionFamily:(SBLinuxDistribution)family isMacUbuntu:(BOOL)isMacUbuntu containsLegacyUbuntuVersion:(BOOL)containsLegacyUbuntu {
	NSError *error;

	NSString *path = [device.path stringByAppendingPathComponent:@"/efi/boot/enterprise.cfg"];
	NSMutableString *string = [NSMutableString stringWithCapacity:30];
	[string appendString:@"#This file is machine generated. Do not modify it unless you know what you are doing.\n\n"];
	[string appendFormat:@"entry %@\n", [SBAppDelegate distributionStringForEquivalentEnum:family]];
	[string appendFormat:@"family %@\n", [SBAppDelegate distributionStringForEquivalentEnum:family]];

	if (family == SBDistributionUbuntu && (isMacUbuntu || containsLegacyUbuntu)) {
		NSMutableString *kernelString = [NSMutableString stringWithString:@"kernel "];

		// I know that this seems a bit redundant, checking for legacy Ubuntu twice, but we have to because if we don't,
		// it would be impossible to have both options be enabled.
		if (isMacUbuntu) {
			[kernelString appendString:@"/casper/vmlinuz "];
			if (containsLegacyUbuntu) {
				[kernelString appendString:@"file=/cdrom/preseed/ubuntu.seed"];
			}
		} else if (containsLegacyUbuntu) {
			[kernelString appendString:@"/casper/vmlinuz.efi file=/cdrom/preseed/ubuntu.seed"];
		}

		[kernelString appendString:@"\n"];
		[string appendString:kernelString];
	}

	if (![[NSFileManager defaultManager] removeItemAtPath:path error:&error]) {
		NSLog(@"Error removing old configuration file: %@", error);
	}

	BOOL success = [string writeToFile:path atomically:NO encoding:NSASCIIStringEncoding error:&error];
	if (!success) {
		NSLog(@"Error writing configuration file: %@", error);
	}

	// Hide the configuration file if the user has indicated that they desire this behavior.
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([defaults boolForKey:@"HideConfigurationFile"]) {
		BOOL result = [self toggleVisibilityForFile:path isDirectory:NO];
		if (result != 0) {
			NSLog(@"Failed to hide configuration file.");
		}
	}
}

@end