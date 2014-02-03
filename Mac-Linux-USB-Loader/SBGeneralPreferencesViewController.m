//
//  SBGeneralPreferencesViewController.m
//  Mac Linux USB Loader
//
//  Created by SevenBits on 2/3/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import "SBGeneralPreferencesViewController.h"

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

- (NSString*)identifier{
    return NSStringFromClass(self.class);
}

- (NSImage*)toolbarItemImage{
    return [NSImage imageNamed:@"NSApplicationIcon"];
}

- (NSString*)toolbarItemLabel{
    return NSLocalizedString(@"General", nil);
}

@end
