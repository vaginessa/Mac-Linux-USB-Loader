//
//  SBDistributionDownloaderDownloadsDataSource.m
//  Mac Linux USB Loader
//
//  Created by SevenBits on 7/25/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import "SBDistributionDownloaderDownloadsDataSource.h"
#import "SBDistributionDownloaderTableCellView.h"

@implementation SBDistributionDownloaderDownloadsDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return self.prefsViewController.numberOfActiveDownloadOperations;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	SBDistributionDownloaderTableCellView *result = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
	result.nameLabel.stringValue = @"";
	return result;
}

@end
