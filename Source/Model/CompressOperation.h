//
//  CompressOperation.h
//  CompressIIX
//
//  Created by mark lim on 7/10/16.
//  Copyright 2016 IncrementalInnovation. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MainWindowController;

@interface CompressOperation : NSOperation
{
    BOOL					_finished;			// instance variables are
    BOOL					_executing;			// declared within the 2 braces
	NSURL					*_srcURL;
	MainWindowController	*_delegate;         // Set manually. Currently unused.
}

@property (readwrite) BOOL				finished;
@property (readwrite) BOOL				executing;
@property (readwrite, retain) NSURL     *srcURL;
@property (retain) MainWindowController *delegate;

- (id)initWithURL:(NSURL *)url;

@end
