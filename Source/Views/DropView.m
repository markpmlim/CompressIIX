//
//  DropView.m
//  CompressIIX
//
//  Created by mark lim on 7/11/16.
//  Copyright 2016 IncrementalInnovation. All rights reserved.
//

#import "AppDelegate.h"
#import "DropView.h"
#import "DecompressOperation.h"
#import "CompressOperation.h"

/*
 An instance of NSView has accessed to its instance of NSWindow.
 But it cannot directly access its instance of NSViewController.
 */
@implementation DropView

@synthesize string = _string;

- (id)initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];
	if (self)
    {
		// Initialization code here.
		NSFont *font = [NSFont systemFontOfSize:20];
		NSDictionary *attributes = [NSDictionary dictionaryWithObject:font
															   forKey:NSFontAttributeName];
		_string =  [[NSAttributedString alloc] initWithString:@"Drop your files here"
                                                   attributes:attributes];
	}
	return self;
}

- (void)dealloc
{
    if (_string != nil)
    {
        [_string release];
        _string = nil;
    }
	[super dealloc];
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
	[super drawRect:dirtyRect];
	[[NSColor yellowColor] set];
	[NSBezierPath fillRect:dirtyRect];

    NSRect bounds = [self bounds];
	// Center the text horizontally and vertically within the view.
    NSSize stringSize = [self.string size];
    NSPoint point;
    point.y = bounds.size.height/2 - stringSize.height/2;
	point.x = bounds.size.width/2 - stringSize.width/2;
    [self.string drawAtPoint:point];
}

- (BOOL)isAppleIIGraphic:(NSString *)path
                fileType:(uint16_t)fType
                 auxType:(uint16_t)aType
{
	BOOL isAppleIIGraphic = NO;
	NSFileManager *fmgr = [NSFileManager defaultManager];
	// Check if the file is a ProDOS file.
	NSError *error = nil;
	NSDictionary *attr = [fmgr attributesOfItemAtPath:path
												error:&error];
	unsigned long long fileSize = [attr fileSize];
	if (fType == 0 || fType == kTypeBIN)
    {
		// Type less or no ProDOS file type or plain ProDOS BIN
		isAppleIIGraphic = ((fileSize >= minHiResFileSize && fileSize <= maxHiResFileSize) ||
							(fileSize >= minDoubleHiResFileSize && fileSize <= maxDoubleHiResFileSize));
		
	}
	else if (fType == kTypeFOT && (aType < kFOTPackedHGR)) 
    {
		// FOT ($0000-$3FFF) - assumes the user has set them correctly.
		// Should we check the file size as well?
		isAppleIIGraphic = YES;
	}
	return isAppleIIGraphic;
}

// Implementation of some NSDraggingDestination protocol methods
- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
	return NSDragOperationEvery;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
	BOOL result = NO;
	NSPasteboard *pboard = [sender draggingPasteboard];
	if ([[pboard types] containsObject:NSFilenamesPboardType])
    {
		NSFileManager *fmgr = [NSFileManager defaultManager];
		BOOL isDir;
		NSArray *paths = [pboard propertyListForType:NSFilenamesPboardType];
		id appDelegate = [NSApp delegate];
		MainWindowController *winCtlr = [[self window] windowController];
		NSMutableArray *filteredPaths = [NSMutableArray array];
		NSMutableArray *filteredCompressedPaths = [NSMutableArray array];

		for (NSString *path in paths)
        {
			// check that path is not a folder
			if ([fmgr fileExistsAtPath:path
						   isDirectory:&isDir] && isDir) 
            {
				NSLog(@"Folder not accepted");
				continue;
			}
			NSString *fileExt = [[path pathExtension] uppercaseString];
			if ([fileExt isEqualToString:@"LZ4"] ||
				[fileExt isEqualToString:@"LZ4FH"] ||
				[fileExt isEqualToString:@"PAK"])
            {
                // The file will be decompressed.
				[filteredCompressedPaths addObject:path];
				continue;
			}

			// Check if the file is a ProDOS file
			NSError *error = nil;
			NSDictionary *attr = [fmgr attributesOfItemAtPath:path
														error:&error];
			if  (error == nil) {
				OSType creatorCode = [attr fileHFSCreatorCode];
				// Check if the ProDOS file & aux types indicates it is a compressed file.
				OSType typeCode = [attr fileHFSTypeCode];
				uint16_t fileType = (typeCode & 0x00ff0000) >> 16;
				uint16_t auxType = (typeCode & 0x0000ffff);

				if (creatorCode == 'pdos') 
                {
					if (fileType == kTypeFOT &&
						(auxType == kFOTPackedHGR || auxType == kFOTPackedDHGR ||
						 auxType == kFOTLZ4HGR || auxType == kFOTLZ4DHGR || auxType == kFOTLZ4FH))
                    {

                        // The file will be decompressed.
						[filteredCompressedPaths addObject:path];
						continue;
					}
				}

				if ([self isAppleIIGraphic:path
								  fileType:fileType
								   auxType:auxType] == YES) 
                {

					// The file will be compressed.
					[filteredPaths addObject:path];
                }
			}
		} // for

		if ([filteredCompressedPaths count] != 0) 
        {
            
			for (NSString *path in filteredCompressedPaths)
            {
				NSURL *url = [NSURL fileURLWithPath:path];
				DecompressOperation *op = [[DecompressOperation alloc] initWithURL:url];
                op.delegate =  winCtlr;

				[op addObserver:(id)winCtlr
					 forKeyPath:@"isFinished"
						options:0       // It just changes state once, so don't
                                        // worry about what's in the notification
						context: NULL];

				// Watch for when this operation starts executing, so we can update
				// the user interface. Currently, there is no progress window.
				[op addObserver:(id)winCtlr
					 forKeyPath:@"isExecuting"
						options:NSKeyValueObservingOptionNew
						context:NULL];
				[[appDelegate queue] addOperation:op];
				[op release];
			}
			result = YES;
		}
		else if ([filteredPaths count] != 0)
        {
			for (NSString *path in filteredPaths)
            {
				NSURL *url = [NSURL fileURLWithPath:path];
				CompressOperation *op = [[CompressOperation alloc] initWithURL:url];
                op.delegate = winCtlr;

				[op addObserver:(id)winCtlr
					 forKeyPath:@"isFinished"
						options:0           // It just changes state once, so don't
                                            // worry about what's in the notification
						context: NULL];

				// Watch for when this operation starts executing, so we can update
				// the user interface. Currently, there is no progress window.
				[op addObserver:(id)winCtlr
					 forKeyPath:@"isExecuting"
						options:NSKeyValueObservingOptionNew
						context:NULL];
				[[appDelegate queue] addOperation:op];
				[op release];
			}
		}
		result = YES;
	}
	return result;
}

@end
