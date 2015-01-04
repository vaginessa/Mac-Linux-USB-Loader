//
//  SBEnterpriseConfigurationWriter.m
//  Mac Linux USB Loader
//
//  Created by SevenBits on 10/24/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import "SBEnterpriseConfigurationWriter.h"
#import "SBAppDelegate.h"

@implementation SBEnterpriseConfigurationWriter

+ (void)writeConfigurationFileAtUSB:(SBUSBDevice *)device distributionFamily:(SBLinuxDistribution)family isMacUbuntu:(BOOL)isMacUbuntu containsLegacyUbuntuVersion:(BOOL)containsLegacyUbuntu {
	NSError *error;

	NSString *path = [device.path stringByAppendingPathComponent:@"/efi/boot/.MLUL-Live-USB"];
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
}

@end