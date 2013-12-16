//
//  RHAboutViewController.h
//  RHPreferencesTester
//
//  Originally created by Richard Heard on 23/05/12. Subsequently modified by SevenBits.
//  Copyright (c) 2012-2013 SevenBits. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <RHPreferences/RHPreferences.h>

@interface SBNotificationViewController : NSViewController  <RHPreferencesViewControllerProtocol> {
    //NSButton *notificationCenterButton;
}
@property (unsafe_unretained) IBOutlet NSView *panelView;

@property (unsafe_unretained) IBOutlet NSButton *notificationCenterButton;
@property (unsafe_unretained) IBOutlet NSButton *displayNotificationsCheckbox;
- (IBAction)showNotificationCenter:(id)sender;
- (IBAction)setShowNotifications:(id)sender;

@end
