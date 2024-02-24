//
//  CompressOperation.m
//  CompressIIX
//
//  Created by mark lim on 7/10/16.
//  Copyright 2016 IncrementalInnovation. All rights reserved.
//

#import "AppDelegate.h"
#import "CompressOperation.h"
#import "MainWindowController.h"
#import "PackBytes.h"
#include "lz4.h"
#include "lz4hc.h"
#include "fhpack.h"

// 16-byte Generic header
const uint8_t genericHeader[] =
{
	0x03,0x21,0x4C,0x18,			// legacy format
	0x00,0x00,0x00,0x00,			// original size
	0x00,0x00,0x00,0x4D,
	0x00,0x00,0x00,0x00				// compressed size
};

const uint32_t genericHeaderSize = sizeof(genericHeader);

const uint8_t lz4fhHeader = 0x66;

@implementation CompressOperation

@synthesize finished = _finished;
@synthesize executing = _executing;
@synthesize srcURL = _srcURL;
@synthesize delegate = _delegate;

- (id)initWithURL:(NSURL *)url
{
	self = [super init];
	if (self)
    {
		_srcURL = [url retain];
	}
	return self;
}

- (void)dealloc
{
	if (_srcURL != nil) 
    {
		[_srcURL release];
		_srcURL = nil;
	}
	if (_delegate != nil) 
    {
		[_delegate release];
		_delegate = nil;
	}
	[super dealloc];
}

// These 2 keypaths are monitored by the MainWindowController object.
- (BOOL)isExecuting
{
	return self.executing;
}

- (BOOL)isFinished
{
	return self.finished;
}

// Who will send the NSOperation object this message? NSOperationQueue?
// Currently, there is no Progress Window.
- (void)cancel
{
	[super cancel];
	[self willChangeValueForKey:@"isExecuting"];
	self.executing = NO;
	[self didChangeValueForKey:@"isExecuting"];
	[self willChangeValueForKey:@"isFinished"];
	self.finished = YES;
	[self didChangeValueForKey:@"isFinished"];
}

- (void)lz4fhCompress
{
	NSData *originalData = [NSData dataWithContentsOfURL:_srcURL];
	uint32_t sourceSize = (uint32_t)originalData.length;

	// Perform a simple validation
	if (sourceSize >= minHiResFileSize && sourceSize <= maxHiResFileSize)
    {
		uint8_t *inBuf = (uint8_t *)[originalData bytes];
		uint8_t outBuf[maxHiResFileSize];
		size_t compressedSize = 0;

		if ([self.delegate isFastCompression])
        {
			compressedSize = compressBufferGreedily(outBuf, inBuf, sourceSize);
		}
		else 
        {
			compressedSize = compressBufferOptimally(outBuf, inBuf, sourceSize);
		}
		NSData *compressedData = [NSData dataWithBytes:outBuf
												length:compressedSize];
		NSString *srcPath = _srcURL.path;
		NSString *destPath = [srcPath stringByDeletingPathExtension];
		destPath = [destPath stringByAppendingPathExtension:@"LZ4FH"];
		[compressedData writeToFile:destPath
						 atomically:YES];
	}
	else
    {
        NSSound *ping = [NSSound soundNamed:@"Ping"];
        [ping play];
		NSLog(@"LZ4FH compression failed: File is not an Apple II Hires Graphic.");
        [self cancel];
	}

}

//Should we check the file size?
// Check for cancellation.
- (void)lz4Compress
{
	NSData *originalData = [NSData dataWithContentsOfURL:_srcURL];
	uint32_t sourceSize = (uint32_t)originalData.length;
	// do we check the size?
	// maxDestSize should be obtained using LZ4_compressBound(sourceSize)
	uint32_t maxDestSize = (uint32_t)(genericHeaderSize + LZ4_compressBound(sourceSize));
	//NSLog(@"%ld %ld %ld", bdHeaderSize,sourceSize, maxDestSize);
	
	char *outBuffer = (char *)malloc(maxDestSize);
	memcpy(outBuffer, genericHeader, genericHeaderSize);
	uint32_t tmp = NSSwapHostIntToLittle(sourceSize);
	memcpy(outBuffer+4, &tmp, sizeof(uint32_t));

	int outSize = 0;

	if ([self.delegate isFastCompression]) 
    {
		// Values <=0 will be set to 1 --> LZ4_compress_default; we don't have
		// to change the value of accel to 1
		//int LZ4_compress_default(const char* source, char* dest, int sourceSize, int maxDestSize);
		NSInteger accel = [[self.delegate fastCompressionSlider] integerValue];
		// problem: the max value of accel needs to be determined manually.
		// maxDestSize should be obtained using LZ4_compressBound(sourceSize)
		//NSLog(@"Fast Compression value:%ld", accel);
		outSize = LZ4_compress_fast((const char *)originalData.bytes,
									outBuffer+genericHeaderSize,
									sourceSize,
									maxDestSize,
									(int)accel);
		if (outSize < 0)
        {
			free(outBuffer);
			return;
		}
		tmp = NSSwapHostIntToLittle(outSize);
		memcpy(outBuffer+12, &tmp, sizeof(uint32_t));
		//NSLog(@"Fast Compression was successful:%ld", outSize);
	}
	else 
    {
		// Valid values: 0 - 16; 0 means default which is 9 - the called function
		// will do the needful. We don't have to do anything.
		NSInteger level = [[self.delegate highCompressionSlider] integerValue];
		//NSLog(@"high compression value:%ld", level);
		outSize = LZ4_compress_HC((const char*)originalData.bytes,
								  outBuffer+genericHeaderSize,
								  sourceSize,
								  maxDestSize,
								  (int)level);
		if (outSize < 0) 
        {
			free(outBuffer);
			return;
		}
		tmp = NSSwapHostIntToLittle(outSize);
		memcpy(outBuffer+12, &tmp, sizeof(uint32_t));
		//NSLog(@"high Compression was successful: %ld", outSize);
	}

	// Use NSMutableData in case we want to support Apple's LZ4 format.
	NSMutableData *compressedData = [NSMutableData dataWithBytesNoCopy:outBuffer
																length:outSize+genericHeaderSize];
	NSString *srcPath = _srcURL.path;
	NSString *destPath = [srcPath stringByDeletingPathExtension];
	destPath = [destPath stringByAppendingPathExtension:@"LZ4"];
	[compressedData writeToFile:destPath
					 atomically:YES];
}

/*
 Should we check the file size?
 */
- (void)packBytesCompress
{
	//NSLog(@"packBytesCompress");
	NSData *originalData = [NSData dataWithContentsOfURL:_srcURL];
	NSData *packedData = [PackBytes packBytes:originalData];
	if (packedData != nil) 
    {
		NSString *srcPath = _srcURL.path;
		NSString *destPath = [srcPath stringByDeletingPathExtension];
		destPath = [destPath stringByAppendingPathExtension:@"PAK"];
		[packedData writeToFile:destPath
					 atomically:YES];
	}
}

// Need to detect cancellation
- (void)start
{
	if ([self isCancelled])
    {
		goto bailOut;
    }

	[self willChangeValueForKey:@"isExecuting"];
	self.executing = YES;
	[self didChangeValueForKey:@"isExecuting"];

	// Inflate the file here!
	if (self.delegate.algorithm == 0)
    {
		[self lz4Compress];
	}
	else if (self.delegate.algorithm == 1)
    {
		[self lz4fhCompress];
	}
	else if (self.delegate.algorithm == 2)
    {
		[self packBytesCompress];
	}
	
	// To test progress window. Currently, there is no progress window.
	//usleep(1000000);
	[self willChangeValueForKey:@"isExecuting"];
	self.executing = NO;
	[self didChangeValueForKey:@"isExecuting"];
	[self willChangeValueForKey:@"isFinished"];
	self.finished = YES;
	[self didChangeValueForKey:@"isFinished"];

bailOut:
	return;
}

@end
