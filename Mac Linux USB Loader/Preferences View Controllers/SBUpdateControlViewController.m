//
//  RHAccountsViewController.m
//  RHPreferencesTester
//
//  Originally created by Richard Heard on 23/05/12. Subsequently modified by SevenBits.
//  Copyright (c) 2012-2013 SevenBits. All rights reserved.
//

#import "SBUpdateControlViewController.h"

@interface SBUpdateControlViewController ()

@end

@implementation SBUpdateControlViewController
@synthesize usernameTextField;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:@"SBUpdateControlViewController" bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}

#pragma mark - RHPreferencesViewControllerProtocol

- (NSString*)identifier {
    return NSStringFromClass(self.class);
}
- (NSImage*)toolbarItemImage {
    return [NSImage imageNamed:@"Icon"];
}
- (NSString*)toolbarItemLabel {
    return NSLocalizedString(@"APPLICATION", @"AccountsToolbarItemLabel");
}

- (NSView*)initialKeyView{
    return self.usernameTextField;
}

@end
