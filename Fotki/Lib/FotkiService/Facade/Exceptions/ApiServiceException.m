//
//  Created by vavaka on 2/18/12.



#import "ApiServiceException.h"


@implementation ApiServiceException

+ (ApiServiceException *)exceptionWithReason:(NSString *)reason {
    return [[[ApiServiceException alloc] initWithName:@"Api service exception" reason:reason userInfo:nil] autorelease];
}

@end