//
//  RHAboutViewController.m
//  RHPreferencesTester
//
//  Created by Richard Heard on 17/04/12.
//  Copyright (c) 2012 Richard Heard. All rights reserved.
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
    [defaults setBool:NO forKey:@"ShowNotifications"];
    [defaults synchronize];
}

#pragma mark - RHPreferencesViewControllerProtocol

-(NSString*)identifier{
    return NSStringFromClass(self.class);
}
-(NSImage*)toolbarItemImage{
    return [NSImage imageNamed:@"NotificationPreferences"];
}
-(NSString*)toolbarItemLabel{
    return NSLocalizedString(@"Notifications", @"AboutToolbarItemLabel");
}

-(NSView*)initialKeyView{
    return nil;
}

@end
