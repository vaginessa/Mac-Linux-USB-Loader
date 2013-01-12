//
//  main.m
//  Mac Linux USB Loader
//
//  Created by SevenBits on 11/16/12.
//  Copyright (c) 2012 SevenBits. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ApplicationPreferences.h"

int main(int argc, char *argv[])
{
    [ApplicationPreferences new];
    return NSApplicationMain(argc, (const char **)argv);
}