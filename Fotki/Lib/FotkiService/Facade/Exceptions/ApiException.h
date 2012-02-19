//
//  Created by vavaka on 1/5/12.



#import <Foundation/Foundation.h>


@interface ApiException : NSException

+ (ApiException *)exceptionWithReason:(NSString *)reason;

@end