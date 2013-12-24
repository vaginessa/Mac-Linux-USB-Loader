//
//  RHAboutViewController.h
//  RHPreferencesTester
//
//  Originally created by Richard Heard on 23/05/12. Subsequently modified by SevenBits.
//  Copyright (c) 2012-2013 SevenBits. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <RHPreferences/RHPreferences.h>

@interface SBAcknowledgementsViewController : NSViewController  <RHPreferencesViewControllerProtocol> {
    NSTextField *_emailTextField;
}

@property (unsafe_unretained) IBOutlet NSTextField *emailTextField;

@end
