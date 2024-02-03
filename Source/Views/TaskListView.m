//
//  TaskListView.m
//  QuickView
//
//  Created by mark lim on 7/13/16.
//  Copyright 2016 IncrementalInnovation. All rights reserved.
//

#import "TaskListView.h"
#import "TaskView.h"
#import "ProgressWindowController.h"

/*
 An instance of NSView has accessed to its instance of NSWindow.
 But it cannot directly access its instance of NSViewController
 */
@implementation TaskListView

- (id)initWithFrame:(NSRect)frame 
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		resizeTarget = nil;
		totalHeight = -1;
		[self setAutoresizesSubviews:YES];
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    // Drawing code here.
	[super drawRect:dirtyRect];
}

- (void)dealloc
{
	if (resizeTarget != nil) {
		[resizeTarget release];
        resizeTarget = nil;
    }
	[super dealloc];
}

// There is a bug here the width of the subview seems to be increasing.
// Resolved!
- (void)_layoutSubviews
{
	NSEnumerator *enumerator;
	NSView *subview;

	float oldheight = totalHeight;
	
	totalHeight = 0;
	enumerator = [[self subviews] reverseObjectEnumerator];
	while ((subview = [enumerator nextObject])) {
		totalHeight += [subview frame].size.height +1;
    }

	if (totalHeight) {
		totalHeight -= 1;
    }

	NSRect listFrame = [self frame];
	float y = listFrame.size.height - totalHeight;

	enumerator = [[self subviews] reverseObjectEnumerator];
	while ((subview = [enumerator nextObject])) {
		NSRect frame = [subview frame];

		frame.origin.x = 0;
		frame.origin.y = y;
		frame.size.width = listFrame.size.width;

		[subview setFrame:frame];

		y += frame.size.height +1;
	}

	if (oldheight != totalHeight) {
		// `resizeAction` is a method of the class `resizeTarget` belongs to
		// which takes a single argument of type id
		[resizeTarget performSelector:resizeAction
						   withObject:self];
	}
}

// Called by an instance of ProgressWindowController
-(void) addTaskView:(TaskView *)taskView
{
	[taskView setAutoresizingMask:NSViewWidthSizable|NSViewMinYMargin];
	[self addSubview:taskView];
	[self _layoutSubviews];
}

// cascade upwards to ProgressWindowController
- (void)removeTaskView:(TaskView *)taskView
{
	// This should trigger taskView's dealloc method since it is released.
	[taskView retain];
	[taskView removeFromSuperview];
	[self _layoutSubviews];
	ProgressWindowController *winCtlr = (ProgressWindowController *)[[self window] windowController];
	TaskViewController *tvc = [taskView viewController];
	[winCtlr removeTaskViewController:tvc];
	[taskView release];

	if ([[self subviews] count] == 0) {
		[[self window] orderOut:self];
	}
}
// Called by the awakeFromNib method of ProgressWindowController which passes
// a selector (method) and an instance of ProgressWindowController (self).
// Actually, target can be an object of any class and selector can be the
// name of any method of that class.
- (void)setResizeAction:(SEL)action
                 target:(id)target
{
	resizeAction = action;
	[resizeTarget autorelease];
	resizeTarget = [target retain];

}

- (NSSize)preferredSize
{
	return NSMakeSize([self frame].size.width, totalHeight);
}
@end
