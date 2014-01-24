//
//  SBUSBDevice.m
//  Mac Linux USB Loader
//
//  Created by Ryan Bowring on 1/18/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import "SBUSBDevice.h"

@implementation SBUSBDevice

+ (void)createPersistenceFileAtUSB:(NSString *)file withSize:(NSInteger)size withWindow:(NSWindow *)window {
	/* STEP 1: create the blank file. */
	NSTask *task = [[NSTask alloc] init];

	// Initalize the NSTask.
	task.launchPath = @"/bin/dd";
	task.arguments = @[@"if=/dev/zero", [@"of=" stringByAppendingString:file], @"bs=1m",
					   [NSString stringWithFormat:@"count=%ld", (long)size]];
	NSLog(@"%@", [task.arguments componentsJoinedByString:@" "]);

	// Launch the NSTask.
	[task launch];
	[task waitUntilExit];

	/* STEP 2: create the loopback file. */
	[SBUSBDevice createLoopbackPersistence:file];
	NSLog(@"Done!");
}

+ (void)createLoopbackPersistence:(NSString *)file {
	NSBundle *mainBundle = [NSBundle mainBundle];
	NSString *helperAppPath = [[mainBundle bundlePath]
							   stringByAppendingString:@"/Contents/Resources/Tools/mke2fs"];

	NSTask *task = [[NSTask alloc] init];
	task.launchPath = helperAppPath;
	task.arguments = @[@"-t", @"ext4", file];

	// Create a pipe for writing.
	NSPipe *inputPipe = [NSPipe pipe];
	dup2([[inputPipe fileHandleForReading] fileDescriptor], STDIN_FILENO);
	[task setStandardInput:inputPipe];

	NSFileHandle *handle = [inputPipe fileHandleForWriting];
	[task launch];

	[handle writeData:[NSData dataWithBytes:"y" length:strlen("y")]];
	[handle closeFile];
	[task waitUntilExit];
}

- (id)init {
    self = [super init];
    if (self) {
		// Add your subclass-specific initialization here.
    }
    return self;
}

@end
