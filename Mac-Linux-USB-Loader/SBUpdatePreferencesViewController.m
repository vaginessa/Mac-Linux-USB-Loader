//
//  SBUpdatePreferencesViewController.m
//  Mac Linux USB Loader
//
//  Created by Ryan Bowring on 3/14/15.
//  Copyright (c) 2015 SevenBits. All rights reserved.
//

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

@end
