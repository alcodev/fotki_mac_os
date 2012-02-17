//
//  Created by dimakononov on 17.02.12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>


@interface DateUtils : NSObject

+ (NSInteger)dateDiffInSecondsBetweenDate1:(NSDate *)date1 andDate2:(NSDate *)date2;

+ (NSString *)formatLeftTime:(float)leftTime;


@end