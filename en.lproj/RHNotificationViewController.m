//
//  RHAboutViewController.m
//  RHPreferencesTester
//
//  Originally created by Richard Heard on 23/05/12. Subsequently modified by SevenBits.
//  Copyright (c) 2012-2013 SevenBits. All rights reserved.
//

#import "RHNotificationViewController.h"

@interface RHNotificationViewController ()

@end

@implementation RHNotificationViewController

@synthesize notificationCenterButton;
@synthesize displayNotificationsCheckbox;
@synthesize panelView;

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:@"RHNotificationViewController" bundle:nibBundleOrNil];
    if (self){
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults synchronize];
        
        if ([defaults boolForKey:@"ShowNotifications"] == YES) {
            [displayNotificationsCheckbox setState:NSOnState];
        } else {
            [displayNotificationsCheckbox setState:NSOffState];
        }
    }
    return self;
}

- (IBAction)showNotificationCenter:(NSButton*)sender {
    NSProcessInfo *pinfo = [NSProcessInfo processInfo];
    NSArray *myarr = [[pinfo operatingSystemVersionString] componentsSeparatedByString:@" "];
    NSString *version = [myarr objectAtIndex:1];
    
    // Ensure that we are running 10.8 before we display the preferences as we still support Lion, which does not have
    // notifications.
    if ([version rangeOfString:@"10.8"].location == NSNotFound) {
        [sender setEnabled:NO];
    } else {
        [[NSWorkspace sharedWorkspace] openFile:@"/System/Library/PreferencePanes/Notifications.prefPane"];
    }
}

- (IBAction)setShowNotifications:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    BOOL showNotifications;
    if ([displayNotificationsCheckbox state] == NSOnState) {
        showNotifications = YES;
    } else {
        showNotifications = NO;
    }
    
    [defaults setBool:showNotifications forKey:@"ShowNotifications"];
    [defaults synchronize];
    
    NSLog(@"Setting show notifications to %ld. Value is now: %c", (long)[displayNotificationsCheckbox state],
          (BOOL)[defaults boolForKey:@"ShowNotifications"]);
}

#pragma mark - RHPreferencesViewControllerProtocol

-(NSString*)identifier{
    return NSStringFromClass(self.class);
}
-(NSImage*)toolbarItemImage{
    return [NSImage imageNamed:@"Notifications"];
}
-(NSString*)toolbarItemLabel{
    return NSLocalizedString(@"Notifications", @"AboutToolbarItemLabel");
}

-(NSView*)initialKeyView{
    return nil;
}

@end
