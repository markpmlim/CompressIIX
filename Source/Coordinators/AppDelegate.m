//
//  AppDelegate.m
//  CompressIIX
//
//  Created by mark lim on 7/11/16.
//  Copyright 2016 IncrementalInnovation. All rights reserved.
//

#import "AppDelegate.h"
#import "MainWindowController.h"
//#import "ProgressWindowController.h"
//#import "TaskViewController.h"
//#import "TaskView.h"
#import "DecompressOperation.h"

@implementation AppDelegate
@synthesize mainWinController;
@synthesize progressWinController;
@synthesize queue;

FILE *logFilePtr = NULL;

- (id)init
{
	//NSLog(@"min version:%d", __MAC_OS_X_VERSION_MIN_REQUIRED);
	if (NSAppKitVersionNumber < 949) 
    {
		// Pop up a warning dialog, 
		NSRunAlertPanel(@"Sorry, this program requires Mac OS X 10.5 or later", @"You are running %@", 
						@"OK", nil, nil, [[NSProcessInfo processInfo] operatingSystemVersionString]);
		
		// then quit the program
		[NSApp terminate:self]; 
		
	}
	self = [super init];
	if (self != nil)
    {
		queue = [[NSOperationQueue alloc] init];        // we own this
		NSInteger maxCount = [queue maxConcurrentOperationCount];
		[queue setMaxConcurrentOperationCount:maxCount];
	}
	return self;
}

// Not guaranteed to be called on exit.
- (void)dealloc
{
	if (queue != nil) 
    {
		[queue release];
		queue = nil;
	}
	if (progressWinController != nil) 
    {
		[progressWinController release];
		progressWinController = nil;
	}
	if (mainWinController != nil)
    {
		[mainWinController release];
		mainWinController = nil;
	}
	[super dealloc];
}

// Returns the url to CompressAppleIIGraphics's console log file.
// It will create the folder /Users/marklim/Library/"Application Support"/CompressIIX
// if it does not exists.
- (NSURL *)urlOfLogFile
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,
														 NSUserDomainMask,
														 YES);
	NSString *basePath = [paths objectAtIndex:0];
	NSString *logFolder = [basePath stringByAppendingString:@"/CompressIIX"];
	NSFileManager *fmgr = [NSFileManager defaultManager];
	BOOL isDir = NO;
	// If the path has a trailing slash, the call below will return NO 
	// irrespective of whether or not there is a regular file at the location.
	BOOL exists = [fmgr fileExistsAtPath:logFolder
							 isDirectory:&isDir];
	if (exists == YES && isDir == NO) 
    {
		NSString *message = [NSString localizedStringWithFormat:@"A file (not folder) with the name \"NuShrinkItX\" exists at the location\n%@.", basePath];
		NSAlert *alert = [NSAlert alertWithMessageText:message
										 defaultButton:@"OK"
									   alternateButton:nil
										   otherButton:nil
							 informativeTextWithFormat:@"All messages will be send to the system log."];
		[alert runModal];
		logFilePtr = NULL;
		return nil;
	}
	else if (!exists)
    {
		//NSLog(@"Creating the Application Support folder: %@", logFolder);
		NSError *outErr = nil;
		if ([fmgr createDirectoryAtPath:logFolder
			withIntermediateDirectories:YES
							 attributes:nil
								  error:&outErr] == NO)
        {
			NSString *message = [NSString localizedStringWithFormat:@"Creating the folder %@\n failed", logFolder];
			NSAlert *alert = [NSAlert alertWithMessageText:message
											 defaultButton:@"OK"
										   alternateButton:nil
											   otherButton:nil
								 informativeTextWithFormat:@"All messages will be send to the system log."];
			[alert runModal];
			logFilePtr = NULL;
			return nil;
		}
	}

	// If we get here, the folder "CompressIIX" already exists or is newly-created.
	NSString *logPath = [logFolder stringByAppendingString:@"/messages.log"];
	NSURL *urlLog = [NSURL fileURLWithPath:logPath];
	return urlLog;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Insert code here to initialize your application 
	self.mainWinController = [[[MainWindowController alloc] initWithWindowNibName:@"MainWindow"] autorelease];
	[self.mainWinController showWindow:nil];
    // Currently there is no progress window.
	//self.progressWinController = [[[ProgressWindowController alloc] initWithWindowNibName:@"ProgressPanel"] autorelease];

	// This will force the progress window to load.
	//[self.progressWinController window];
	//[[self.progressWinController window] orderOut:nil];

	NSURL *logURL = [self urlOfLogFile];
	if (logURL != nil)
    {
		logFilePtr = freopen([logURL.path fileSystemRepresentation], "a+", stderr);

		if (logFilePtr == NULL) 
        {	// Put up an alert here?
			NSLog(@"Could not open the console log file. All messages will be sent to system log.");
		}
	}

/*
	[self.progressWinController showWindow:nil];
	// These should be moved somewhere since they must be released either
	// when the compress/decompress operations have finished or are cancelled.
	TaskViewController *prog1 = [[TaskViewController alloc] initWithOperation:YES];
	[self.progressWinController addSubview:(TaskView *)[prog1 view]];
	TaskViewController *prog2 = [[TaskViewController alloc] initWithOperation:NO];
	[self.progressWinController addSubview:(TaskView *)[prog2 view]];
	TaskViewController *prog3 = [[TaskViewController alloc] initWithOperation:YES];
	[self.progressWinController addSubview:(TaskView *)[prog3 view]];
*/
}


- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return YES;
}

- (void)applicationWillTerminate:(NSNotification *)note
{
	//printf("applicationWillTerminate\n");
	if (logFilePtr != NULL)
    {
		fclose(logFilePtr);
	}
}


- (IBAction)showLogs:(id)sender
{
	//printf("show logs\n");
	if (logFilePtr != NULL)
    {
		fflush(logFilePtr);
		NSURL *consoleURL = [self urlOfLogFile];
		NSString *logFilePath = consoleURL.path;
		// We assume nobody gets funny and remove the log file while
		// the program is executing.
		[[NSWorkspace sharedWorkspace] openFile:logFilePath
								withApplication:@"Console.app"];
	}
}

- (IBAction)clearLogs:(id)sender
{
	//printf("remove logs\n");
	if (logFilePtr != NULL) 
    {
		fflush(logFilePtr);
		rewind(logFilePtr);
		ftruncate(fileno(logFilePtr), 0);
	}
}
/*
 Magic Number at offset 0:
 Apple: 0x31 34 76 62 (4 bytes)
		trailing magic # at offset (EOF-4)
 Brutal Deluxe: 0x184c2103 (4 bytes)
 Fadden: 0x66 (1 byte)
 */
- (LZ4Format)identifyFormatWithFileData:(NSData *)fileContents
{
	LZ4Format format = kGenericLZ4;
	
	unsigned char brutalMagic[] = {0x03, 0x21, 0x4c, 0x18};
	unsigned char appleMagic1[] = {0x62, 0x76, 0x34, 0x31};
	unsigned char appleMagic2[] = {0x62, 0x76, 0x34, 0x24};
	NSData *brutalSignature = [NSData dataWithBytes:brutalMagic
											 length:4];
	NSData *appleSignature1 = [NSData dataWithBytes:appleMagic1
											 length:4];
	NSData *appleSignature2 = [NSData dataWithBytes:appleMagic2
											 length:4];
	unsigned char buf4[4];
	[fileContents getBytes:buf4
					length:4];
	NSData *leadinSignature = [NSData dataWithBytes:buf4
											 length:4];
	NSRange range = NSMakeRange(fileContents.length-4, 4);
	NSData *trailingSignature = [fileContents subdataWithRange:range];
	
	if (buf4[0] == 0x66)
    {
		//NSLog(@"Fadden");
		format = kFHPackLZ4;
	}
	else {
		if ([leadinSignature isEqualToData:brutalSignature])
        {
			//NSLog(@"brutal");
			format = kBrutalDeluxeLZ4;
		}
		else if ([leadinSignature isEqualToData:appleSignature1] &&
				 [trailingSignature isEqualToData:appleSignature2])
        {
			//NSLog(@"Apple");
			format = kAppleLZ4;
		}
		
	}
	return format;
}

/*
 Handles double-click on files with LZ4, LZ4FH, PAK extensions.
 */
- (void)application:(NSApplication *)sender
          openFiles:(NSArray *)filenames
{
	for (NSString *name in filenames) 
    {
		NSURL *url = [NSURL fileURLWithPath:name];
		DecompressOperation *op = [[DecompressOperation alloc] initWithURL:url];
        op.delegate = self.mainWinController;

		[op addObserver:(id)self.mainWinController
			 forKeyPath:@"isFinished"
				options:0	// It just changes state once, so don't
							// worry about what's in the notification
				context:NULL];

		// Watch for when this operation starts executing, so we can update
		// the user interface.
		[op addObserver:(id)self.mainWinController
			 forKeyPath:@"isExecuting"
				options:NSKeyValueObservingOptionNew
				context:NULL];

		[[self queue] addOperation:op];
		[op release];
	}

}

- (IBAction)openHelpFile:(id)sender
{
	NSString *fullPathname;
	fullPathname = [[NSBundle mainBundle] pathForResource:@"Documentation"
												   ofType:@"rtfd"];
	[[NSWorkspace sharedWorkspace] openFile:fullPathname];
}

@end
