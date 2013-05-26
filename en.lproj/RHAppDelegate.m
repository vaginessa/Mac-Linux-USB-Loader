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

@synthesize preferencesWindowController=_preferencesWindowController;
@synthesize distroPopUpSelector;
@synthesize closeDistroDownloadSheetButton;
@synthesize distroDownloadButton;
@synthesize distroDownloadProgressIndicator;
@synthesize distroSelectorComboBox;
@synthesize eraseUSBSelector;
@synthesize recentFileBrowser;
@synthesize dataSource;

NSWindow *downloadLinuxDistroSheet;
BOOL canQuit = YES; // Can the user quit the application?

/*
 * This array of NSStrings will be full of URLs to ISOs that the user can download.
 */
NSString *urlArray[] = {
    @"http://releases.ubuntu.com/13.04/ubuntu-13.04-desktop-amd64+mac.iso", // Ubuntu 13.04 for Mac
    @"http://linuxfreedom.com/linuxmint/stable/14/linuxmint-14.1-cinnamon-dvd-64bit.iso", // Mint 14.1 US
    @"http://distro.ibiblio.org/zorin/6/zorin-os-6.3-core-64.iso" // Zorin OS 6.3 US
    };

- (void)dealloc
{
    _preferencesWindowController = nil;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    [eraseUSBSelector removeAllItems];
    [self detectUSBs:nil];
    
    NSArray *myArray = [[NSDocumentController sharedDocumentController] recentDocumentURLs];
    [dataSource setArray:myArray];
    [recentFileBrowser setDataSource:dataSource];
    [recentFileBrowser setDoubleAction:@selector(respondToRecentFileDoubleClick)];
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

- (void)respondToRecentFileDoubleClick {
    NSInteger clickedRow = [recentFileBrowser clickedRow];
    
    if (clickedRow != -1) { // We're in the row.
        NSDocumentController *docControl = [NSDocumentController sharedDocumentController];
        NSURL *selectedDocument = (NSURL *)[[docControl recentDocumentURLs] objectAtIndex:clickedRow];
        NSLog(@"Selected row %ld.", (long)clickedRow);
        [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:selectedDocument display:YES completionHandler:nil];
    }
}

#pragma mark - IBActions
- (IBAction)showPreferences:(id)sender {
    // If we have not created the window controller yet, create it now.
    if (!_preferencesWindowController){
        RHAccountsViewController *accounts = [[RHAccountsViewController alloc] init];
        RHAboutViewController *about = [[RHAboutViewController alloc] init];
        RHNotificationViewController *notifications = [[RHNotificationViewController alloc] init];
        
        NSArray *controllers = [NSArray arrayWithObjects:accounts, notifications,
                                [RHPreferencesWindowController flexibleSpacePlaceholderController], 
                                about,
                                nil];
        
        _preferencesWindowController = [[RHPreferencesWindowController alloc] initWithViewControllers:controllers andTitle:NSLocalizedString(@"Preferences", @"Preferences Window Title")];
    }
    
    [_preferencesWindowController showWindow:self];
}

#pragma mark - USB Live Eraser

- (IBAction)showEraseDistroSheet:(id)sender {
    [NSApp beginSheet:eraseSheet modalForWindow:(NSWindow *)_window modalDelegate:self
       didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (IBAction)closeEraseDistroSheet:(id)sender {
    [NSApp endSheet:eraseSheet];
    [eraseSheet orderOut:sender];
}

- (IBAction)detectUSBs:(id)sender {
    // Fetch the NSArray of strings of mounted media from the shared workspace.
    NSArray *volumes = [[NSWorkspace sharedWorkspace] mountedRemovableMedia];
    
    // Setup target variables for the data to be put into.
    BOOL isRemovable, isWritable, isUnmountable;
    NSString *description, *volumeType;
    
    [eraseUSBSelector removeAllItems]; // Clear the dropdown list.
    
    // Iterate through the array using fast enumeration.
    for (NSString *volumePath in volumes) {
        // Get filesystem info about each of the mounted volumes.
        if ([[NSWorkspace sharedWorkspace] getFileSystemInfoForPath:volumePath isRemovable:&isRemovable isWritable:&isWritable isUnmountable:&isUnmountable description:&description type:&volumeType]) {
            if ([volumeType isEqualToString:@"msdos"] && isWritable && [volumePath rangeOfString:@"/Volumes/"].location != NSNotFound) {
                if([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@/efi/boot/.MLUL-Live-USB", volumePath]]) {
                    // We have a valid mounted media - not necessarily a USB though.
                    NSString * title = [NSString stringWithFormat:@"%@", volumePath];
                
                    [eraseUSBSelector addItemWithTitle:title]; // Add to the dropdown list.
                }
            }
        }
    }
}

- (IBAction)eraseSelectedDrive:(id)sender {
    [[NSApp delegate] setCanQuit:NO];
    
    if ([eraseUSBSelector numberOfItems] != 0) {
        [eraseUSBSelector setEnabled:NO];

        // Construct the path of the efi folder that we're going to nuke.
        NSString *usbRoot = [eraseUSBSelector titleOfSelectedItem];
        NSString *tempPath = [NSString stringWithFormat:@"%@/efi", usbRoot];
        
        // Need these to recursively delete the folder, because UNIX can't erase a folder without erasing its
        // contents first, apparently.
        NSFileManager* fm = [[NSFileManager alloc] init];
        NSDirectoryEnumerator* en = [fm enumeratorAtPath:tempPath];
        NSError *err = nil;
        BOOL eraseDidSucceed;
        
        // Recursively erase the efi folder.
        NSString *file;
        while (file = [en nextObject]) { // While there are files to remove...
            eraseDidSucceed = [fm removeItemAtPath:[tempPath stringByAppendingPathComponent:file] error:&err]; // Delete.
            
            NSAlert *alert = [[NSAlert alloc] init];
            
            if (!eraseDidSucceed && err) { // If there was an error...
                NSString *text = [NSString stringWithFormat:@"Error: %@", err];
                [alert addButtonWithTitle:@"Okay"];
                [alert setMessageText:@"Failed to erase live USB."];
                [alert setInformativeText:text];
                [alert setAlertStyle:NSWarningAlertStyle];
                [alert beginSheetModalForWindow:_window modalDelegate:self didEndSelector:@selector(regularAlertDidEnd:returnCode:contextInfo:) contextInfo:nil];
                NSLog(@"Could not delete: %@", err);
            } else {
                [alert addButtonWithTitle:@"Okay"];
                [alert setMessageText:@"Erase successful."];
                [alert setInformativeText:@"The live USB has been erased."];
                [alert setAlertStyle:NSWarningAlertStyle];
                [alert beginSheetModalForWindow:_window modalDelegate:self didEndSelector:@selector(regularAlertDidEnd:returnCode:contextInfo:) contextInfo:nil];
            }
        }
        
        [eraseUSBSelector setEnabled:YES];
    }
    
    [[NSApp delegate] setCanQuit:YES];
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

- (IBAction)openDownloadedDistro:(id)sender {
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"/Downloads/"];
    NSString *isoName = [[[NSURL URLWithString:urlArray[distroSelectorComboBox.indexOfSelectedItem]] path] lastPathComponent];
    path = [NSString stringWithFormat:@"%@/%@", path, isoName];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:nil];
    } else {
        // ISO file not downloaded yet?
        [self closeDownloadDistroSheet:sender];
        
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"Okay"];
        [alert setMessageText:@"File not found."];
        [alert setInformativeText:@"That distribution's ISO file was not found in your Downloads folder."];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert beginSheetModalForWindow:_window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
    }
}

- (IBAction)downloadDistribution:(id)sender {
    if (distroSelectorComboBox != nil && distroSelectorComboBox.indexOfSelectedItem != -1) {
        [self setCanQuit:NO]; // Prevent the user from quiting the application until the download has finished.
        
        [distroDownloadButton setEnabled:NO];
        [distroDownloadProgressIndicator startAnimation:self];
        [distroDownloadProgressIndicator setDoubleValue:0.0];
        
#ifdef DEBUG
        NSLog(@"URL: %@", [NSURL URLWithString:urlArray[distroSelectorComboBox.indexOfSelectedItem]]);
#endif
        NSURL *downloadLocation = [NSURL URLWithString:urlArray[distroSelectorComboBox.indexOfSelectedItem]];
        
        [[DistributionDownloader new] downloadLinuxDistribution:downloadLocation:
         [NSHomeDirectory() stringByAppendingPathComponent:@"/Downloads/"]:distroDownloadProgressIndicator];
        
        // The program calls the setCanQuit method in the download delegates. We don't call it here, as this function returns
        // immediately.
    } else {
        [self closeDownloadDistroSheet:sender];
        
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"Okay"];
        [alert setMessageText:@"No distribution selected."];
        [alert setInformativeText:@"Please select a distribution first before clicking the download button."];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert beginSheetModalForWindow:_window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
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

- (IBAction)openDiskUtility:(id)sender {
    [[NSWorkspace sharedWorkspace] launchApplication:@"/Applications/Utilities/Disk Utility.app"];
}

- (IBAction)updateRecents:(id)sender {
    NSArray *myArray = [[NSDocumentController sharedDocumentController] recentDocumentURLs];
    
    dataSource = [[RecentDocumentsTableViewDataSource new] init];
    [dataSource setArray:myArray];
    [recentFileBrowser setDataSource:dataSource];
}

- (IBAction)openCompatibilityTester:(id)sender {
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *helperAppPath = [[mainBundle bundlePath] stringByAppendingString:@"/Contents/Resources/Tools/Compatibility Tester.app"];
    
    [[NSWorkspace sharedWorkspace] launchApplication:helperAppPath];
}

- (IBAction)openGithubPage:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/SevenBits/Mac-Linux-USB-Loader"]];
}

- (IBAction)reportBug:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/SevenBits/Mac-Linux-USB-Loader/issues/new"]];
}

@end
