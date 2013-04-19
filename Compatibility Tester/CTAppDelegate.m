//
//  CTAppDelegate.m
//  Compatibility Tester
//
//  Created by SevenBits on 4/18/13.
//
//

#import "CTAppDelegate.h"

@implementation CTAppDelegate

@synthesize window;
@synthesize spinner;
@synthesize textView;

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    [spinner startAnimation:self];
    [self performSelector:@selector(performSystemCheck)];
}

- (void)performSystemCheck {
    NSTextStorage *storage = [textView textStorage];
    [storage beginEditing];
    
    size_t len = 0;
    sysctlbyname("hw.model", NULL, &len, NULL, 0);
    
    if (len)
    {
        char *model = malloc(len*sizeof(char));
        sysctlbyname("hw.model", model, &len, NULL, 0);
        NSString *model_ns = [NSString stringWithUTF8String:model];
        free(model);
        
        NSAttributedString *string = [[NSAttributedString alloc]
                                      initWithString:[NSString stringWithFormat:@"Computer Model: %@\n", model_ns]];
        [storage appendAttributedString:string];
    }
    
    [storage endEditing];
    [spinner stopAnimation:self];
}

@end
