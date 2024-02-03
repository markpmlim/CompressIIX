//
//  DecompressOperation.m
//  CompressIIX
//
//  Created by mark lim on 7/10/16.
//  Copyright 2016 IncrementalInnovation. All rights reserved.
//
// KIV. Instead of an array of paths, consider instantiating with
// a single path URL. Multiple threads can be used.

#import "DecompressOperation.h"
#import "MainWindowController.h"
#import "AppDelegate.h"
#import "PackBytes.h"
#include "lz4.h"
#include "fhpack.h"

NSString *const compressedSizeKey = @"Compressed Size";
NSString *const originalSizeKey = @"Original Size";
NSString *const lz4FormatKey = @"LZ4 Format";
NSString *const compressedDataKey = @"Compressed Data";


@implementation DecompressOperation
@synthesize finished;
@synthesize executing;
@synthesize delegate = _delegate;   // Not used.

-(id)initWithURL:(NSURL *)url
{
	self = [super init];
	if (self)
    {
		_srcURL = [url retain];		// must retain this because paths was set to autorelease
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

// These 2 keypaths are used to inform observers.
- (BOOL)isExecuting
{
	return self.executing;
}

- (BOOL)isFinished
{
	return self.finished;
}

// Who will send the NSOperation object this message? NSOperationQueue?
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

/*
 Extract the compressed data which was deflated with the LZ4 format.
 We need to preserve the original size.
 However, Fadden's implementation does not store its original size;
 it expects the original size to be 8184-8192.
 LZ4_decompress_safe must be used since the compressedSize &
 maxDecompressedSize are known.
 */
- (NSData *)compressedDataFromFileData:(NSData *)fileContents
                                format:(LZ4Format)format
{
	NSMutableData *mutableContents = [NSMutableData dataWithData:fileContents];
	NSRange range;

	if (format == kFHPackLZ4) 
    {
        //printf("Compress Fadden LZ4\n");
		range = NSMakeRange(0, 1);
		[mutableContents replaceBytesInRange:range
								   withBytes:NULL
									  length:0];
	}
	else if (format == kBrutalDeluxeLZ4 || format == kGenericLZ4)
    {
        //printf("Compress BrutalDeluxe LZ4\n");
		range = NSMakeRange(0, 16);
		[mutableContents replaceBytesInRange:range
								   withBytes:NULL
									  length:0];
	}
	else if (format == kAppleLZ4)
    {
		// Remove trailing magic number first.
        //printf("Compress Apple LZ4\n");
		range = NSMakeRange(mutableContents.length-4, 4);
		[mutableContents replaceBytesInRange:range
								   withBytes:NULL
									  length:0];
		// Then remove leading magic number which is 12 bytes.
		range = NSMakeRange(0, 12);
		[mutableContents replaceBytesInRange:range
								   withBytes:NULL
									  length:0];
	}
	return mutableContents;
}

/*
 Returns a custom dictionary to be used to decompress a file.
 */
- (NSDictionary *)compressionDictionaryAtURL:(NSURL *)url
{
	NSData *fileContents = [NSData dataWithContentsOfURL:url];
	AppDelegate *appDelegate = [NSApp delegate];
	LZ4Format format = [appDelegate identifyFormatWithFileData:fileContents];
	u_int32_t compressedSize;
	u_int32_t originalSize = 0;
	
	if (format == kFHPackLZ4) 
    {
		compressedSize = fileContents.length - 1;
		// orginal size is 8184-8192 bytes.
	}
	else if (format == kBrutalDeluxeLZ4 || format == kAppleLZ4) 
    {
		u_int32_t tmp;
		memcpy(&tmp, (uint8_t *)fileContents.bytes+4, sizeof(uint32_t));
		originalSize = NSSwapLittleIntToHost(tmp);
		compressedSize = fileContents.length - 16;
	}
	NSData *compressedData = [self compressedDataFromFileData:fileContents
													   format:format];
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
							  compressedData, compressedDataKey,
							  [NSNumber numberWithUnsignedInt:format], lz4FormatKey,
							  [NSNumber numberWithUnsignedInt:compressedSize], compressedSizeKey,
							  [NSNumber numberWithUnsignedInt:originalSize], originalSizeKey,
							  nil];
	return dict;
}

/*
 */
- (void)writeInflatedData:(NSData *)inflatedData
{
	NSString *srcPath = _srcURL.path;
	NSString *destPath = [NSString stringWithString:srcPath];
	NSString *name = [destPath lastPathComponent];
	name = [name stringByDeletingPathExtension];
	destPath = [destPath stringByDeletingLastPathComponent];
	destPath = [destPath stringByAppendingPathComponent:name];
	uint32_t dataLen = (uint32_t)[inflatedData length];

	if ((dataLen >= minHiResFileSize && dataLen <= maxHiResFileSize) ||
		(dataLen >= minDoubleHiResFileSize && dataLen <= maxDoubleHiResFileSize))
    {
		uint16_t auxType = 0x0000;
		uint8_t fileType = 0x00;
		if (dataLen >= minHiResFileSize && dataLen <= maxHiResFileSize)
        {
			destPath = [destPath stringByAppendingPathExtension:@"HGR"];
			fileType = 0x08;		// FOT
			auxType = 0x0000;
		}
		else if (dataLen >= minDoubleHiResFileSize && dataLen <= maxDoubleHiResFileSize)
        {
			destPath = [destPath stringByAppendingPathExtension:@"DHGR"];
			fileType = 0x08;		// FOT
			auxType = 0x0000;
		}

		NSURL *destURL = [NSURL fileURLWithPath:destPath];
		[inflatedData writeToURL:destURL
					  atomically:YES];

		if (fileType != 0x00) 
        {
			NSError *errOut = nil;
			NSFileManager *fileManager = [NSFileManager defaultManager];
			NSDictionary *fileAttr = [fileManager attributesOfItemAtPath:destPath
																   error:&errOut];
			NSMutableDictionary *newFileAttr = [NSMutableDictionary dictionary];
			[newFileAttr addEntriesFromDictionary:fileAttr];
			OSType creatorCode = 'pdos';
			OSType fileTypeCode = 0x70000000 + (fileType << 16) + auxType; 
			[newFileAttr setObject:[NSNumber numberWithInt:fileTypeCode]
							forKey:NSFileHFSTypeCode];
			[newFileAttr setObject:[NSNumber numberWithInt:creatorCode]
							forKey:NSFileHFSCreatorCode];
			[fileManager setAttributes:newFileAttr
						  ofItemAtPath:destPath
								 error:&errOut];
		}
	}
	else 
    {
		NSLog(@"%@ is not a compressed Apple II Graphic file", _srcURL.path);
	}
}

/*
 Inflate PAK files
 */
- (void)packInflate
{
    //printf("PAK Inflate\n");
	NSError *errOut = nil;
	NSData *compressedData = [NSData dataWithContentsOfURL:_srcURL
												 options:NSMappedRead
												   error:&errOut];
	NSData *inflatedData = nil;
	if (errOut == nil) 
    {
		inflatedData = [PackBytes unpackBytes:compressedData];
		if (inflatedData != nil) 
        {
			[self writeInflatedData:inflatedData];
		}
	}
}

// todo: support latest LZ4 frame format
// Inflate LZ4 files
- (void)lz4Inflate
{
    //printf("lz4Inflate\n");
	NSError *errOut = nil;
	NSData *originalData = [NSData dataWithContentsOfURL:_srcURL
												 options:NSMappedRead
												   error:&errOut];
	if (errOut == nil) 
    {
		uint32_t tmp;
		memcpy(&tmp, originalData.bytes, sizeof(uint32_t));
		uint32_t magic_number = NSSwapLittleIntToHost(tmp);
		
		if (magic_number != 0x184c2103)
        {
			NSLog(@"magic number not found");
			goto bailOut;
		}


		uint32_t headerSize = 16;
		memcpy(&tmp, (uint8_t*)originalData.bytes+4, sizeof(uint32_t));
		uint32_t originalSize = NSSwapLittleIntToHost(tmp);

		char *outBuffer = (char *)malloc(originalSize);
		// The function LZ4_uncompress is deprecated - use LZ4_decompress_fast.
		// outSize should be the compressed size of the file.
		int outSize = LZ4_decompress_fast((const char *)((uint8_t *)originalData.bytes+headerSize),
										  outBuffer,
										  (int)originalSize);

		if (outSize < 0)
        {
			free(outBuffer);
			goto bailOut;
		}

		// Ownership of outBuffer will be taken over by the returned NSData
		// object so we must not call the C function free.
		NSData *inflatedData = [NSData dataWithBytesNoCopy:outBuffer
													length:originalSize];
		if (inflatedData != nil) 
        {
			[self writeInflatedData:inflatedData];
		}
		else
        {
			// Instance of NSData could not be created.
			free(outBuffer);	// But will this crash the program?
		}
	}

bailOut:
	return;
}

- (void)lz4fhInflate
{
    //printf("lz4fh Inflate\n");
	NSError *errOut = nil;
	NSData *compressedData = [NSData dataWithContentsOfURL:_srcURL
												   options:NSMappedRead
													 error:&errOut];
	if (errOut == nil)
    {
		uint8_t *outBuffer = (uint8_t *)malloc(maxHiResFileSize);
		size_t originalSize = uncompressBuffer(outBuffer,
											   (const uint8_t *)[compressedData bytes],
											   [compressedData length]);
		if (originalSize >= minHiResFileSize && originalSize <= maxHiResFileSize) 
        {
			NSData *inflatedData = [NSData dataWithBytesNoCopy:outBuffer
														length:originalSize];
			[self writeInflatedData:inflatedData];
		}
		else 
        {
			NSLog(@"%@ is not a compressed Apple II Graphic file", _srcURL.path);
			free(outBuffer);
		}
	}
}

- (void)start
{
	if ([self isCancelled] == NO)
    {
		NSFileManager *fmgr = [NSFileManager defaultManager];
		// Check if the file is a ProDOS file.
		NSError *error = nil;
		NSDictionary *attr = [fmgr attributesOfItemAtPath:_srcURL.path
													error:&error];
		if (error != nil)
        {
			goto bailOut;
        }
		OSType typeCode = [attr fileHFSTypeCode];
		uint16_t fileType = (typeCode & 0x00ff0000) >> 16;
		uint16_t auxType = (typeCode & 0x0000ffff);
		OSType creatorCode = [attr fileHFSCreatorCode];
		int compressionType;
		if (creatorCode == 'pdos' && fileType == kTypeFOT)
        {
			if 	(auxType == kFOTLZ4HGR || auxType == kFOTLZ4DHGR)
            {
				compressionType = 1;
            }
			else if (auxType == kFOTPackedHGR || auxType == kFOTPackedDHGR)
            {
				compressionType = 2;
            }
			else if (auxType == kFOTLZ4FH)
            {
				compressionType = 3;
            }
		}
		else
        {
			// Not a ProDOS file, so we just check the suffix.
			NSString *fileExtension = [[_srcURL.path pathExtension] uppercaseString];
			if ([fileExtension isEqualToString:@"LZ4"])
            {
				compressionType = 1;
            }
			else if ([fileExtension isEqualToString:@"PAK"]) 
            {
				compressionType = 2;
            }
			else if ([fileExtension isEqualToString:@"LZ4FH"])
            {
				compressionType = 3;
            }
		}

		[self willChangeValueForKey:@"isExecuting"];
		self.executing = YES;
		[self didChangeValueForKey:@"isExecuting"];

		// Inflate the file here!
		if (compressionType == 1) 
        {
			[self lz4Inflate];
		}
		else if (compressionType == 2) 
        {
			[self packInflate];
		}
		else if (compressionType == 3)
        {
			[self lz4fhInflate];
		}

		//usleep(1000000);
		[self willChangeValueForKey:@"isExecuting"];
		self.executing = NO;
		[self didChangeValueForKey:@"isExecuting"];
		[self willChangeValueForKey:@"isFinished"];
		self.finished = YES;
		[self didChangeValueForKey:@"isFinished"];
		
	}

bailOut:
	return;
}
@end
