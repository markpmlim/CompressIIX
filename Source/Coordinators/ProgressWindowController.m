//
//  ProgressDialog.m
//  QuickView
//
//  Created by mark lim on 7/11/16.
//  Copyright 2016 IncrementalInnovation. All rights reserved.
//

#import "ProgressWindowController.h"
#import "TaskViewController.h"
#import "TaskListView.h"
#import "TaskView.h"
#import "AppDelegate.h"

/*
 A window controller has access to its instance of NSWindow and vice-versa.
 */
@implementation ProgressWindowController

- (id)initWithWindow:(NSWindow *)window
{
	//NSLog(@"ProgressWindowController");
	self = [super initWithWindow:window];
	if (self) {
		taskViewCtlrs = [[NSMutableArray alloc] initWithCapacity:1];
	}
	return self;
}

- (void)dealloc
{
	if (taskViewCtlrs != nil)
    {
		[taskViewCtlrs release];
		taskViewCtlrs = nil;
	}
	[super dealloc];
}


- (void)awakeFromNib {
	[[self window] setReleasedWhenClosed:NO];	// don't release window's allocated resources
	// Ensures taskListView will call back whenever the window needs to be
	// resized; this object which is a sub-class of NSWindowController.
	[taskListView setResizeAction:@selector(resizeWindow:)
					   target:self];

}

// For progress window, we may start off with no taskviews.
// There is always a taskListView which is the container of taskviews
- (void)loadWindow {
	//NSLog(@"loadWindow");
	[super loadWindow];
}

- (void)windowDidLoad 
{
	//NSLog(@"windowDidLoad");
}

// Should we move this method of the class TaskListView?
// taskListView must not be nil. To ensure that we force the progress
// window controller to load the window and hide it - ref AppDelegate
- (void)addSubview:(TaskView *)childView 
{
	[taskListView addTaskView:childView];
}

// KIV: removeTaskView instead of removeTaskViewController
// Search for the instance of TaskViewController and remove it from
// the mutable array.
- (void)removeTaskViewController:(TaskViewController *)tvc 
{
	NSEnumerator *en =  [taskViewCtlrs objectEnumerator];
	TaskViewController *vc = nil;
    // Brute-force method to search for the task view controller.
	while (vc = [en nextObject]) {
		if (vc == tvc) {
			break;
		}
	} // while

	if (vc != nil) 	{
		//NSLog(@"removing taskViewController");
		// looks like tvc is not only released by the instruction below
		// but its associate taskView is also deallocated as well. 
		[taskViewCtlrs removeObject:vc];
		//[vc release];				// will crash if executed!
	}
}


// This method should be called by an instance of TaskListView
// (a sub-class of NSView) whenever its size changes.
// Sender can be any object; in this application it happens to be
// an instance of TaskListView
- (void)resizeWindow:(id)sender
{
	//NSLog(@"resizeWindow:%@", sender);
	NSSize size = [taskListView preferredSize];
	if (size.height == 0) {
		return;
    }
	NSWindow *progWin = [self window];
	NSRect frame = [progWin contentRectForFrameRect:[progWin frame]];

	NSRect newframe = [progWin frameRectForContentRect:NSMakeRect(frame.origin.x, frame.origin.y+frame.size.height-size.height,
																  size.width, size.height)];
	[progWin setMinSize:NSMakeSize(316, newframe.size.height)];
	[progWin setMaxSize:NSMakeSize(100000, newframe.size.height)];
	[progWin setFrame:newframe
			  display:YES
			  animate:NO];
/*
	NSEnumerator *enumerator = [[taskListView subviews] reverseObjectEnumerator];
	NSView *subview;
	while (subview = [enumerator nextObject])
	{
		NSLog(@"%f, %f %f %f",
			  [subview frame].origin.x, [subview frame].origin.y,
			  [subview frame].size.width, [subview frame].size.height);
	}
*/
}


@end
