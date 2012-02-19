//
//  Created by vavaka on 1/13/12.



#import "ApiConnectionException.h"


@implementation ApiConnectionException

+ (ApiConnectionException *)exceptionWithReason:(NSString *)reason {
    return [[[ApiConnectionException alloc] initWithName:@"Api connection exception" reason:reason userInfo:nil] autorelease];
}

@end