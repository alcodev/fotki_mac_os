//
//  Created by aistomin on 1/12/12.
//
//


#import "ServiceUtils.h"
#import "AFHTTPClient.h"
#import "CXMLDocument.h"
#import "ErrorResponseParser.h"
#import "Error.h"
#import "Consts.h"
#import "ServiceFacadeCallbackCaller.h"
#import "AFHTTPRequestOperation.h"


@implementation ServiceUtils {

}


+ (void)processXmlRequestForUrl:(NSString *)servideUrl andPath:(NSString *)path andParams:(NSDictionary *)params onSuccess:(ServiceFacadeCallback)onSuccess onError:(ServiceFacadeCallback)onError {
    NSURL *url = [NSURL URLWithString:servideUrl];

    AFHTTPClient *httpClient = [[[AFHTTPClient alloc] initWithBaseURL:url] autorelease];
    [httpClient setDefaultHeader:@"Accept" value:@"text/xml"];
    [httpClient getPath:path parameters:params success:^(__unused AFHTTPRequestOperation *operation, id response) {
        CXMLDocument *document = [[[CXMLDocument alloc] initWithData:response options:0 error:nil] autorelease];
        NSArray *nodes = [document nodesForXPath:@"//result" error:nil];
        NSXMLElement *element = [nodes objectAtIndex:0];
        NSString *resultValue = [element stringValue];
        if ([@"ok" isEqualToString:resultValue]) {
            [ServiceFacadeCallbackCaller callServiceFacadeCallback:onSuccess withObject:document];
        } else {
            if ([@"error" isEqualToString:resultValue]) {
                Error *error = [ErrorResponseParser extractErrorFromXmlDocument:document];
                [ServiceFacadeCallbackCaller callServiceFacadeCallback:onError withObject:error];
            } else {
                Error *error = [[[Error alloc] initWithId:DEFAULT_ERROR_CODE andMessage:[NSString stringWithFormat:@"Unknown result: %@", resultValue]] autorelease];
                [ServiceFacadeCallbackCaller callServiceFacadeCallback:onError withObject:error];
            }
        }
    }           failure:^(__unused AFHTTPRequestOperation *operation, NSError *receivedError) {
        Error *error = [[[Error alloc] initWithId:DEFAULT_ERROR_CODE andMessage:[NSString stringWithFormat:@"Unknown result: %@", receivedError]] autorelease];
        [ServiceFacadeCallbackCaller callServiceFacadeCallback:onError withObject:error];
    }];

}

+ (void)processImageRequestForUrl:(NSString *)serviceUrl path:(NSString *)path params:(NSDictionary *)params name:(NSString *)name imagePath:(NSString *)imagePath onSuccess:(ServiceFacadeCallback)onSuccess onError:(ServiceFacadeCallback)onError {
    NSURL *url = [NSURL URLWithString:serviceUrl];

    AFHTTPClient *httpClient = [[[AFHTTPClient alloc] initWithBaseURL:url] autorelease];


    NSMutableURLRequest *request = [httpClient multipartFormRequestWithMethod:@"POST"
                                                                         path:path
                                                                   parameters:params
                                                    constructingBodyWithBlock:^(id <AFMultipartFormData> formData) {
                                                        NSData *data = [NSData dataWithContentsOfFile:imagePath];
                                                        [formData appendPartWithFileData:data name:name fileName:imagePath mimeType:@"application/octet-stream"];
                                                    }];

    AFHTTPRequestOperation *requestOperation = [[[AFHTTPRequestOperation alloc] initWithRequest:request] autorelease];

    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObjec) {
        CXMLDocument *document = [[[CXMLDocument alloc] initWithData:responseObjec options:0 error:nil] autorelease];
        NSArray *nodes = [document nodesForXPath:@"//result" error:nil];
        NSXMLElement *element = [nodes objectAtIndex:0];
        NSString *resultValue = [element stringValue];
        if ([@"error" isEqualToString:resultValue]) {
            Error *error = [ErrorResponseParser extractErrorFromXmlDocument:document];
            [ServiceFacadeCallbackCaller callServiceFacadeCallback:onError withObject:error];
        } else {
            if ([@"ok" isEqualToString:resultValue]) {
                [ServiceFacadeCallbackCaller callServiceFacadeCallback:onSuccess withObject:nil];
            } else {
                Error *error = [[[Error alloc] initWithId:DEFAULT_ERROR_CODE andMessage:[NSString stringWithFormat:@"Unknown result: %@", resultValue]] autorelease];
                [ServiceFacadeCallbackCaller callServiceFacadeCallback:onError withObject:error];
            }
        }
    }                                       failure:^(AFHTTPRequestOperation *operation, NSError *receivedError) {
        Error *error = [[[Error alloc] initWithId:DEFAULT_ERROR_CODE andMessage:[NSString stringWithFormat:@"Unknown result: %@", receivedError]] autorelease];
        [ServiceFacadeCallbackCaller callServiceFacadeCallback:onError withObject:error];
    }];
    NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];
    [queue addOperation:requestOperation];

}

@end