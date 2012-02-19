//
//  Created by aistomin on 1/12/12.
//
//


#import "ServiceUtils.h"
#import "AFHTTPClient.h"
#import "CXMLDocument.h"
#import "ErrorResponseParser.h"
#import "Error.h"
#import "ApiCallResult.h"
#import "Consts.h"
#import "AFHTTPRequestOperation.h"
#import "NSThread+Helper.h"
#import "Async2SyncLock.h"
#import "ApiAuthenticationException.h"
#import "ApiConnectionException.h"
#import "ApiCallResult.h"
#import "ApiNotFoundException.h"
#import "ApiServiceException.h"


typedef void (^ApiSyncCallback)(ApiCallback doneCallback);

@interface ServiceUtils ()
+ (void)callServiceFacadeCallback:(ServiceFacadeCallback)callback withObject:(id)object;

+ (id)callAsyncApiMethodSynchronously:(ApiSyncCallback)callback;

@end

@implementation ServiceUtils

+ (void)callServiceFacadeCallback:(ServiceFacadeCallback)callback withObject:(id)object {
    if (callback) {
        callback(object);
    }
}

+ (id)callAsyncApiMethodSynchronously:(ApiSyncCallback)callback {
    __block ApiCallResult *syncResult = nil;
    [NSThread runAsyncBlockSynchronously:^(Async2SyncLock *lock) {
        callback(^(ApiCallResult *asyncResult) {
            syncResult = [asyncResult retain];
            [lock asyncFinished];
        });
    }];

    if (!syncResult.isSuccess) {
        if (syncResult.requestOperation.response.statusCode == 401) {
            @throw [ApiAuthenticationException exceptionWithReason:syncResult.requestOperation.responseString];
        } else if (syncResult.requestOperation.response.statusCode == 404) {
            @throw [ApiNotFoundException exceptionWithReason:syncResult.requestOperation.responseString];
        } else {
            @throw [ApiConnectionException exceptionWithReason:syncResult.error.description];
        }
    }

    NSArray *nodes = [syncResult.methodResult nodesForXPath:@"//result" error:nil];
    NSXMLElement *element = [nodes objectAtIndex:0];
    NSString *resultValue = [element stringValue];
    if (![@"ok" isEqualToString:resultValue]) {
        if ([@"error" isEqualToString:resultValue]) {
            @throw [ApiServiceException exceptionWithReason:[ErrorResponseParser extractErrorFromXmlDocument:syncResult.methodResult]];
        } else {
            @throw [ApiServiceException exceptionWithReason:[NSString stringWithFormat:@"Unknown result: %@", resultValue]];
        }
    }

    [syncResult autorelease];
    return [[syncResult.methodResult retain] autorelease];
}

+ (void)asyncProcessXmlRequestForUrl:(NSString *)serviceUrl andPath:(NSString *)path andParams:(NSDictionary *)params finishCallback:(ApiCallback)finishCallback {
    NSURL *url = [NSURL URLWithString:serviceUrl];

    AFHTTPClient *httpClient = [[[AFHTTPClient alloc] initWithBaseURL:url] autorelease];
    [httpClient setDefaultHeader:@"Accept" value:@"text/xml"];
    [httpClient getPath:path parameters:params success:^(__unused AFHTTPRequestOperation *operation, id response) {
        if (finishCallback) {
            CXMLDocument *document = [[[CXMLDocument alloc] initWithData:response options:0 error:nil] autorelease];
            finishCallback([ApiCallResult successResultWithRequestOperation:operation methodResult:document]);
        }
    } failure:^(__unused AFHTTPRequestOperation *operation, NSError *error) {
        if (finishCallback) {
            finishCallback([ApiCallResult errorResultWithRequestOperation:operation error:error]);
        }
    }];
}

+ (id)syncProcessXmlRequestForUrl:(NSString *)serviceUrl andPath:(NSString *)path andParams:(NSDictionary *)params {
    return [ServiceUtils callAsyncApiMethodSynchronously:^(ApiCallback doneCallback) {
        [self asyncProcessXmlRequestForUrl:serviceUrl andPath:path andParams:params finishCallback:^(ApiCallResult *result) {
            doneCallback(result);
        }];
    }];
}

+ (void)asyncProcessImageRequestForUrl:(NSString *)serviceUrl path:(NSString *)path params:(NSDictionary *)params name:(NSString *)name imagePath:(NSString *)imagePath finishCallback:(ApiCallback)finishCallback uploadProgressBlock:(UploadProgressBlock)uploadProgressBlock{
    NSURL *url = [NSURL URLWithString:serviceUrl];

    AFHTTPClient *httpClient = [[[AFHTTPClient alloc] initWithBaseURL:url] autorelease];


    NSMutableURLRequest *request = [httpClient multipartFormRequestWithMethod:@"POST" path:path parameters:params constructingBodyWithBlock:^(id <AFMultipartFormData> formData) {
        NSData *data = [NSData dataWithContentsOfFile:imagePath];
        [formData appendPartWithFileData:data name:name fileName:imagePath mimeType:@"application/octet-stream"];
    }];

    AFHTTPRequestOperation *requestOperation = [[[AFHTTPRequestOperation alloc] initWithRequest:request] autorelease];
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id response) {
        if (finishCallback) {
            CXMLDocument *document = [[[CXMLDocument alloc] initWithData:response options:0 error:nil] autorelease];
            finishCallback([ApiCallResult successResultWithRequestOperation:operation methodResult:document]);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (finishCallback) {
            finishCallback([ApiCallResult errorResultWithRequestOperation:operation error:error]);
        }
    }];
    [requestOperation setUploadProgressBlock:uploadProgressBlock];
    [requestOperation start];
}

+ (id)syncProcessImageRequestForUrl:(NSString *)serviceUrl path:(NSString *)path params:(NSDictionary *)params name:(NSString *)name imagePath:(NSString *)imagePath uploadProgressBlock:(UploadProgressBlock)uploadProgressBlock{
    return [ServiceUtils callAsyncApiMethodSynchronously:^(ApiCallback doneCallback) {
        [self asyncProcessImageRequestForUrl:serviceUrl path:path params:params name:name imagePath:imagePath finishCallback:^(ApiCallResult *result) {
            doneCallback(result);
        } uploadProgressBlock:uploadProgressBlock];
    }];
}
@end