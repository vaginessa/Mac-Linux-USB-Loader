//
//  DistributionDownloader.m
//  Mac Linux USB Loader
//
//  Created by SevenBits on 1/14/13.
//  Copyright (c) 2013 SevenBits. All rights reserved.
//

#import "DistributionDownloader.h"

@implementation DistributionDownloader

NSURLDownload *download;
NSString *destinationPath;

- (void)downloadLinuxDistribution:(NSURL*)url:(NSString*)destination {
    destinationPath = destination;
    NSURLRequest *request=[NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    // create the connection with the request
    // and start loading the data
    [download setDestination:destination allowOverwrite:NO];
    download=[[NSURLDownload alloc] initWithRequest:request delegate:self];
    if (!download) {
        NSLog(@"Download could not be made...");
    }
}

#pragma mark NSURLDownload delegates
- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error
{
    // Inform us that the download failed.
    NSLog(@"Download failed! Error - %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"Okay"];
    [alert setMessageText:@"Download failed."];
    [alert setInformativeText:@"Check the system logs for more information."];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert beginSheetModalForWindow:nil modalDelegate:self didEndSelector:@selector(regularAlertDidEnd:returnCode:contextInfo:) contextInfo:nil];
    
    // Show a notification.
    NSProcessInfo *pinfo = [NSProcessInfo processInfo];
    NSArray *myarr = [[pinfo operatingSystemVersionString] componentsSeparatedByString:@" "];
    NSString *version = [myarr objectAtIndex:1];
    
    // Ensure that we are running 10.8 before we display the notification as we still support Lion, which does not have
    // them.
    if ([version rangeOfString:@"10.8"].location != NSNotFound) {
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = @"File Download Failure";
        notification.informativeText = @"Could not download the file.";
        notification.soundName = NSUserNotificationDefaultSoundName;
        
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    }
}

- (void)download:(NSURLDownload *)download decideDestinationWithSuggestedFilename:(NSString *)filename {
    NSString *destinationFilename;
    NSString *homeDirectory=NSHomeDirectory();
    
    destinationFilename=[[homeDirectory stringByAppendingPathComponent:@"Desktop"] stringByAppendingPathComponent:filename];
    [download setDestination:destinationFilename allowOverwrite:YES];
}

- (void)downloadDidFinish:(NSURLDownload *)download
{
    // Do something with the data.
    NSLog(@"Downloaded file was downloaded:\n%@", download);
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"Okay"];
    [alert setMessageText:@"Download complete."];
    [alert setInformativeText:@"The file was downloaded."];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert beginSheetModalForWindow:nil modalDelegate:self didEndSelector:@selector(regularAlertDidEnd:returnCode:contextInfo:) contextInfo:nil];
    
    // Show a notification.
    NSProcessInfo *pinfo = [NSProcessInfo processInfo];
    NSArray *myarr = [[pinfo operatingSystemVersionString] componentsSeparatedByString:@" "];
    NSString *version = [myarr objectAtIndex:1];
    
    // Ensure that we are running 10.8 before we display the notification as we still support Lion, which does not have
    // them.
    if ([version rangeOfString:@"10.8"].location != NSNotFound) {
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = @"File Download Complete";
        notification.informativeText = @"The ISO was successfully downloaded.";
        notification.soundName = NSUserNotificationDefaultSoundName;
        
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    }
}

#pragma mark NSAlert delegates
- (void)regularAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    // Do nothing.
}

@end
