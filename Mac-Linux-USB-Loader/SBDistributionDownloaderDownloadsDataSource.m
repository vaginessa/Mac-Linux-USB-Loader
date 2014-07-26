//
//  SBDistributionDownloaderDownloadsDataSource.m
//  Mac Linux USB Loader
//
//  Created by SevenBits on 7/25/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import "SBDistributionDownloaderDownloadsDataSource.h"
#import "SBDistributionDownloaderTableCellView.h"
#import "DownloadOperation.h"

@implementation SBDistributionDownloaderDownloadsDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return self.prefsViewController.numberOfActiveDownloadOperations;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	NSOperationQueue *queue = self.prefsViewController.downloadQueue;
	DownloadOperation *downloadOperation = queue.operations[row];

	SBDistributionDownloaderTableCellView *result = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
	[result.nameLabel setStringValue:[[downloadOperation.path lastPathComponent] stringByDeletingPathExtension]];
	return result;
}

@end
