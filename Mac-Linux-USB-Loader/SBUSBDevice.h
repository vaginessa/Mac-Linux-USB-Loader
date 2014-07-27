//
//  SBUSBDevice.h
//  Mac Linux USB Loader
//
//  Created by SevenBits on 1/18/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SBGlobals.h"
#import "SBDocument.h"
#import "SBEnterpriseSourceLocation.h"

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
+ (void)createPersistenceFileAtUSB:(NSString *)file withSize:(NSUInteger)size withWindow:(NSWindow *)window;

/**
 * Uses an internal Mac Linux USB Loader tool to create a loopback ext4 filesystem inside of the
 * specified file. This is used mainly by createPersistenceFileAtUSB:, and doesn't really need to be
 * called directly.
 *
 * @param file The path to the file that should be used.
 */
+ (void)createLoopbackPersistence:(NSString *)file;

/**
 * Given a file name corresponding to a Linux distribution ISO, returns an indicator of which distribution
 * was selected. This method disregards the path of the file and operates on the file name only.
 *
 * @param file The path to the file that should be used.
 */
+ (SBLinuxDistribution)distributionTypeForISOName:(NSString *)fileName;

/**
 * Copies the ISO file to the USB device represented by this object.
 *
 * @param document The instance of the document class that this object belongs to.
 * @param usb An instanse of the SBUSBDevice class that represents the USB drive to install to.
 * @return YES if the operation succeeded, NO if it did not.
 */
- (BOOL)copyInstallationFiles:(SBDocument *)document toUSBDrive:(SBUSBDevice *)usb;

/**
 * Copies the Enterprise boot loader to the USB device represented by this object. This method does not
 * attempt to deal with any potential sandboxing issues, such as security scoped bookmarks, instead
 * assuming that the user already has granted access to the target USB device.
 *
 * @param document The instance of the document class that this object belongs to.
 * @param usb An instanse of the SBUSBDevice class that represents the USB drive to install to.
 * @return YES if the operation succeeded, NO if it did not.
 */
- (BOOL)copyEnterpriseFiles:(SBDocument *)document withEnterpriseSource:(SBEnterpriseSourceLocation *)source toUSBDrive:(SBUSBDevice *)usb;

@end
