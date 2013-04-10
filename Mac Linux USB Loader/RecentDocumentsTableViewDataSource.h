//
//  RecentDocumentsTableViewDataSource.h
//  Mac Linux USB Loader
//
//  Created by Ryan Bowring on 4/10/13.
//
//

#import <Cocoa/Cocoa.h>

@interface RecentDocumentsTableViewDataSource : NSObject <NSTableViewDataSource>

- (void)setArray:(const NSArray *)myArray;

@end
