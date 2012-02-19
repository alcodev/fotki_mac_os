//
//  Created by vavaka on 1/27/12.



#import <Foundation/Foundation.h>
#import "ApiException.h"


@interface ApiNotFoundException : ApiException

+ (ApiNotFoundException *)exceptionWithReason:(NSString *)reason;

@end