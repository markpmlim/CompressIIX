// prototype
#ifndef FHPACK_H
#define FHPACK_H
#include <sys/types.h>
#include <stdint.h>

extern "C" size_t compressBufferOptimally(uint8_t* outBuf,
										  const uint8_t* inBuf,
										  size_t inLen);
extern "C" size_t compressBufferGreedily(uint8_t* outBuf,
										 const uint8_t* inBuf,
										 size_t inLen);
extern "C" size_t uncompressBuffer(uint8_t* outBuf,
								   const uint8_t* inBuf,
								   size_t inLen);
#endif