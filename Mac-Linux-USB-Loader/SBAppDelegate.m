//
//  SBAppDelegate.m
//  Mac Linux USB Loader
//
//  Created by SevenBits on 1/13/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import "SBAppDelegate.h"

@implementation SBAppDelegate
@synthesize window;

- (void)applicationDidFinishLaunching: (NSNotification *)aNotification {
	// Set window properties.
	[self.window setBackgroundColor:[NSColor whiteColor]];
	[self.window setMovableByWindowBackground:YES];

	[[self.window standardWindowButton:NSWindowZoomButton] setHidden:YES];
	[[self.window standardWindowButton:NSWindowMiniaturizeButton] setHidden:YES];
	[self.window setShowsResizeIndicator:NO];
	[self.window setResizeIncrements:NSMakeSize(MAXFLOAT, MAXFLOAT)];

	[self.window setTitle:@""]; // Remove the title.
}

@end
