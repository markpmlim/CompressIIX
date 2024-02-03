//
//  DropView.h
//  CompressIIX
//
//  Created by mark lim on 7/11/16.
//  Copyright 2016 IncrementalInnovation. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DropView : NSView
{
	NSAttributedString *_string;
}

@property(retain) NSAttributedString *string;

@end
