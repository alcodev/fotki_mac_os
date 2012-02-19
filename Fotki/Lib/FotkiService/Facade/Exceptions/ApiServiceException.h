//
//  Created by vavaka on 2/18/12.



#import <Foundation/Foundation.h>
#import "ApiException.h"


@interface ApiServiceException : ApiException

+ (ApiServiceException *)exceptionWithReason:(NSString *)reason;

@end