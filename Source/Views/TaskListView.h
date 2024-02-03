//
//  TaskListView.h
//  QuickView
//
//  Created by mark lim on 7/13/16.
//  Copyright 2016 IncrementalInnovation. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TaskView;
// This is the container (superview) view of instances of TaskView
// and is created as a sub-view of the window content.
// This UI is not managed by an NSViewController but by the ProgressWindowController.
@interface TaskListView : NSView
{
	float	totalHeight;
	SEL		resizeAction;
	id		resizeTarget;
}

// No properties are declared

- (void)addTaskView:(TaskView *)taskview;

- (void)removeTaskView:(TaskView *)taskview;

- (void)setResizeAction:(SEL)action
                 target:(id)target;

- (NSSize) preferredSize;

@end
