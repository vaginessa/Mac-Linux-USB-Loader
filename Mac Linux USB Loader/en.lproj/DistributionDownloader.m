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

- (void)downloadLinuxDistribution:(NSURL*)url:(NSString*)destination {
    download = [[NSURLDownload alloc] initWithRequest:[NSURLRequest requestWithURL:url] delegate:self];
    
    if (download) {
        // Download the file.
        [download setDestination:destination allowOverwrite:YES];
    } else {
        // Something went wrong. Bad Internet connection?
    }
}

#pragma mark NSURLDownload delegates
- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error
{
    // Inform the user.
    NSLog(@"Download failed! Error - %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
}

- (void)downloadDidFinish:(NSURLDownload *)download
{
    // Do something with the data.
    NSLog(@"%@",@"downloadDidFinish");
}

@end
