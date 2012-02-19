//
//  Created by dimakononov on 15.02.12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <zlib.h>
#import "CRCUtils.h"


@implementation CRCUtils

+ (uint32_t)crcFromDataAsInteger:(NSData *)data {
    uint32_t crc = crc32(0, NULL, 0);
    return crc32(crc, [data bytes], [data length]);
}

+ (NSString *)crcFromDataAsString:(NSData *)data {
    return [NSString stringWithFormat:@"%lu", (unsigned long) [CRCUtils crcFromDataAsInteger:data]];
}

@end