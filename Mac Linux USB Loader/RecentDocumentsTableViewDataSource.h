//
//  RecentDocumentsTableViewDataSource.h
//  Mac Linux USB Loader
//
//  Created by SevenBits on 4/10/13.
//
//

#import <Cocoa/Cocoa.h>

@interface RecentDocumentsTableViewDataSource : NSObject <NSTableViewDataSource>

- (void)setArray:(const NSArray *)myArray;

@end
