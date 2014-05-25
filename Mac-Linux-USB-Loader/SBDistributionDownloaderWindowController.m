//
//  SBDistributionDownloaderWindowController.m
//  Mac Linux USB Loader
//
//  Created by SevenBits on 5/9/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import "SBDistributionDownloaderWindowController.h"
#import "SBAppDelegate.h"
#import "SBDownloadMirrorModel.h"
#import "SBDownloadableDistributionModel.h"

@interface SBDistributionDownloaderWindowController ()

@property (strong) IBOutlet NSView *accessoryView;
@property (weak) IBOutlet NSTableView *tableView;

@property (nonatomic, strong) id jsonRecieved;
@property (nonatomic, strong) SBDownloadableDistributionModel *downloadDistroModel;

@end

@implementation SBDistributionDownloaderWindowController

#pragma mark - Object Setup
- (id)initWithWindow:(NSWindow *)window {
	self = [super initWithWindow:window];
	if (self) {
		// First things first. Grab the JSON.
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		    // Grab our JSON, but do it on a background thread so we don't slow down the GUI.
		    [self setupJSON];
		});
	}
	return self;
}

- (void)setupJSON {
	NSURL *url = [NSURL URLWithString:@"https://github.com/SevenBits/mlul-iso-mirrors/raw/master/mirrors/Linux-Mint.json"];
#ifdef DEBUG
	if ([url isFileURL]) {
		NSLog(@"We have a local URL, parsing locally.");

		NSError *err;
		NSString *strCon = [NSString stringWithContentsOfURL:url encoding:NSASCIIStringEncoding error:&err];

		if (strCon) {
			[self processJSON:strCon];
		}
	}
	else {
#endif
	NSError *err;
	NSString *strCon = [NSString stringWithContentsOfURL:url encoding:NSASCIIStringEncoding error:&err];
	if (!err) {
		NSLog(@"Recieved JSON data: %@", strCon);
		[self processJSON:strCon];
	}
	else {
		dispatch_async(dispatch_get_main_queue(), ^{
		    NSAlert *alert = [NSAlert alertWithError:err];
		    [alert runModal];
		});
	}
#ifdef DEBUG
}

#endif
}

- (void)processJSON:(NSString *)json {
	JSONModelError *error;
	self.downloadDistroModel = [[SBDownloadableDistributionModel alloc] initWithString:json error:&error];
	if (error) {
		dispatch_async(dispatch_get_main_queue(), ^{
		    NSAlert *alert = [NSAlert alertWithError:error];
		    [alert runModal];
		});
	}
	else {
		//SBLogObject(self.downloadDistroModel);
	}
}

- (void)windowDidLoad {
	[super windowDidLoad];

	// Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
	[self.window setDelegate:self];

	// Setup the accessory view.
	[self placeAccessoryView];

	NSView *themeFrame = [[self.window contentView] superview];
	[themeFrame addSubview:self.accessoryView];

	// Setup delegates.
	[self.tableView setDataSource:self];
	[self.tableView setDelegate:self];
}

#pragma mark - Delegates
- (void)windowDidResize:(NSNotification *)notification {
	// Keep the accessory view in the right place in the window.
	[self placeAccessoryView];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return [[[NSApp delegate] supportedDistributions] count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	if ([[[aTableColumn headerCell] stringValue] isEqualToString:NSLocalizedString(@"Distribution Name", nil)]) {
		return [[[NSApp delegate] supportedDistributions] objectAtIndex:rowIndex];
	}
	else if ([[[aTableColumn headerCell] stringValue] isEqualToString:NSLocalizedString(@"Current Version", nil)]) {
		NSString *distribution = [[[NSApp delegate] supportedDistributions] objectAtIndex:rowIndex];
		return [[[NSApp delegate] supportedDistributionsAndVersions] objectForKey:distribution];
	}
	else {
		return @"N/A";
	}
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	return NO;
}

#pragma mark - UI
- (void)placeAccessoryView {
	NSView *themeFrame = [[self.window contentView] superview];
	NSRect c = [themeFrame frame];  // c for "container"
	NSRect aV = [self.accessoryView frame]; // aV for "accessory view"
	NSRect newFrame = NSMakeRect(c.size.width - aV.size.width - 25, // x position
	                             c.size.height - aV.size.height, // y position
	                             aV.size.width, // width
	                             aV.size.height); // height
	[self.accessoryView setFrame:newFrame];
	[self.accessoryView setNeedsDisplay:YES];
}

@end
