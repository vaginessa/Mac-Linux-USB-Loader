//
//  SBAboutWindowController.h
//  Mac Linux USB Loader
//
//  Created by SevenBits on 1/27/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@interface SBAboutWindowController : NSWindowController

@property (weak) IBOutlet NSTextField *applicationVersionLabel;
@property (weak) IBOutlet NSView *aboutView;
@property (weak) IBOutlet NSView *creditsView;

@end

@interface BackgroundColorView : NSView
@property (nonatomic, strong) NSColor *gb_backgroundColor;
@end
