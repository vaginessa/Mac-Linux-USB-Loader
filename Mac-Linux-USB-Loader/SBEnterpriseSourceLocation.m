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

- (id)initWithName:(NSString *)name withPath:(NSString *)path withVersionNumber:(NSString *)version withSecurityScopedBookmark:(NSURL *)bookmark shouldBeVolatile:(BOOL)deletable {
	self = [super init];
    if (self) {
		// Add your subclass-specific initialization here.
		self.name = name;
		self.path = path;
		self.version = version;
		self.securityScopedBookmark = bookmark;
		self.deletable = deletable;
    }
    return self;
}

- (id)initWithName:(NSString *)name andPath:(NSString *)path shouldBeVolatile:(BOOL)deletable {
	self = [self initWithName:name withPath:path withVersionNumber:SBBundledEnterpriseVersionNumber withSecurityScopedBookmark:nil shouldBeVolatile:deletable];
    if (self) {
		// Add your subclass-specific initialization here.
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
	self.version = [decoder decodeObjectForKey:@"version"];
	self.securityScopedBookmark = [decoder decodeObjectForKey:@"bookmark"];
	self.deletable = [decoder decodeBoolForKey:@"deletable"];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.name forKey:@"name"];
	[encoder encodeObject:self.path forKey:@"path"];
	[encoder encodeObject:self.version forKey:@"version"];
	[encoder encodeObject:self.securityScopedBookmark forKey:@"bookmark"];
	[encoder encodeBool:self.deletable forKey:@"deletable"];
}

- (NSString *)description {
	return [NSString stringWithFormat: @"Name:'%@' Path:'%@' Version:'%@' Bookmark:%@ Deletable:%@", self.name, self.path, self.version, self.securityScopedBookmark, SBBool2NSString(self.deletable)];
}

@end
