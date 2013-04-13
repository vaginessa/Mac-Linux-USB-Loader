//
//  RecentDocumentsTableViewDataSource.m
//  Mac Linux USB Loader
//
//  Created by SevenBits on 4/10/13.
//
//

#import "RecentDocumentsTableViewDataSource.h"

@implementation RecentDocumentsTableViewDataSource

const NSArray *array;

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [array count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    [tableColumn setEditable:NO];
    return [[array objectAtIndex:row] lastPathComponent];
}

- (void)setArray:(const NSArray *)myArray {
    array = myArray;
}

@end
