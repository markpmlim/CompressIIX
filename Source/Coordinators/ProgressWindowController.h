//
//  ProgressDialog.h
//  QuickView
//
//  Created by mark lim on 7/11/16.
//  Copyright 2016 IncrementalInnovation. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TaskView;
@class TaskListView;
@class TaskViewController;
// KIV: use an NSMapTable instead of NSMutableArray for taskViewCtlrs
/*
 The associated window object is actually an NSPanel (sub-class of NSWindow)
 This object will manage the various UI elements via a hierarchy.

 window
 |
  --- taskListView
	  |
	   --- taskView
		   |
		    ---- progress indicator, stop button etc.
 */
@interface ProgressWindowController : NSWindowController
{
//	IBOutlet NSPanel			*panel;
	IBOutlet TaskListView		*taskListView;	// container view
	NSMutableArray				*taskViewCtlrs;	// list of taskViewController
	
}

- (void)addSubview:(TaskView *)childView;
- (void)removeTaskViewController:(TaskViewController *)tvc;
@end
