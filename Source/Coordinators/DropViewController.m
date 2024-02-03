//
//  DropView.m
//  CompressIIX
//
//  Created by mark lim on 7/11/16.
//  Copyright 2016 IncrementalInnovation. All rights reserved.
//

#import "DropViewController.h"

@implementation DropViewController
- (id)init
{
	//NSLog(@"DropViewController");
    self = [super initWithNibName:@"DropView"
						   bundle:nil];
    return self;
}

- (void)dealloc
{
	[super dealloc];
}

- (void)loadView
{
	//printf("load drop view\n");
	[super loadView];
	NSArray *draggedTypes = [NSArray arrayWithObjects:
								 NSFilenamesPboardType,			// Drag from Finder
								 nil];

	// View controllers have an built-in outlet for their managed view.
	[self.view registerForDraggedTypes:draggedTypes];
}

@end
