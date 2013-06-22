//
//  SBFirmwareViewController.m
//  Mac Linux USB Loader
//
//  Created by Ryan Bowring on 6/22/13.
//
//

#import "SBFirmwareViewController.h"

@implementation SBFirmwareViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

#pragma mark - RHPreferencesViewControllerProtocol

- (NSString*)identifier{
    return NSStringFromClass(self.class);
}
- (NSImage*)toolbarItemImage{
    return [NSImage imageNamed:@"Boot"];
}
- (NSString*)toolbarItemLabel{
    return NSLocalizedString(@"Firmware", @"AboutToolbarItemLabel");
}

- (NSView*)initialKeyView{
    return nil;
}

@end
