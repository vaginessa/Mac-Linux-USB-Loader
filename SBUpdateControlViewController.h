//
//  RHAccountsViewController.h
//  RHPreferencesTester
//
//  Originally created by Richard Heard on 23/05/12. Subsequently modified by SevenBits.
//  Copyright (c) 2012-2013 SevenBits. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <RHPreferences/RHPreferences.h>

@interface SBUpdateControlViewController : NSViewController  <RHPreferencesViewControllerProtocol> {
    //NSTextField *usernameTextField;
}

@property (unsafe_unretained) IBOutlet NSTextField *usernameTextField;


@end
