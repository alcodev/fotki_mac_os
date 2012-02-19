//
//  Created by vavaka on 1/3/12.



#import <Foundation/Foundation.h>

@class AFHTTPRequestOperation;


@interface ApiCallResult : NSObject

@property(nonatomic, retain) AFHTTPRequestOperation *requestOperation;
@property(nonatomic, retain) id methodResult;
@property(assign) BOOL isSuccess;
@property(nonatomic, retain) NSError *error;

+ (id)successResultWithRequestOperation:(AFHTTPRequestOperation *)requestOperation methodResult:(id)methodResult;

+ (id)errorResultWithRequestOperation:(AFHTTPRequestOperation *)requestOperation error:(NSError *)error;

@end