//
//  Created by vavaka on 1/5/12.



#import "ApiException.h"


@implementation ApiException

+ (ApiException *)exceptionWithReason:(NSString *)reason {
    return [[[ApiException alloc] initWithName:@"Api exception" reason:reason userInfo:nil] autorelease];
}


@end