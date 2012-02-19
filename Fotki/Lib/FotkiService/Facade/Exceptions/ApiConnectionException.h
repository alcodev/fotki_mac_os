//
//  Created by vavaka on 1/13/12.



#import <Foundation/Foundation.h>
#import "ApiException.h"


@interface ApiConnectionException : ApiException

+ (ApiConnectionException *)exceptionWithReason:(NSString *)reason;

@end