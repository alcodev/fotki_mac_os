//
//  Created by vavaka on 1/3/12.



#import "ApiCallResult.h"
#import "AFHTTPRequestOperation.h"

@implementation ApiCallResult

@synthesize requestOperation = _requestOperation;
@synthesize methodResult = _methodResult;
@synthesize isSuccess = _isSuccess;
@synthesize error = _error;


+ (id)successResultWithRequestOperation:(AFHTTPRequestOperation *)requestOperation methodResult:(id)methodResult {
    ApiCallResult *apiCallResult = [[[ApiCallResult alloc] init] autorelease];
    apiCallResult.requestOperation = requestOperation;
    apiCallResult.isSuccess = YES;
    apiCallResult.methodResult = methodResult;

    return apiCallResult;
}

+ (id)errorResultWithRequestOperation:(AFHTTPRequestOperation *)requestOperation error:(NSError *)error {
    ApiCallResult *apiCallResult = [[[ApiCallResult alloc] init] autorelease];
    apiCallResult.requestOperation = requestOperation;
    apiCallResult.isSuccess = NO;
    apiCallResult.error = error;

    return apiCallResult;
}

- (void)dealloc {
    [_requestOperation release];
    [_methodResult release];
    [_error release];

    [super dealloc];
}
@end