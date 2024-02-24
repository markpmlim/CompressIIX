//
//  DecompressOperation.h
//  CompressIIX
//
//  Created by mark lim on 7/10/16.
//  Copyright 2016 IncrementalInnovation. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MainWindowController;
@interface DecompressOperation : NSOperation
{
    BOOL					finished;
    BOOL					executing;
	NSURL					*_srcURL;
	MainWindowController	*_delegate; // not used!
}

@property (readwrite) BOOL              finished;
@property (readwrite) BOOL              executing;
@property (readwrite, retain) NSURL     *srcURL;
@property (retain) MainWindowController *delegate;

- (id)initWithURL:(NSURL *)url;

@end
