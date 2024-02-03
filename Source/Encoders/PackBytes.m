/*
 A function that can compress data based on the "packBytes" algorithm developed
 by Apple for the AppleIIgs computer.
 */
// Author: Sheldon Simms
// http://wsxyz.net/tohgr.html
#include <stdlib.h>
#include <assert.h>
#import "PackBytes.h"

#define sixtyFourK	65536
#define kThreshhold	2

struct OutputBuffer {
	unsigned char *p;		// start of memblock
	unsigned char *n;		// pointer to next free slot
	unsigned int len, size;
};

// Ensure a 64K output buffer
// Bug fix: We should use malloc rather than realloc
static int initOutputBuffer (struct OutputBuffer *ob)
{
	ob->len = 0;				// # of bytes encoded so far
	ob->size = sixtyFourK;		// current size of ouput buffer in bytes
	//ob->n = ob->p = realloc(0, ob->size);
	ob->n = ob->p = malloc(ob->size);
	return ob->p != 0;
}

// Resize if necessary; len is the # of bytes required
static int checkOutputBuffer (struct OutputBuffer *ob, int len)
{
	unsigned char *p;

	if (ob->len + len <= ob->size) {
		return 1;
    }

	// Increase the size of the output buffer by 64K
	p = realloc(ob->p, ob->size + sixtyFourK);
	if (!p) {
		return 0;			// failed
    }
	ob->n = p + (ob->n - ob->p);
	ob->p = p;
	ob->size = ob->size + sixtyFourK;
	return 1;
}

#define CaptureSingletons() {					\
	while (tmpCount > 0)						\
	{											\
		int k = tmpCount;						\
		if (k >= 64)							\
			k = 64;								\
			tmpCount -= k;						\
			if (!checkOutputBuffer(ob, k + 1))	\
				return NULL;					\
		ob->len += (k + 1);						\
		*ob->n++ = (unsigned char)(k - 1);		\
		while (k--)								\
			*ob->n++ = *blockPtr++;				\
	}											\
}
// FTN 08/0x4000 - Packed Hi-Res File
// TN.IIGS.094 - see "PACKBYTES BUFFERS COUNT TOO" section
// Return a NULL pointer if unsuccessful especially if there is not enough mem.
// KIV: to convert to Objective-C method
static struct OutputBuffer *CPackBytes(void *vp, unsigned int len)
{
	u_int32_t bytesLeft, tmpCount, repeatCount;
	Byte *blockPtr, *inputPtr, *tmpPtr, *rp;
	Byte currByte;
	struct OutputBuffer *ob = malloc(sizeof(struct OutputBuffer));
	//struct OutputBuffer ob;
	//Byte rleBuf[65];						// use min size for Run Length Encoding Buffer
	//u_int32_t numBytes;					// # of encoded bytes including leading flag byte
	//NSMutableData *packedData = [NSMutableData data];

	if (!initOutputBuffer(ob)) {            // Get a 4K buffer
		return NULL;
	}
	blockPtr = vp;
	inputPtr = vp;
	bytesLeft = len;						// # of bytes to pack

	while (bytesLeft) {
		tmpPtr = inputPtr;
		tmpCount = bytesLeft;
		currByte = *tmpPtr++;				// get byte to be checked
		// Loop to check if the byte is repeated
		while (--tmpCount && currByte == *tmpPtr) {
			tmpPtr++;
        }

		// tmpPtr is pointing @ the next byte that's different from the byte being examined.
		repeatCount = tmpPtr - inputPtr;
		// No encoding for 2 identical bytes in a row; treated as singletons
		if (repeatCount > kThreshhold) {
			// Handles 2 or more repeats of the byte being examined
			// ie 3 or more identical bytes in a row: 3, 4, 5, ...
			// inputPtr is pointing @ the byte being examined
			tmpCount = inputPtr - blockPtr;
			// if tmpCount > 0, there are singletons to be captured
			CaptureSingletons();

			assert(blockPtr == inputPtr);			// abort if blockPtr != ip

			if (repeatCount < 8 && repeatCount % 4) {
				// case 1: 3,5,6,7 identical bytes in a row
				if (!checkOutputBuffer(ob, 2)) {
					return NULL;
                }
				// flag byte (flag bits = %01)
				// Order of operation: -> access the pointer n, incr pointer n later, deref pointer n, assign
				// Assign the flag byte and then increment the pointer to next slot.
				*ob->n++ = 0x40 | ((unsigned char)(repeatCount - 1));
				*ob->n++ = currByte;
				ob->len += 2;
				bytesLeft -= repeatCount;
				inputPtr += repeatCount;
			}
			else {
				// case 3: multiple of 4 of a repeated byte (up to 64 x 4)
				repeatCount /= 4;
				if (repeatCount > 64) {
					repeatCount = 64;
                }
				if (!checkOutputBuffer(ob, 2)) {
					return NULL;
                }
				// flag byte (flag bits = %11)
				*ob->n++ = 0xC0 | ((unsigned char)(repeatCount - 1));
				*ob->n++ = currByte;		// byte that is repeated
				ob->len += 2;
				bytesLeft -= (repeatCount * 4);
				inputPtr += (repeatCount * 4);
			}
			blockPtr = inputPtr;
			continue;
		}

		if (bytesLeft >= 8) {
			// Prepare to scan ahead 4 bytes from where we are
			rp = inputPtr;				// rp is pointing @ the byte being examined/repeated
			tmpPtr = inputPtr + 4;		// NB. tmpPtr is always 4 bytes ahead of rp
			tmpCount = bytesLeft - 4;
			while (tmpCount && *tmpPtr == *rp) {
				tmpPtr += 1;			// advance by pointers and check
				rp += 1;				// if the bytes pointed to are identical
				tmpCount -= 1;
			}

			repeatCount = tmpPtr - inputPtr;
			if (repeatCount >= 8) {
				// case 0 - all bytes different
				tmpCount = inputPtr - blockPtr;		// condition
				CaptureSingletons();
				assert(blockPtr == inputPtr);       // abort if blockPtr != ip

				// case 2 - handle repeats of 4 consecutive different bytes
				repeatCount /= 4;
				if (repeatCount > 64) {
					repeatCount = 64;
                }
				if (!checkOutputBuffer(ob, 5)) {
					return NULL;
                }
				// flag byte (flag bits = %10)
				*ob->n++ = 0x80 | ((unsigned char)(repeatCount - 1));
				*ob->n++ = inputPtr[0];
				*ob->n++ = inputPtr[1];
				*ob->n++ = inputPtr[2];
				*ob->n++ = inputPtr[3];
				ob->len += 5;
				bytesLeft -= (repeatCount * 4);
				inputPtr += (repeatCount * 4);
				blockPtr = inputPtr;
				continue;
			}
		}

		// We have a singleton
		inputPtr += 1;
		bytesLeft -= 1;
	} // while

	// capture all the stragglers which are singletons
	tmpCount = inputPtr - blockPtr;
	CaptureSingletons();
	return ob;
}


@implementation PackBytes

// An entire file or just a scanline may be passed
// todo: bullet proof
+ (NSData *)packBytes:(NSData *)fileData
{
	//NSLog(@"packBytes compress");
	NSData *compressedData = nil;
	unsigned int fileSize = [fileData length];
	void *inputBuf = (void *)[fileData bytes];

	struct OutputBuffer *compressedBuf = CPackBytes(inputBuf, fileSize);

	if (compressedBuf) {
		compressedData = [NSData dataWithBytes:compressedBuf->p
										length:compressedBuf->len];
		free(compressedBuf->p);
		free(compressedBuf);
	}
	return compressedData;
}

#pragma mark unpackBytes decoder used by many AppleIIGS graphics programs
/*
 An entire file or just a packed scanline may be passed.
 The caller will decide whether the # of bytes in the 
 returned instance of NSData is valid.
 This method is not crash-proofed; acccessing the input/output buffers
 (via the inp, outp pointers) beyond their limits can happen.
 The variable srcLen can serve as a sentinel/guard for Input Buffer
 We could use the "count" to compute value which is then compare to 256 to
 determine if there is overflow in the Output Buffer (rldBuf).
 The parameter "numBytes" + (outp - rldBuf) < 256
 This may not be necessary after all on further investigation because there is
 no way an overrun of the output can happen since outp is reset to rldBuf after
 each mini-run.
 */
+ (NSData *)unpackBytes:(NSData *)packedData
{
	Byte *inp = (Byte *)[packedData bytes];
	int srcLen = [packedData length];
	NSMutableData *unpackedData = [NSMutableData data];
	Byte rldBuf[256];							// max runlen= 64 x 4
	NSUInteger numBytes;
	NSUInteger totalBytes = 0;					// running total of decoded bytes
	
	while (srcLen > 0) {
		Byte header = *inp++;
		--srcLen;
		Byte *outp = rldBuf;					// Run Len Decode buffer
		int whichFormat = (header & 0xC0) >> 6;	// isolate 2 flag bits
		int count = (header & 0x3F) + 1;		// isolate 6 length bits (0-63)
												// count is 0-based so add 1
		numBytes = count;						// set this for cases 0 and 1
		switch (whichFormat) {
			case 0:
				// add a sentinel here
				//NSLog(@"%d", numBytes + outp - rldBuf);
				while (count--) {
					*outp++ = *inp++;			// AllDifferent
					--srcLen;
				}
				break;
			case 1:
			{
				// add a sentinel here
				//NSLog(@"%d", numBytes + outp - rldBuf);
				Byte repeatedByte = *inp++;		// RepeatNextByte
				--srcLen;
				// count: 3, 5, 6 or 7
				while (count--) {
					*outp++ = repeatedByte;
				}
				break;
			}
			case 2:
			{
				Byte fourBytes[4];				// REPEAT NEXT 4 BYTES
				fourBytes[0] = *inp++;
				fourBytes[1] = *inp++;
				fourBytes[2] = *inp++;
				fourBytes[3] = *inp++;
				srcLen -= 4;
				numBytes = count*4;				// # of bytes to be decoded
												// add a sentinel here?
												//NSLog(@"%d", numBytes + outp - rldBuf);
				while (count--) {
					*outp++ = fourBytes[0];
					*outp++ = fourBytes[1];
					*outp++ = fourBytes[2];
					*outp++ = fourBytes[3];
				}
				break;
			}
			case 3:
			{
				Byte repeatedByte = *inp++;		// REPEAT 4 OF NEXT 1 BYTE
				--srcLen;
				numBytes = count *= 4;			// total # of bytes to be decoded
												// add a sentinel here
												//NSLog(@"%d", numBytes + outp - rldBuf);
				while (count--) {
					*outp++ = repeatedByte;
				}
				break;
			}
		} // switch

		[unpackedData appendBytes:rldBuf
						   length:numBytes];
		totalBytes += numBytes;
	} // while
	return unpackedData;
}


@end;











