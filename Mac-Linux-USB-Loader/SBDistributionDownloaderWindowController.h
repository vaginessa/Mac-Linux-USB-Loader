//
//  SBDistributionDownloaderWindowController.h
//  Mac Linux USB Loader
//
//  Created by SevenBits on 5/9/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <JSONModel/JSONModel.h>
#import <JSONHTTPClient.h>
#import "SBDownloadableDistributionModel.h"

@interface SBDistributionDownloaderWindowController : NSWindowController <NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate>

@property (atomic, strong) id jsonRecieved;
@property NSInteger numberOfFinishedJsonRequests;
@property (atomic, strong) SBDownloadableDistributionModel *downloadDistroModel;
@property (atomic, strong) NSMutableDictionary *modelDictionary;
@property (strong) NSLock *mdLock;
@property (atomic, strong) NSMutableDictionary *imageDictionary;
@property (strong) NSLock *idLock;

@property (nonatomic, strong) NSOperationQueue *downloadQueue;
@property NSInteger numberOfActiveDownloadOperations;

- (IBAction)downloadDistroButtonPressed:(id)sender;
- (IBAction)closeDownloadDistroSheetPressed:(id)sender;
- (IBAction)commenceDownload:(id)sender;
- (IBAction)viewInProgressDownloads:(id)sender;

@end
