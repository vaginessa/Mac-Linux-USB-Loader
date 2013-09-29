//
//  main.m
//  mlul
//
//  Created by Ryan Bowring on 9/14/13.
//
//

#import <Foundation/Foundation.h>
#define VERSION "0.1"
#define error(message) fprintf(stderr, message)

/* Our global variables. */
char devicePath[100];
char hostPath[100] = "/Applications/Mac Linux USB Loader/Contents/Resources/";
char inputFile[100];

int haveInputFile = NO;

void usage() {
    printf("USAGE: mlul [options] inputs\n");
    printf("\n");
    printf("OPTIONS:\n");
    printf("\t--version\tDisplay program version number then exit.\n");
    printf("\t--help\t\tDisplay this help text then exit.\n");
    printf("\t--info\t\tDisplay information on included components then exit.\n");
    
    printf("INPUTS:\n");
    printf("\t--drive path\t(required) The path to the mounted volume to install to.\n");
    printf("\t--host path\t(optional) Specifies the directory where Mac Linux USB Loader installation files can be found.\n");
    
    printf("\n");
}

void version() {
    printf("Mac Linux USB Loader Command Line Installation Manager\n");
    printf("version %s\n", VERSION);
    
    printf("\n");
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // First, process command line arguments.
#ifdef DEBUG
        printf("Processing %i arguments...\n", argc);
#endif
        
        if (argc <= 1) {
            usage();
            return 1;
        }
        
        for (int i = 1; i < argc; i++) {
            // If it starts with the `-` character, it must be an option.
            if (argv[i][0] == '-') {
                // Handle singleton options first.
                if (strcmp(argv[i], "--help") == 0) {
                    usage();
                    return 0;
                } else if (strcmp(argv[i], "--version") == 0) {
                    version();
                    return 0;
                }
            
                // Read program inputs.
                if (strcmp(argv[i], "--drive") == 0) {
                    strcpy(devicePath, argv[++i]);
#ifdef DEBUG
                    printf("Setting mounted volume at %s as installation device.\n", devicePath);
#endif
                    continue;
                } else if (strcmp(argv[i], "--host") == 0) {
                    strcpy(hostPath, argv[++i]);
#ifdef DEBUG
                    printf("Setting mounted volume at %s as host path.\n", hostPath);
#endif
                    continue;
                } else {
                    printf("Unrecognized option %s.\n", argv[i]);
                }
            } else {
                // We have a standalone argument. Check if it's an argument to an option. If not, and
                // it stands alone, we'll assume that it's the file to process.
                if (argv[i - 1][0] != '-') {
                    if (!haveInputFile) {
                        strcpy(inputFile, argv[i]);
                        haveInputFile = YES;
#ifdef DEBUG
                        printf("Input file is %s.\n", inputFile);
#endif
                    } else {
                        printf("Warning: argument %s is extraneous.\n", argv[i]);
                    }
                }
            }
        }
        
        // Check if we ever got required parameters. If not, we show an error message and bail.
        if (strcmp(inputFile, "") == 0) {
            error("Error: no input file!\n");
            return 1;
        }
        
        if (strcmp(devicePath, "") == 0) {
            error("Error: no mounted drive to install to entered (specify with --drive)!\n");
            return 1;
        }
    }
    return 0;
}

