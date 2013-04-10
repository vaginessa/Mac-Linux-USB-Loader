//
//  RecentDocumentsTableViewDataSource.m
//  Mac Linux USB Loader
//
//  Created by Ryan Bowring on 4/10/13.
//
//

#import "RecentDocumentsTableViewDataSource.h"

@implementation RecentDocumentsTableViewDataSource

const NSArray *array;

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [array count];
}

- (id)tableView:(NSTableView *)tableView
objectValueForTableColumn:(NSTableColumn *)tableColumn
            row:(NSInteger)row {
    NSTableColumn *firstColoum = [tableView viewAtColumn:0 row:0 makeIfNecessary:NO];
    [tableColumn setEditable:NO];
    
    // Not working yet...
    if (YES) {
        return [[array objectAtIndex:row] lastPathComponent];
    } else if ([tableColumn isEqualTo:firstColoum]) {
        return [array objectAtIndex:row];
    } else {
        return @"(null)";
    }
}

- (void)setArray:(const NSArray *)myArray {
    array = myArray;
}

@end
