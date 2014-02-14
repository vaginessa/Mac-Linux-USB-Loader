//
//  SBEnterprisePreferencesViewController.m
//  Mac Linux USB Loader
//
//  Created by SevenBits on 2/14/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import "SBEnterprisePreferencesViewController.h"

@interface SBEnterprisePreferencesViewController ()

@end

@implementation SBEnterprisePreferencesViewController

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
    return NSLocalizedString(@"Enterprise", nil);
}

@end
