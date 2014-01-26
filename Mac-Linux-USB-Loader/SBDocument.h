//
//  SBDocument.h
//  Mac-Linux-USB-Loader
//
//  Created by SevenBits on 1/13/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RSTLCopyOperation.h"

@interface SBDocument : NSDocument <RSTLCopyOperationDelegate>

@property (weak) IBOutlet NSImageView *imageIcon;

@end
