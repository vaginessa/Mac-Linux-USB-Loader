//
//  SBEnterpriseSourceLocation.h
//  Mac Linux USB Loader
//
//  Created by SevenBits on 2/15/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SBEnterpriseSourceLocation : NSObject <NSCoding>

@property (assign) NSString *name;
@property (assign) NSString *path;
@property (assign) NSURL *securityScopedBookmark;
@property (assign) BOOL deletable;

/**
 * Initializes a new SBEnterpriseSourceLocation object immediately after memory for it has been allocated.
 * It is configured with the passed name and path variables.
 *
 * @param name The name (for user reference) of the source location.
 * @param path The path of the source location.
 * @param deletable Whether can user should be able to delete this source.
 */
- (id)initWithName:(NSString *)name andPath:(NSString *)path shouldBeVolatile:(BOOL)deletable;

@end
