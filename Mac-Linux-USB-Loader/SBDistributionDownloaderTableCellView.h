//
//  SBDistributionDownloaderTableCellView.h
//  Mac Linux USB Loader
//
//  Created by SevenBits on 7/25/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SBDistributionDownloaderTableCellView : NSTableCellView

@property (assign) IBOutlet NSProgressIndicator *progressBar;
@property (assign) IBOutlet NSTextField *nameLabel;
@property (assign) IBOutlet NSButton *revealButton;
@property (assign) IBOutlet NSButton *deleteButton;

@end
