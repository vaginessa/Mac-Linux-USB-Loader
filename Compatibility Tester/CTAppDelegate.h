//
//  CTAppDelegate.h
//  Compatibility Tester
//
//  Created by SevenBits on 4/18/13.
//
//

#import <Cocoa/Cocoa.h>
#include <sys/types.h>
#include <sys/sysctl.h>

@interface CTAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSProgressIndicator *spinner;
@property (unsafe_unretained) IBOutlet NSTextView *textView;
@property (weak) IBOutlet NSTextField *label;

- (IBAction)refresh:(id)sender;
- (void)performSystemCheck;
- (void)findGraphicsCard:(NSTextStorage*)storage;

@end
