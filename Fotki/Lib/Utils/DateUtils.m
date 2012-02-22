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
    if ((int) hours > 0) {
        if ((int) hours == 1)
            formattedString = [NSString stringWithFormat:@"%d hour ", (int) hours];
        else
            formattedString = [NSString stringWithFormat:@"%d hours ", (int) hours];
    }
    if ((int) minutes > 0) {
        if ((int) minutes == 1)
            formattedString = [NSString stringWithFormat:@"%@%d minute ", formattedString, (int) minutes];
        else
            formattedString = [NSString stringWithFormat:@"%@%d minutes ", formattedString, (int) minutes];
    }
    if ((int) seconds == 1)
        formattedString = [NSString stringWithFormat:@"%@ %d second", formattedString, (int) seconds];
    else
        formattedString = [NSString stringWithFormat:@"%@ %d seconds", formattedString, (int) seconds];

    return formattedString;
}


@end