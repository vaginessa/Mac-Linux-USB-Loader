//
//  RHAboutViewController.m
//  RHPreferencesTester
//
//  Originally created by Richard Heard on 23/05/12. Subsequently modified by SevenBits.
//  Copyright (c) 2012-2013 SevenBits. All rights reserved.
//

#import "SBAcknowledgementsViewController.h"

@interface SBAcknowledgementsViewController ()

@end

@implementation SBAcknowledgementsViewController
@synthesize emailTextField = emailTextField;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:@"SBAcknowledgementsViewController" bundle:nibBundleOrNil];
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
    return [NSImage imageNamed:@"AboutPreferences"];
}
- (NSString*)toolbarItemLabel {
    return NSLocalizedString(@"ACKNOWLEDGEMENTS", @"AboutToolbarItemLabel");
}

- (NSView*)initialKeyView{
    return self.emailTextField;
}

@end
