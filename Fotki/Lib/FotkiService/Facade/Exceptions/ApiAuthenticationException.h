//
//  Created by vavaka on 1/13/12.



#import <Foundation/Foundation.h>
#import "ApiException.h"


@interface ApiAuthenticationException : ApiException

+ (ApiAuthenticationException *)exceptionWithReason:(NSString *)reason;

@end