//
//  SBGeneralPreferencesViewController.m
//  Mac Linux USB Loader
//
//  Created by SevenBits on 2/3/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import "SBGeneralPreferencesViewController.h"
#import "SBAppDelegate.h"

@interface SBGeneralPreferencesViewController ()

@end

@implementation SBGeneralPreferencesViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		// Initialization code here.
	}
	return self;
}

- (IBAction)clearCachesButtonPressed:(id)sender {
	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:NSLocalizedString(@"Yes", nil)];
	[alert addButtonWithTitle:NSLocalizedString(@"No", nil)];
	[alert setMessageText:NSLocalizedString(@"Are you sure you want to clear caches?", nil)];
	[alert setInformativeText:NSLocalizedString(@"This can be useful if you want to conserve your disk space, but it will delete all of your downloaded ISO files and reset your download mirrors. Is this okay?", nil)];
	[alert setAlertStyle:NSWarningAlertStyle];
	[alert beginSheetModalForWindow:[self.view window] modalDelegate:self didEndSelector:@selector(deleteCachesAlertSheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (NSString *)identifier {
	return NSStringFromClass(self.class);
}

- (NSImage *)toolbarItemImage {
	return [NSImage imageNamed:@"NSApplicationIcon"];
}

- (NSString *)toolbarItemLabel {
	return NSLocalizedString(@"General", nil);
}

- (void)deleteCachesAlertSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	if (returnCode == NSAlertFirstButtonReturn) {
		[(SBAppDelegate *)[NSApp delegate] purgeCachesAndOldFiles];
	}
}

@end
