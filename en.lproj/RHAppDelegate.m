//
//  RHAppDelegate.m
//  RHPreferencesTester
//
//  Originally created by Richard Heard on 23/05/12. Subsequently modified by SevenBits.
//  Copyright (c) 2012-2013 SevenBits. All rights reserved.
//

#import "RHAppDelegate.h"
#import "RHAboutViewController.h"
#import "RHAccountsViewController.h"
#import "RHNotificationViewController.h"

#import "DistributionDownloader.h"

@implementation RHAppDelegate

@synthesize window = _window;
@synthesize preferencesWindowController=_preferencesWindowController;
@synthesize distroPopUpSelector;
@synthesize closeDistroDownloadSheetButton;
@synthesize distroDownloadButton;
@synthesize distroDownloadProgressIndicator;
@synthesize distroSelectorComboBox;

NSWindow *downloadLinuxDistroSheet;
BOOL canQuit = YES; // Can the user quit the application?

- (void)dealloc
{
    [_preferencesWindowController release]; _preferencesWindowController = nil;
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    // Once we get any operation going, do this to not let the user quit the app until it finishes.
    if (canQuit) {
        return YES;
    } else {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"Yes"];
        [alert addButtonWithTitle:@"No"];
        [alert setMessageText:@"Operation in progress."];
        [alert setInformativeText:@"Mac Linux USB Loader is currently in the middle of an operation. Quitting the application at this time could result in corrupted data. Do you want to quit anyway?"];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert beginSheetModalForWindow:_window modalDelegate:self didEndSelector:@selector(quitSheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
        return NO;
    }
}

- (BOOL)canQuit {
    return canQuit;
}

- (BOOL)setCanQuit:(BOOL)ableToQuit {
#ifdef DEBUG
    NSLog(@"Can quit: %i. Setting to: %i", canQuit, ableToQuit);
#endif
    
    canQuit = ableToQuit;
    return canQuit;
}

#pragma mark - IBActions
- (IBAction)showPreferences:(id)sender {
    //if we have not created the window controller yet, create it now
    if (!_preferencesWindowController){
        RHAccountsViewController *accounts = [[[RHAccountsViewController alloc] init] autorelease];
        RHAboutViewController *about = [[[RHAboutViewController alloc] init] autorelease];
        RHNotificationViewController *notifications = [[[RHNotificationViewController alloc] init] autorelease];
        
        NSArray *controllers = [NSArray arrayWithObjects:accounts, notifications,
                                [RHPreferencesWindowController flexibleSpacePlaceholderController], 
                                about,
                                nil];
        
        _preferencesWindowController = [[RHPreferencesWindowController alloc] initWithViewControllers:controllers andTitle:NSLocalizedString(@"Preferences", @"Preferences Window Title")];
    }
    
    [_preferencesWindowController showWindow:self];
}

#pragma mark - Distribution Downloader
- (IBAction)showDownloadDistroSheet:(id)sender {
    [NSApp beginSheet:sheet modalForWindow:(NSWindow *)_window modalDelegate:self
       didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (IBAction)closeDownloadDistroSheet:(id)sender {
    [NSApp endSheet:sheet];
    [sheet orderOut:sender];
}

- (IBAction)downloadDistribution:(id)sender {
    if (distroSelectorComboBox != nil && distroSelectorComboBox.indexOfSelectedItem != -1) {
        //[closeDistroDownloadSheetButton setEnabled:NO];
        [self setCanQuit:NO]; // Prevent the user from quiting the application until the download has finished.
        
        [distroDownloadButton setEnabled:NO];
        [distroDownloadProgressIndicator startAnimation:self];
        [distroDownloadProgressIndicator setDoubleValue:0.0];
        
        NSURL *downloadLocation = [NSURL URLWithString:@"http://releases.ubuntu.com/quantal/ubuntu-12.10-desktop-amd64+mac.iso"];
        
        [[DistributionDownloader new] downloadLinuxDistribution:downloadLocation:
         [NSHomeDirectory() stringByAppendingPathComponent:@"/Desktop/"]:distroDownloadProgressIndicator];
        
        // The program calls the setCanQuit method in the download delegates. We don't call it here, as this function returns
        // immediately.
    } else {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"Okay"];
        [alert setMessageText:@"No distribution selected."];
        [alert setInformativeText:@"Please select a distribution first before clicking the download button."];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert beginSheetModalForWindow:nil modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
    }
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    // Empty
}

- (void)quitSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertFirstButtonReturn) {
        [[NSApp delegate] setCanQuit:YES];
        [NSApp performSelector:@selector(terminate:) withObject:nil afterDelay:0.0];
    }
}

@end
