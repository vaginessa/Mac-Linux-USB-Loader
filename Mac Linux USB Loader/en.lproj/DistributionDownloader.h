//
//  DistributionDownloader.h
//  Mac Linux USB Loader
//
//  Created by SevenBits on 1/14/13.
//  Copyright (c) 2013 SevenBits. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DistributionDownloader : NSViewController <NSURLDownloadDelegate>

- (void)downloadLinuxDistribution:(NSURL*)url:(NSString*)destination;

@end