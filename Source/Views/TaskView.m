//
//  TaskView.m
//  QuickView
//
//  Created by mark lim on 7/15/16.
//  Copyright 2016 IncrementalInnovation. All rights reserved.
//

#import "TaskView.h"

/*
 An instance of NSView has accessed to its instance of NSWindow.
 But it cannot directly access its instance of NSViewController
 */

@implementation TaskView

@synthesize viewController = _viewController;

- (id)initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];
	if (self) {
		// This is called.
	}
	return self;
}

// This method should be called when an instance of TaskView is released.
// This is supposed to happen when it is removed from its super view which is
// TaskListView.
// Maybe we have to deallocate the instance of TaskViewController manually.
- (void)dealloc
{
	//NSLog(@"deallocating instance of TaskView");
	// We don't own the instance var  "_viewController"
	//NSLog(@"%@", _viewController);
	[super dealloc];
}

/* This confirms that _viewController had been instantiated by the xib code.
- (void) awakeFromNib
{
	NSLog(@"awakeFromNib %@", _viewController);

}
 */

- (void)drawRect:(NSRect)dirtyRect {
    // Drawing code here.
	[super drawRect:dirtyRect];
}

@end
