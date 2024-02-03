//
//  Encode_PackBytes.h
//  ConvertSHR+3200
//
//  Created by mark lim on 4/5/16.
//  Copyright 2016 IncrementalInnovation. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PackBytes: NSObject

+ (NSData *)packBytes:(NSData *)fileData;
+ (NSData *)unpackBytes:(NSData *)packedData;
@end
