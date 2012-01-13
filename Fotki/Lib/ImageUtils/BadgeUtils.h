//
//  Created by aistomin on 1/13/12.
//
//


#import <Foundation/Foundation.h>


@interface BadgeUtils : NSObject
+ (void)putUpdatedBadgeOnFileIconAtPath:(NSString *)path;

+ (void)putCheckBadgeOnFileIconAtPath:(NSString *)path;
@end