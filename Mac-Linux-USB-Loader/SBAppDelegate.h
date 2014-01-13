//
//  SBAppDelegate.h
//  Mac Linux USB Loader
//
//  Created by SevenBits on 1/13/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SBAppDelegate : NSObject {
	__unsafe_unretained NSWindow *window;
}

@property (unsafe_unretained) IBOutlet NSWindow *window;

@end
