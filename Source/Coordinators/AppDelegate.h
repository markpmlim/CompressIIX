//
//  AppDelegate.h
//  CompressIIX
//
//  Created by mark lim on 7/11/16.
//  Copyright 2016 IncrementalInnovation. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include "UserDefines.h"

@class MainWindowController;
@class ProgressWindowController;

@interface AppDelegate : NSObject
{
	// Instance variables; these objects are instantiated in the
	// applicationDidFinishLaunching method.
    MainWindowController		*mainWinController;
    ProgressWindowController	*progressWinController;
	NSOperationQueue			*queue;
}

@property (retain) MainWindowController		*mainWinController;
@property (retain) ProgressWindowController	*progressWinController;
@property (retain) NSOperationQueue			*queue;

// Public methods
- (IBAction)openHelpFile:(id)sender;
- (IBAction)showLogs:(id)sender;
- (IBAction)clearLogs:(id)sender;
- (LZ4Format)identifyFormatWithFileData:(NSData *)fileContents;

// Internal methods
- (NSURL *)urlOfLogFile;

@end
