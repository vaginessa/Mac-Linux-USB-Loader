//
//  USBDevice.h
//  Mac Linux USB Loader
//
//  Created by SevenBits on 11/26/12.
//  Copyright (c) 2012 SevenBits. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Document.h"
#include <unistd.h>

@interface USBDevice : NSObject

- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)setWindow:(NSWindow *) window;
- (BOOL)prepareUSB:(NSString *)path;
- (BOOL)copyISO:(NSString *)path:(NSString *)isoFile:(NSProgressIndicator *)progressBar:(Document *)document;

@end