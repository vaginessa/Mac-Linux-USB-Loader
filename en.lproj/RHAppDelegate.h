//
//  RHAppDelegate.h
//  RHPreferencesTester
//
//  Originally created by Richard Heard on 23/05/12. Subsequently modified by SevenBits.
//  Copyright (c) 2012-2013 SevenBits. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <RHPreferences/RHPreferences.h>

@interface RHAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *_window;
    RHPreferencesWindowController *_preferencesWindowController;
    IBOutlet NSPanel *sheet;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSButton *closeDistroDownloadSheetButton;
@property (retain) RHPreferencesWindowController *preferencesWindowController;
@property (retain) IBOutlet NSPopUpButton *distroPopUpSelector;
@property (retain) IBOutlet NSProgressIndicator *distroDownloadProgressIndicator;


#pragma mark - IBActions
- (IBAction)showPreferences:(id)sender;
- (IBAction)showDownloadDistroSheet:(id)sender;
- (IBAction)closeDownloadDistroSheet:(id)sender;
- (IBAction)downloadDistribution:(id)sender;

#pragma mark - Delegates
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;

@end
