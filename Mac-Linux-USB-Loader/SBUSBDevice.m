//
//  SBUSBDevice.m
//  Mac Linux USB Loader
//
//  Created by SevenBits on 1/18/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import <copyfile.h>
#import "SBUSBDevice.h"
#import "NSString+Extensions.h"

typedef enum {
	NotStarted = 0,
	InProgress,
	Finished,
} State;

@implementation SBUSBDevice {
	copyfile_state_t copyfileState;
	State state;
	NSTimer *progressTimer;

	SBDocument *attachedDocument;
	BOOL USBIsInUse;
}

#pragma mark - Class methods
+ (void)createPersistenceFileAtUSB:(NSString *)file withSize:(NSUInteger)size withWindow:(NSWindow *)window {
	// Initalize the NSTask.
	NSTask *task = [[NSTask alloc] init];
	task.launchPath = @"/bin/dd";
	task.arguments = @[@"if=/dev/zero", [@"of=" stringByAppendingString:file], @"bs=1m",
	                   [NSString stringWithFormat:@"count=%ld", (long)size]];
	NSLog(@"command: %@ %@", task.launchPath, [task.arguments componentsJoinedByString:@" "]);

	// Launch the NSTask.
	[task launch];
	[task waitUntilExit];

	// Create the loopback file.
	NSLog(@"Done USB persistence creation!");
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

	// Answer "yes" to the message where the program complains that the file is not a block
	// special device and asks if we want to continue anyway.
	[handle writeData:[NSData dataWithBytes:"y" length:strlen("y")]];
	[handle closeFile];
	[task waitUntilExit];
}

+ (SBLinuxDistribution)distributionTypeForISOName:(NSString *)fileName {
	fileName = [[fileName lowercaseString] lastPathComponent];
	if ([fileName containsSubstring:@"ubuntu"] ||
	    [fileName containsSubstring:@"linuxmint"] ||
	    [fileName containsSubstring:@"elementaryos"]) {
		return SBDistributionUbuntu;
	}
	else if ([fileName containsSubstring:@"tails"]) {
		return SBDistributionTails;
	}

	return SBDistributionUnknown;
}

#pragma mark - Instance methods
- (id)init {
	self = [super init];
	if (self) {
		// Add your subclass-specific initialization here.
	}
	return self;
}

- (BOOL)copyInstallationFiles:(SBDocument *)document {
	// Create an operation for the operation queue to copy over the necessary files.
	attachedDocument = document;
	USBIsInUse = YES;
	NSString *finalISOCopyPath = [NSString stringWithFormat:@"/Volumes/%@/efi/boot/boot.iso",
	                              self.name];

	dispatch_async(dispatch_get_main_queue(), ^{
	    progressTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(outputProgress:) userInfo:@{} repeats:YES];
	});

	copyfile_state_t s;
	s = copyfile_state_alloc();

	const char *fromPath = [document.fileURL.path UTF8String];
	const char *toPath = [finalISOCopyPath UTF8String];

	NSLog(@"from: %s to: %s", fromPath, toPath);

	NSLog(@"Will start copying");

	int returnCode;
	copyfileState = copyfile_state_alloc();
	{
		state = InProgress;

		returnCode = copyfile(fromPath, toPath, copyfileState, COPYFILE_ALL);

		state = Finished;
		[progressTimer performSelectorOnMainThread:@selector(invalidate) withObject:nil waitUntilDone:YES];
		progressTimer = nil;
	}
	copyfile_state_free(copyfileState);

	NSLog(@"Did finish copying with return code %d", returnCode);

	return YES;
}

- (BOOL)copyEnterpriseFiles:(SBDocument *)document withEnterpriseSource:(SBEnterpriseSourceLocation *)source {
	// Create an operation for the operation queue to copy over the necessary files.
	attachedDocument = document;
	USBIsInUse = YES;
	NSString *finalEnterpriseCopyPath = [NSString stringWithFormat:@"/Volumes/%@/efi/boot/bootx64.efi",
	                              self.name];
	NSString *finalGRUBCopyPath = [NSString stringWithFormat:@"/Volumes/%@/efi/boot/boot.efi",
										 self.name];

	dispatch_async(dispatch_get_main_queue(), ^{
	    progressTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(outputProgress:) userInfo:@{} repeats:YES];
	});

	// First, copy Enterprise.
	copyfile_state_t s;
	s = copyfile_state_alloc();

	const char *fromPath = [[source.path stringByAppendingPathComponent:@"bootx64.efi"] UTF8String];
	const char *toPath = [finalEnterpriseCopyPath UTF8String];

	NSLog(@"from: %s to: %s", fromPath, toPath);

	NSLog(@"Will start copying");

	int returnCode;
	copyfileState = copyfile_state_alloc();
	{
		state = InProgress;

		returnCode = copyfile(fromPath, toPath, copyfileState, COPYFILE_ALL);

		state = Finished;
		[progressTimer performSelectorOnMainThread:@selector(invalidate) withObject:nil waitUntilDone:YES];
		progressTimer = nil;
	}
	copyfile_state_free(copyfileState);

	s = copyfile_state_alloc();

	// Next, copy GRUB.
	fromPath = [[source.path stringByAppendingPathComponent:@"boot.efi"] UTF8String];
	toPath = [finalGRUBCopyPath UTF8String];

	NSLog(@"from: %s to: %s", fromPath, toPath);

	NSLog(@"Will start copying");

	copyfileState = copyfile_state_alloc();
	{
		state = InProgress;

		returnCode = copyfile(fromPath, toPath, copyfileState, COPYFILE_ALL);

		state = Finished;
		[progressTimer performSelectorOnMainThread:@selector(invalidate) withObject:nil waitUntilDone:YES];
		progressTimer = nil;
	}
	copyfile_state_free(copyfileState);

	NSLog(@"Did finish copying with return code %d", returnCode);

	return YES;
}

- (void)outputProgress:(NSTimer *)timer {
	switch (state) {
		case NotStarted:
			NSLog(@"Not started yet");
			break;

		case Finished:
			NSLog(@"Finished");
			break;

		case InProgress: {
			off_t copiedBytes;
			const int returnCode = copyfile_state_get(copyfileState, COPYFILE_STATE_COPIED, &copiedBytes);
			if (returnCode == 0) {
				//NSLog(@"Copied %@ so far", [NSByteCountFormatter stringFromByteCount:copiedBytes countStyle:NSByteCountFormatterCountStyleFile]);
				[attachedDocument.installationProgressBar setDoubleValue:copiedBytes];
			}
			else {
				NSLog(@"Could not retrieve copyfile state");
			}

			break;
		}
	}
}

- (BOOL)enableStartupDiskSupport {
	NSString *finalPath = [self.path stringByAppendingString:@"/System/Library/CoreServices/"];
	SBLogObject(finalPath);

	[[NSFileManager defaultManager] createDirectoryAtPath:finalPath withIntermediateDirectories:YES attributes:nil error:nil];

	return YES;
}

@end
