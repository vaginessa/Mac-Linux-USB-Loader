//
//  SBUpdatePreferencesViewController.m
//  Mac Linux USB Loader
//
//  Created by SevenBits on 3/14/15.
//  Copyright (c) 2015 SevenBits. All rights reserved.
//

#import <Sparkle/Sparkle.h>

#import "SBUpdatePreferencesViewController.h"

@interface SBUpdatePreferencesViewController ()

@end

@implementation SBUpdatePreferencesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (NSString *)identifier {
	return NSStringFromClass(self.class);
}

- (NSImage *)toolbarItemImage {
	return [NSImage imageNamed:@"SparkleUpdate"];
}

- (NSString *)toolbarItemLabel {
	return NSLocalizedString(@"Updates", nil);
}

#pragma mark - IBActions

- (IBAction)changeUpdateChannel:(NSPopUpButton *)sender {
	if (sender.selectedTag == 1) {
		NSURL *feedURL = [NSURL URLWithString:@"https://www.sevenbits.tk/appcasts/mlul-beta.xml"];
		[[SUUpdater sharedUpdater] setFeedURL:feedURL];
	} else {
		// TODO: Change this so it grabs from app's plist file, in case this ever changes in the
		// future.
		NSURL *feedURL = [NSURL URLWithString:@"https://www.sevenbits.tk/appcasts/mlul.xml"];
		[[SUUpdater sharedUpdater] setFeedURL:feedURL];
	}
}

@end
