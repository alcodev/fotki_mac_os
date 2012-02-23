//
//  Created by dimakononov on 15.02.12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>


@interface TextUtils : NSObject
+ (id)hyperlinkFromString:(NSString *)inString withURL:(NSURL *)aURL;

+ (NSString *)formatFileSize:(float)sizeInByte;

+ (NSString *)formatSpeed:(float)speedInByteSec;
@end