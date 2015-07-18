//
//  SBAboutWindowController.m
//  Mac Linux USB Loader
//
//  Created by SevenBits on 1/27/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import "SBAboutWindowController.h"

/// The speed at which the scrolling text moves in points per second.
static CGFloat kAboutWindowCreditsAnimationSpeed = 1.5;

/// The height of the fade effect in points.
static CGFloat kAboutWindowCreditsFadeHeight = 15.0;

/// The colors of the fade effect gradient.
static CGColorRef kAboutWindowCreditsFadeColor1 = NULL;

/// The colors of the fade effect gradient.
static CGColorRef kAboutWindowCreditsFadeColor2 = NULL;

@interface SBAboutWindowController ()

@property (nonatomic, strong) CALayer *creditsRootLayer;
@property (nonatomic, strong) CAGradientLayer *creditsTopFadeLayer;
@property (nonatomic, strong) CAGradientLayer *creditsBottomFadeLayer;
@property (nonatomic, strong) CATextLayer *creditsTextLayer;

@property (nonatomic, assign) BOOL isCreditsAnimationActive;
@property (nonatomic, readonly) CGFloat creditsFadeHeightCompensation;
@property (nonatomic, readonly) CGFloat scaleFactor;

@property (weak) IBOutlet NSTextField *applicationVersionLabel;
@property (weak) IBOutlet NSView *aboutView;
@property (weak) IBOutlet NSView *creditsView;

@end

@implementation SBAboutWindowController

#pragma mark - Setup
+ (void)initialize {
	kAboutWindowCreditsFadeColor1 = CGColorCreateGenericGray(1.0, 1.0);
	kAboutWindowCreditsFadeColor2 = CGColorCreateGenericGray(1.0, 0.0);
}

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
	_scaleFactor = [[self.creditsView window] backingScaleFactor];
	[self.creditsView setLayer:self.creditsRootLayer];
	[self.creditsView setWantsLayer:YES];
	[self.applicationVersionLabel setStringValue:versionString];
}

- (void)showWindow:(id)sender {
	[super showWindow:sender];
	[self startCreditsScrollAnimation];
}

- (void)windowWillClose:(NSNotification *)note {
	[self stopCreditsScrollAnimation];
}

#pragma mark - IBActions

- (IBAction)showAcknowledgementsButtonPressed:(id)sender {
	NSError *err;
	NSString *path = [[NSBundle mainBundle] pathForResource:@"Acknowledgements" ofType:@"rtf"];
	NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"Acknowledgements"];
	if (![[NSFileManager defaultManager] removeItemAtPath:tempPath error:&err] && [[NSFileManager defaultManager] fileExistsAtPath:tempPath isDirectory:NULL]) {
		return;
	}

	if (![[NSWorkspace sharedWorkspace] openFile:tempPath withApplication:@"TextEdit"]) {
		if ([[NSFileManager defaultManager] copyItemAtPath:path toPath:tempPath error:&err]) {
			[[NSWorkspace sharedWorkspace] openFile:tempPath withApplication:@"TextEdit"];
		} else {
			SBLogObject([err localizedDescription]);
		}
	}
}

- (IBAction)showLicenseAgreementButtonPressed:(id)sender {
	NSError *err;
	NSString *path = [[NSBundle mainBundle] pathForResource:@"Credits" ofType:@"rtf"];
	NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"Credits"];
	if (![[NSFileManager defaultManager] removeItemAtPath:tempPath error:&err] && [[NSFileManager defaultManager] fileExistsAtPath:tempPath isDirectory:NULL]) {
		return;
	}

	if (![[NSWorkspace sharedWorkspace] openFile:tempPath withApplication:@"TextEdit"]) {
		if ([[NSFileManager defaultManager] copyItemAtPath:path toPath:tempPath error:&err]) {
			[[NSWorkspace sharedWorkspace] openFile:tempPath withApplication:@"TextEdit"];
		} else {
			SBLogObject([err localizedDescription]);
		}
	}
}

#pragma mark - Properties

- (NSString *)applicationVersionString {
	return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

- (NSString *)applicationBuildNumberString {
	return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
}

#pragma mark - Higher level

- (void)startCreditsScrollAnimation {
	CATextLayer *creditsLayer = self.creditsTextLayer;
	CGFloat viewHeight = self.creditsView.bounds.size.height;
	CGFloat fadeCompensation = self.creditsFadeHeightCompensation;

	// Enable animation and reset.
	self.isCreditsAnimationActive = YES;
	[self resetCreditsScrollPosition];

	// Animate to top and execute animation again - resulting in endless loop.
	[CATransaction begin];
	[CATransaction setAnimationDuration:(viewHeight / kAboutWindowCreditsAnimationSpeed)];
	[CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
	[CATransaction setCompletionBlock: ^{
	    if (!self.isCreditsAnimationActive) return;
	    [self startCreditsScrollAnimation];
	}];
	creditsLayer.position = CGPointMake(0.0, viewHeight + fadeCompensation);
	[CATransaction commit];
}

- (void)stopCreditsScrollAnimation {
	self.isCreditsAnimationActive = NO;
	[self resetCreditsScrollPosition];
}

/// Reset the scroll effect. Put the text back at the bottom and start again.
- (void)resetCreditsScrollPosition {
	CATextLayer *creditsLayer = self.creditsTextLayer;
	CGFloat textHeight = creditsLayer.frame.size.height;
	CGFloat fadeCompensation = self.creditsFadeHeightCompensation;

	[CATransaction begin];
	[CATransaction setAnimationDuration:0.0];
	creditsLayer.position = CGPointMake(0.0, -textHeight - fadeCompensation);
	[CATransaction commit];
}

- (CGFloat)creditsFadeHeightCompensation {
	return self.creditsTopFadeLayer.frame.size.height;
}

#pragma mark - Core Animation layers

- (CATextLayer *)creditsTextLayer {
	if (_creditsTextLayer) return _creditsTextLayer;
	NSString *path = [[NSBundle mainBundle] pathForResource:@"Credits" ofType:@"rtf"];
	NSAttributedString *credits = [[NSAttributedString alloc] initWithPath:path documentAttributes:nil];
	CGSize size = [self sizeForAttributedString:credits inWidth:self.creditsView.bounds.size.width];
	_creditsTextLayer = [CATextLayer layer];
	_creditsTextLayer.wrapped = YES;
	_creditsTextLayer.string = credits;
	_creditsTextLayer.anchorPoint = CGPointMake(0.0, 0.0);
	_creditsTextLayer.frame = CGRectMake(0.0, 0.0, size.width, size.height);

	_creditsTextLayer.contentsScale = self.scaleFactor;
	_creditsTextLayer.delegate = self;

	return _creditsTextLayer;
}

- (CAGradientLayer *)creditsTopFadeLayer {
	if (_creditsTopFadeLayer) return _creditsTopFadeLayer;
	CGColorRef color1 = kAboutWindowCreditsFadeColor1;
	CGColorRef color2 = kAboutWindowCreditsFadeColor2;
	CGFloat height = kAboutWindowCreditsFadeHeight;
	_creditsTopFadeLayer = [CAGradientLayer layer];
	_creditsTopFadeLayer.colors = @[(__bridge id)color1, (__bridge id)color2];
	_creditsTopFadeLayer.frame = CGRectMake(0.0, 0.0, self.creditsView.bounds.size.width, height);

	_creditsTopFadeLayer.contentsScale = self.scaleFactor;
	_creditsTopFadeLayer.delegate = self;

	return _creditsTopFadeLayer;
}

- (CAGradientLayer *)creditsBottomFadeLayer {
	if (_creditsBottomFadeLayer) return _creditsBottomFadeLayer;
	CGColorRef color1 = kAboutWindowCreditsFadeColor1;
	CGColorRef color2 = kAboutWindowCreditsFadeColor2;
	CGFloat height = kAboutWindowCreditsFadeHeight;
	_creditsBottomFadeLayer = [CAGradientLayer layer];
	_creditsBottomFadeLayer.colors = @[(__bridge id)color2, (__bridge id)color1];
	_creditsBottomFadeLayer.frame = CGRectMake(0.0, self.creditsView.bounds.size.height - height, self.creditsView.bounds.size.width, height);

	_creditsBottomFadeLayer.contentsScale = self.scaleFactor;
	_creditsBottomFadeLayer.delegate = self;

	return _creditsBottomFadeLayer;
}

- (CALayer *)creditsRootLayer {
	if (_creditsRootLayer) return _creditsRootLayer;
	_creditsRootLayer = [CALayer layer];
	[_creditsRootLayer addSublayer:self.creditsTextLayer];
	[_creditsRootLayer addSublayer:self.creditsTopFadeLayer];
	[_creditsRootLayer addSublayer:self.creditsBottomFadeLayer];

	_creditsRootLayer.contentsScale = self.scaleFactor;
	_creditsRootLayer.delegate = self;

	return _creditsRootLayer;
}

- (CGSize)sizeForAttributedString:(NSAttributedString *)string inWidth:(CGFloat)width {
	CTTypesetterRef typesetter = CTTypesetterCreateWithAttributedString((__bridge CFAttributedStringRef)string);
	CFIndex offset = 0, length;
	CGFloat height = 0;
	do {
		length = CTTypesetterSuggestLineBreak(typesetter, offset, width);
		CTLineRef line = CTTypesetterCreateLine(typesetter, CFRangeMake(offset, length));
		CGFloat ascent, descent, leading;
		CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
		CFRelease(line);
		offset += length;
		height += ascent + descent + leading;
	}
	while (offset < [string length]);
	CFRelease(typesetter);
	return CGSizeMake(width, ceil(height));
}

- (BOOL)layer:(CALayer *)layer shouldInheritContentsScale:(CGFloat)newScale fromWindow:(NSWindow *)window {
	if (layer == _creditsRootLayer) {
		_scaleFactor = newScale; // Just to keep the value consistent
	}
	return YES;
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
