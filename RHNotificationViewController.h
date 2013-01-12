//
//  RHAboutViewController.h
//  RHPreferencesTester
//
//  Created by Richard Heard on 17/04/12.
//  Copyright (c) 2012 Richard Heard. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <RHPreferences/RHPreferences.h>

#import "ApplicationPreferences.h"

@interface RHNotificationViewController : NSViewController  <RHPreferencesViewControllerProtocol> {
    NSButton *notificationCenterButton;
}

@property (unsafe_unretained) IBOutlet NSButton *notificationCenterButton;
@property (unsafe_unretained) IBOutlet NSButton *displayNotificationsCheckbox;
- (IBAction)showNotificationCenter:(id)sender;
- (IBAction)setShowNotifications:(id)sender;

@end
