//
//  SBUSBDevice.h
//  Mac Linux USB Loader
//
//  Created by SevenBits on 1/18/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SBDocument.h"

@interface SBUSBDevice : NSObject

/// The path (including the mount point) of the USB drive represented by this object.
@property (nonatomic, strong) NSString *path;

/// The "name" of the USB; really just its drive label.
@property (nonatomic, strong) NSString *name;

/**
 * Creates a persistence file on the USB stick of the specified size. The file is formatted to contain
 * a loopback ext4 filesystem.
 *
 * @param file The path to the file (which doesn't need to exist) that should be used.
 * @param size An integer size, in megabytes, of the file.
 * @param window The window from which to display popup alerts. Currently unused.
 */
+ (void)createPersistenceFileAtUSB:(NSString *)file withSize:(NSInteger)size withWindow:(NSWindow *)window;

/**
 * Uses an internal Mac Linux USB Loader tool to create a loopback ext4 filesystem inside of the
 * specified file. This is used mainly by createPersistenceFileAtUSB:, and doesn't really need to be
 * called directly.
 *
 * @param file The path to the file that should be used.
 */
+ (void)createLoopbackPersistence:(NSString *)file;

/**
 * Copies the Enterprise boot loader files to the USB device represented by this object.
 *
 * @param document The instance of the document class that this object belongs to.
 */
- (bool)copyInstallationFiles:(NSDocument *)document;

@end
