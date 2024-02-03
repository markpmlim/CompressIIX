//
//  ProgressViewController.m
//  QuickView
//
//  Created by mark lim on 7/12/16.
//  Copyright 2016 IncrementalInnovation. All rights reserved.
//

#import "AppDelegate.h"
#import "TaskViewController.h"
#import "TaskListView.h"

/*
 A view controller has access to its view
 */
@implementation TaskViewController
@synthesize action;
@synthesize message;
@synthesize progress;
@synthesize autoMode = operation;
@synthesize operationQue;
@synthesize isBarpole;
@synthesize isIndeterminate;

const double maxProgress = 100.0;
// This object needs to be sent a message to indicate the type of action.
- (id)initWithOperation:(BOOL)automatically
{
	//NSLog(@"TaskViewController");
	self = [super initWithNibName:@"TaskView"
						   bundle:nil];
	if (self != nil) {
		self.action = @"Change File Attributes...";
		[self setAutoMode:automatically];
		self.message = @"# of files being processed";
		operationQue = [[NSOperationQueue alloc] init];		// we own this so no self.
		[operationQue setMaxConcurrentOperationCount:1];	// use a serial queue first
	}
	return self;
}

// Not called when an instance of TaskView is removed from its parent
// view which is an instance of TaskListView
- (void)dealloc
{
	//NSLog(@"deallocating instance of TaskViewController:%@", self);
	if (operationQue != nil) {
		//NSLog(@"deallocating instance operation queue:%@", operationQue);
		[operationQue release];
	}
	[action release];
	[message release];
	[super dealloc];
}


- (void)awakeFromNib
{
	NSImage *stopImage = [NSImage imageNamed:NSImageNameStopProgressFreestandingTemplate];
	// "self" must be prepended to the instance variable "action" the statement below
	// since its value is bound to a UI label element.
	if (self.isAutoMode) {
		self.action = @"Changing File Attributes automatically...";
    }
	else {
		self.action = @"Changing File Attributes manually...";
    }
	[stopButton setImage:stopImage];
}

- (void)loadView
{
	//NSLog(@"loadView");
	[super loadView];
}

// not used currently
- (void)startTwirling
{
	NSLog(@"startTwirling");
	self.action = NSLocalizedString(@"Please wait...", @"Wait message");
	self.message = NSLocalizedString(@"Calculating...", @"Calculate message");
	self.isIndeterminate = YES;
	self.isBarpole = YES;
	[progressIndicator setUsesThreadedAnimation:YES];
	[progressIndicator startAnimation:self];
}

- (void)didUpdateTotalFileCount:(NSNumber *)count
{
	totalFileCount = [count unsignedLongLongValue];
}

- (void)didUpdateFileCount:(NSNumber *)count
{
	fileCount = [count unsignedLongLongValue];
	self.progress = maxProgress * ((double)fileCount) / ((double)totalFileCount);
	self.action = [NSString stringWithFormat:NSLocalizedString(@"Changing File Attributes of item %lld...", @"Copied message"),
				   fileCount];
	self.message = [NSString stringWithFormat:NSLocalizedString(@"%lld of %lld items processed", @"# of files done"),
					fileCount, totalFileCount];
}

- (void)didEndFileOperations
{
    self.progress = maxProgress;
    self.isIndeterminate = NO;
	self.action = [NSString stringWithFormat:NSLocalizedString(@"Finish processing %lld file(s)",
															   @"Finish message"),
				   totalFileCount];
    self.message =  NSLocalizedString(@"Changes to File Attributes Done...", @"Done message");
	//NSLog(@"didEndFileOperations: %@ %@", [self.view superview], self.view);
	TaskListView *taskListView = (TaskListView *)[self.view superview];
	[taskListView removeTaskView:(TaskView *)self.view];
}

// When the progress is stopped, we can remove the task view from its parent
// taskListView, release it. However, taskView is bound to its view controller in xib.
// When the view controller is (manually) released then the task view will be deallocated.
// This must be called on the main thread.
- (IBAction)cancelling:(id)sender
{
	//NSLog(@"cancelling");
	// When the view is removed from its superView and window, it is released as well.
	// By declaring an instance of its view controller in this view's interface, the view
	// controller gets to be released.
	[self.operationQue cancelAllOperations];
	//NSLog(@"%@", [self.view superview]);
	TaskListView *taskListView = (TaskListView *)[self.view superview];
	[taskListView removeTaskView:(TaskView *)self.view];
}
@end
