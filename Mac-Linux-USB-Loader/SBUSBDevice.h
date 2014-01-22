//
//  SBUSBDevice.h
//  Mac Linux USB Loader
//
//  Created by Ryan Bowring on 1/18/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SBUSBDevice : NSObject

@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSString *name;

@end
