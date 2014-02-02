//
//  NSFileManager+Extensions.m
//  Mac Linux USB Loader
//
//  Created by Ryan Bowring on 2/1/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import "NSFileManager+Extensions.h"

@implementation NSFileManager (Extensions)

NSOpenPanel *spanel;

- (NSNumber *)sizeOfFileAtPath:(NSString *)path {
	NSNumber *mySize = [NSNumber numberWithUnsignedLongLong:[[self attributesOfItemAtPath:path error:nil] fileSize]];
	return mySize;
}

- (NSURL *)setupSecurityScopedBookmarkForUSBAtPath:(NSString *)path withWindowForSheet:(NSWindow *)window {
	//NSURL *fileURL = [self fileURL];
	NSString *targetUSBName = [[path lastPathComponent] stringByDeletingPathExtension];
	NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
	NSURL *outURL;
	if ([prefs objectForKey:[targetUSBName stringByAppendingString:@"_USBSecurityBookmarkTarget"]]) {
		outURL = [NSURL URLByResolvingBookmarkData:[[NSUserDefaults standardUserDefaults]
													objectForKey:[targetUSBName stringByAppendingString:@"_USBSecurityBookmarkTarget"]]
										   options:NSURLBookmarkResolutionWithSecurityScope
									 relativeToURL:nil
							   bookmarkDataIsStale:nil
											 error:nil];
	} else {
		NSLog(@"Don't have access to USB %@, showing file dialog.", targetUSBName);

		spanel = [NSOpenPanel openPanel];
		[spanel setMessage:NSLocalizedString(@"Click Open below to authorize access of the USB drive.", nil)];
		[spanel setDirectoryURL:[NSURL URLWithString:
								 [@"/Volumes/" stringByAppendingString:targetUSBName]]];
		[spanel setNameFieldStringValue:@""];
		[spanel setCanChooseDirectories:YES];
		[spanel setCanSelectHiddenExtension:NO];
		[spanel setTreatsFilePackagesAsDirectories:NO];
		[spanel beginSheetModalForWindow:window completionHandler:^(NSInteger result) {
			// Create a security scoped bookmark here so we don't ask the user again.
			NSURL *url = [spanel URL];
			NSData *data = [url bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope includingResourceValuesForKeys:nil relativeToURL:nil error:nil];
			if (data) {
				[prefs setObject:data forKey:[targetUSBName stringByAppendingString:@"_USBSecurityBookmarkTarget"]];
				[prefs synchronize];
			}
		}];
	}

	outURL = [NSURL URLByResolvingBookmarkData:[[NSUserDefaults standardUserDefaults]
												objectForKey:[targetUSBName stringByAppendingString:@"_USBSecurityBookmarkTarget"]]
									   options:NSURLBookmarkResolutionWithSecurityScope
								 relativeToURL:nil
						   bookmarkDataIsStale:nil
										 error:nil];

	return outURL;
}

@end
