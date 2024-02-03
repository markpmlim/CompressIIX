//
//  MainWindowController.h
//  CompressIIX
//
//  Created by mark lim on 7/11/16.
//  Copyright 2016 IncrementalInnovation. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class DropViewController;

// MainWindow.xib (fileOwner is MainWindowController)
// Built-in IBOutlet named `window`
@interface MainWindowController : NSWindowController 
{
	NSView				*hostView;		
	NSPopUpButton		*compressPopup;

	// These are for the LZ4 compressor
	NSMatrix			*lz4CompressionMethods;
	NSSlider			*fastCompressionSlider;
	NSSlider			*highCompressionSlider;
	BOOL				isFastCompression;
	DropViewController	*dropViewController;

	NSInteger			algorithm;			// LZ4=0 LZ4FH=1 PAK=2
	NSInteger			lz4Method;			// fast=0 high=1
}

@property (assign) IBOutlet NSView			*hostView;		
@property (assign) IBOutlet NSPopUpButton	*compressPopup;		
@property (assign) IBOutlet NSMatrix		*lz4CompressionMethods;
@property (assign) IBOutlet NSSlider		*fastCompressionSlider;
@property (assign) IBOutlet NSSlider		*highCompressionSlider;
@property (assign)			BOOL			isFastCompression;
@property (retain) DropViewController		*dropViewController;
@property (assign) NSInteger				algorithm;
@property (assign) NSInteger				lz4Method;

- (IBAction)handleCompressionAlgorithm:(id)sender;
- (IBAction)handleLZ4CompressionMethod:(id)sender;

@end
