//
//  SBSelectableCollectionView.m
//  Mac Linux USB Loader
//
//  Created by SevenBits on 3/20/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import "SBSelectableCollectionView.h"

@implementation SBSelectableCollectionView

- (id)initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		// Initialization code here.
	}
	return self;
}

- (void)drawRect:(NSRect)dirtyRect {
	[super drawRect:dirtyRect];

	if (self.selected) {
		[[NSColor alternateSelectedControlColor] set];
		NSRectFill([self bounds]);
	}
}

@end
