#ifndef __USER_DEFINES_H__
#define __USER_DEFINES_H__

// II Graphic identifiers
typedef enum
{
	kAppleLZ4			= 1,
	kBrutalDeluxeLZ4	= 2,
	kFHPackLZ4			= 3,
	kTentativeLZ4		= 4,
	kGenericLZ4			= 5,
} LZ4Format;

extern const uint8_t genericHeader[];
extern const uint32_t genericHeaderSize;
extern const uint8_t lz4fhHeader;

#define kTypeFOT		0x08
#define kTypeBIN		0x06

#define kFOTPackedHGR	0x4000
#define kFOTPackedDHGR	0x4001
#define kFOTLZ4HGR		0x8005
#define kFOTLZ4DHGR		0x8006
#define kFOTLZ4FH		0x8066

#define kTypePNT		0xC0

#define kTypePIC		0xC1
#define kAuxTypeSHR		0x0000
#define kAuxType3200	0x0002

#define minHiResFileSize		8184
#define maxHiResFileSize		8192
#define minDoubleHiResFileSize	16376
#define maxDoubleHiResFileSize	16384
#define plainSHRFileSize		32768
#define plain3200FileSize		38400

#endif