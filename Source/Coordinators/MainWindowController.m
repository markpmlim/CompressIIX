//
//  MainWindowController.m
//  CompressIIX
//
//  Created by mark lim on 7/11/16.
//  Copyright 2016 IncrementalInnovation. All rights reserved.
//

#import "MainWindowController.h"
#import "DropViewController.h"
#import "CompressOperation.h"
#import "DecompressOperation.h"


@implementation MainWindowController
@synthesize hostView;
@synthesize compressPopup;
@synthesize lz4CompressionMethods;
@synthesize fastCompressionSlider;
@synthesize highCompressionSlider;
@synthesize isFastCompression;
@synthesize dropViewController;
@synthesize algorithm;
@synthesize lz4Method;


- (id)initWithWindow:(NSWindow *)window
{
	//NSLog(@"MainWindowController");
	self = [super initWithWindow:window];
	if (self) 
    {
		dropViewController = [[DropViewController alloc] init];
	}
	return self;
}

- (void)dealloc
{
	//NSLog(@"Deallocating window controller");
	if (dropViewController != nil) 
    {
		[dropViewController release];
		dropViewController = nil;
	}
	[super dealloc];
}

- (void)loadWindow
{
	//printf("loadWindow\n");
	[super loadWindow];
	[self.hostView addSubview:[dropViewController view]];
	[[self.dropViewController view] setFrame: [self.hostView bounds]];
	[self.compressPopup selectItemAtIndex:0];
	self.isFastCompression = YES;
	[self.fastCompressionSlider setHidden:NO];
}

// Click on the Popup menu
- (IBAction)handleCompressionAlgorithm:(id)sender;
{
	self.algorithm = [self.compressPopup indexOfSelectedItem];
	if (self.algorithm == 2) 
    {
		//printf("PAK\n");
		[self.lz4CompressionMethods setEnabled:NO];
		[self.fastCompressionSlider setEnabled:NO];
		[self.highCompressionSlider setEnabled:NO];
	}
	else if (self.algorithm == 0)
    {
		//printf("LZ4\n");
		[self.lz4CompressionMethods setEnabled:YES];
		if (self.isFastCompression == YES) {
			[self.fastCompressionSlider setHidden:NO];
			[self.fastCompressionSlider setEnabled:YES];
		}
		else {
			[self.highCompressionSlider setHidden:NO];
			[self.highCompressionSlider setEnabled:YES];
		}
	}
	else if (self.algorithm == 1) 
    {
		//printf("LZ4FH\n");
		[self.lz4CompressionMethods setEnabled:YES];
		[self.fastCompressionSlider setHidden:YES];
		[self.highCompressionSlider setHidden:YES];
		[self.fastCompressionSlider setEnabled:NO];
		[self.highCompressionSlider setEnabled:NO];
	}
}

// To connect - control-click drag to NSMatrix instance in xib file.
// Clicking on the radio button is allowed if the instance of NSMatrix is enabled.
- (IBAction)handleLZ4CompressionMethod:(id)sender
{
	// Handles fast or high compression
	self.lz4Method = [sender selectedTag];
	if (self.lz4Method == 0)
    {
		//printf("fast compression is selected\n");
		self.isFastCompression = YES;
		if (self.algorithm == 1)
        {
            // LZ4FH
			[self.fastCompressionSlider setHidden:YES];
			[self.highCompressionSlider setHidden:YES];
		}
		else 
        {
            // LZ4
			[self.fastCompressionSlider setHidden:NO];
			[self.highCompressionSlider setHidden:YES];
		}
	}
	else if (self.lz4Method == 1) 
    {
		//printf("high compression is selected\n");
		self.isFastCompression = NO;
		if (self.algorithm == 1) 
        {
            // LZ4FH
			[self.fastCompressionSlider setHidden:YES];
			[self.highCompressionSlider setHidden:YES];
		}
		else {
            // LZ4
			[self.fastCompressionSlider setHidden:YES];
			[self.highCompressionSlider setHidden:NO];
		}
	}
}

// Currently there is no progress window.
// Watch for KVO notifications about operations, specifically when they
// start executing and when they finish.
// The observer was added in the instance of DropView but we remove it here.
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *) context
{
    
    if ([keyPath isEqualToString: @"isFinished"]) 
    {
        // If it's done, it has inflated/deflated the file.
	/*
		if ([object isKindOfClass:[DecompressOperation class]])
			printf("All files have been decompressed\n");
		else
			printf("All files have been compressed\n");
		
		NSLog(@"Finished:%@", object);
	*/
        // Unhook the observation for this particular object.
        [object removeObserver:self
					forKeyPath:@"isFinished"];
        [object removeObserver:self
					forKeyPath:@"isExecuting"];
		
    }
	else if ([keyPath isEqualToString: @"isExecuting"]) {
        DecompressOperation *op = (DecompressOperation *)object;
       
		//NSLog(@"still executing:%@", object);
    }
	else {
        // The notification is uninteresting to us, let someone else handle it.
        [super observeValueForKeyPath:keyPath
							 ofObject:object
							   change:change
							  context:context];
    }
} // observeValueForKeyPath

@end
