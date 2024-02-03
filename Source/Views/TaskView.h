//
//  TaskView.h
//  QuickView
//
//  Created by mark lim on 7/15/16.
//  Copyright 2016 IncrementalInnovation. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TaskViewController;

// The identity of File Owner is set as TaskViewController.
//  Remember to bind the property "viewController" to the
// instance of TaskView in TaskView.xib. 
@interface TaskView : NSView
{
   TaskViewController *_viewController;		// instance variable
}

// we need to access the instance var "_viewController" via this property.
@property (assign) IBOutlet TaskViewController *viewController;

@end
