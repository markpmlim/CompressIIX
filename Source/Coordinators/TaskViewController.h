//
//  ProgressViewController.h
//  QuickView
//
//  Created by mark lim on 7/12/16.
//  Copyright 2016 IncrementalInnovation. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*
 This object manages the actual UI elements. As such its methods must be
 called from the main thread
 */
@interface TaskViewController : NSViewController
{
 	NSString						*message;
    NSString						*action;
	IBOutlet NSProgressIndicator	*progressIndicator;
	IBOutlet NSButton				*stopButton;
	BOOL							operation;
    BOOL							isBarpole;			// show a twirling indicator 
    BOOL							isIndeterminate;	// YES=show a twirling indicator
    double							progress;
	unsigned long long				totalFileCount;
	unsigned long long				fileCount;
	NSOperationQueue				*operationQue;
}

@property (assign,getter=isAutoMode,setter=setAutoMode:) BOOL autoMode;
// The following objects are bound to Labels in xib file
@property (retain) NSString				*message;
@property (retain) NSString				*action;
@property (retain) NSOperationQueue		*operationQue;;
@property (assign) double				progress;;
@property (assign) BOOL					isBarpole;;
@property (assign) BOOL					isIndeterminate;;

- (id)initWithOperation:(BOOL)inflating;

- (void)startTwirling;

- (void)didUpdateTotalFileCount:(NSNumber *)count;

- (void)didUpdateFileCount:(NSNumber *)count;

- (void)didEndFileOperations;

- (IBAction)cancelling:(id)sender;

@end
