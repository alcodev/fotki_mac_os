//
//  Created by dimakononov on 17.02.12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "DateUtils.h"


@implementation DateUtils {

}

+ (NSInteger)dateDiffInSecondsBetweenDate1:(NSDate *)date1 andDate2:(NSDate *)date2 {
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSUInteger unitFlags = NSHourCalendarUnit | NSMinuteCalendarUnit | NSDayCalendarUnit | NSSecondCalendarUnit;
    NSDateComponents *components = [gregorianCalendar components:unitFlags
                                                        fromDate:date1
                                                          toDate:date2
                                                         options:0];
    [gregorianCalendar release];

    return [components hour] * 3600 + [components minute] * 60 + [components second];
}

+ (NSString *)formatLeftTime:(float)leftTime {
    double seconds = round(leftTime);
    double hours = floor(seconds / 3600);
    double minutes = floor((seconds - hours * 3600) / 60);
    seconds = round(seconds - hours * 3600 - minutes * 60);
    NSString *formattedString = [[[NSString alloc] init] autorelease];
    if ((int)hours > 0){
        formattedString = [NSString stringWithFormat:@"%d hour(s) ", (int)hours];
    }
    if ((int)minutes > 0){
        formattedString = [NSString stringWithFormat:@"%@%d minute(s) ",formattedString, (int)minutes];
    }
    formattedString = [NSString stringWithFormat:@"%@ %d second(s)", formattedString, (int)seconds];
    //LOG(@"%@", formattedString);
    return [NSString stringWithFormat:@"Total progress (Estimated time left: %@)", formattedString];
}
@end