//
//  SBAboutWindowController.m
//  Mac Linux USB Loader
//
//  Created by SevenBits on 1/27/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import "SBAboutWindowController.h"

@interface SBAboutWindowController ()

@property (weak) IBOutlet NSTextField *applicationVersionLabel;
@property (weak) IBOutlet NSView *aboutView;
@property (weak) IBOutlet NSPanel *acknowledgementsPanel;
@property (strong) IBOutlet NSTextView *acknowledgementsText;

@end

@implementation SBAboutWindowController

#pragma mark - Setup

- (instancetype)initWithWindow:(NSWindow *)window {
	self = [super initWithWindow:window];
	if (self) {
		// Initialization code here.
	}
	return self;
}

#pragma mark - Window
- (void)windowDidLoad {
	[super windowDidLoad];

	NSString *versionFormat = NSLocalizedString(@"Version %@ (%@)", nil);
	NSString *versionString = [NSString stringWithFormat:versionFormat, self.applicationVersionString, self.applicationBuildNumberString];
	(self.applicationVersionLabel).stringValue = versionString;
}

#pragma mark - IBActions

- (IBAction)showAcknowledgementsButtonPressed:(NSButton *)sender {
	NSString *path = [[NSBundle mainBundle] pathForResource:@"Acknowledgements" ofType:@"rtf"];
	[self.acknowledgementsText readRTFDFromFile:path];
	[self.acknowledgementsPanel makeKeyAndOrderFront:nil];
	(self.acknowledgementsPanel).title = sender.title;
}

- (IBAction)showLicenseAgreementButtonPressed:(NSButton *)sender {
	NSString *path = [[NSBundle mainBundle] pathForResource:@"Credits" ofType:@"rtf"];
	[self.acknowledgementsText readRTFDFromFile:path];
	[self.acknowledgementsPanel makeKeyAndOrderFront:nil];
	(self.acknowledgementsPanel).title = sender.title;
}

#pragma mark - Properties

- (NSString *)applicationVersionString {
	return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

- (NSString *)applicationBuildNumberString {
	return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
}

@end
@implementation BackgroundColorView

@synthesize gb_backgroundColor = _gb_backgroundColor;

- (void)drawRect:(NSRect)dirtyRect {
	[self.gb_backgroundColor set];
	NSRectFillUsingOperation(dirtyRect, NSCompositeSourceOver);
}

- (NSColor *)gb_backgroundColor {
	if (_gb_backgroundColor) return _gb_backgroundColor;
	_gb_backgroundColor = [NSColor whiteColor];
	return _gb_backgroundColor;
}

@end
