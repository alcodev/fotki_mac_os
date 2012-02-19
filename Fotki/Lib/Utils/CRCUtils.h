//
//  Created by dimakononov on 15.02.12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>


@interface CRCUtils : NSObject

+ (uint32_t)crcFromDataAsInteger:(NSData *)data;

+ (NSString *)crcFromDataAsString:(NSData *)data;

@end