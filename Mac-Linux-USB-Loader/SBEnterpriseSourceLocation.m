//
//  SBEnterpriseSourceLocation.m
//  Mac Linux USB Loader
//
//  Created by SevenBits on 2/15/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import "SBEnterpriseSourceLocation.h"
#import "SBGlobals.h"

@implementation SBEnterpriseSourceLocation

- (id)initWithName:(NSString *)name andPath:(NSString *)path shouldBeVolatile:(BOOL)deletable {
	self = [super init];
    if (self) {
		// Add your subclass-specific initialization here.
		self.name = name;
		self.path = path;
		self.deletable = deletable;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.name = [decoder decodeObjectForKey:@"name"];
	self.path = [decoder decodeObjectForKey:@"path"];
	self.securityScopedBookmark = [decoder decodeObjectForKey:@"bookmark"];
	self.deletable = [decoder decodeBoolForKey:@"deletable"];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.name forKey:@"name"];
	[encoder encodeObject:self.path forKey:@"path"];
	[encoder encodeObject:self.securityScopedBookmark forKey:@"bookmark"];
	[encoder encodeBool:self.deletable forKey:@"deletable"];
}

- (NSString *)description {
	return [NSString stringWithFormat: @"Name:'%@' Path:'%@' Bookmark:%@ Deletable:%@", self.name, self.path, self.securityScopedBookmark, SBBool2NSString(self.deletable)];
}

@end
