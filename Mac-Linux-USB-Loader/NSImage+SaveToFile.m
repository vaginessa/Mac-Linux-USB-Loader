//
//  NSImage+SaveToFile.m
//  Mac Linux USB Loader
//
//  Created by SevenBits on 8/18/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import "NSImage+SaveToFile.h"

@implementation NSImage (SaveToFile)

- (void)saveAsPNGWithName:(NSString *)fileName {
	// Cache the reduced image
	NSData *imageData = [self TIFFRepresentation];
	NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
	NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
	imageData = [imageRep representationUsingType:NSPNGFileType properties:imageProps];
	[imageData writeToFile:fileName atomically:NO];
}

@end