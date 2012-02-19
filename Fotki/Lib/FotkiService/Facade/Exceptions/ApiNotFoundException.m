//
//  Created by vavaka on 1/27/12.



#import "ApiNotFoundException.h"


@implementation ApiNotFoundException

+ (ApiNotFoundException *)exceptionWithReason:(NSString *)reason {
    return [[[ApiNotFoundException alloc] initWithName:@"Api not found exception" reason:reason userInfo:nil] autorelease];
}

@end