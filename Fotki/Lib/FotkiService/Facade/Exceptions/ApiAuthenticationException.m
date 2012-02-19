//
//  Created by vavaka on 1/13/12.



#import "ApiAuthenticationException.h"


@implementation ApiAuthenticationException

+ (ApiAuthenticationException *)exceptionWithReason:(NSString *)reason {
    return [[[ApiAuthenticationException alloc] initWithName:@"Api authentication exception" reason:reason userInfo:nil] autorelease];
}

@end