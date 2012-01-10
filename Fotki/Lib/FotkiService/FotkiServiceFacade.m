//
//  Created by aistomin on 1/9/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "FotkiServiceFacade.h"
#import "AFHTTPRequestOperation.h"
#import "AFHTTPClient.h"
#import "Consts.h"
#import "CXMLDocument.h"
#import "Album.h"


@implementation FotkiServiceFacade {

}

- (void)dealloc {
    [_sessionId release];
    [super dealloc];
}

- (void)authenticateWithLogin:(NSString *)login andPassword:(NSString *)password {

    NSURL *url = [NSURL URLWithString:FOTKI_SERVER_PATH];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
            login, @"login",
            password, @"password",
            nil];
    AFHTTPClient *httpClient = [[[AFHTTPClient alloc] initWithBaseURL:url] autorelease];
    [httpClient setDefaultHeader:@"Accept" value:@"text/xml"];
    [httpClient getPath:@"/new_session" parameters:params success:^(__unused AFHTTPRequestOperation *operation, id response) {
        CXMLDocument *document = [[[CXMLDocument alloc] initWithData:response options:0 error:nil] autorelease];
        NSArray *nodes = [document nodesForXPath:@"session/result" error:nil];
        NSXMLElement *element = [nodes objectAtIndex:0];
        NSString *resultValue = [element stringValue];
        LOG(@"result: %@", resultValue);

        nodes = [document nodesForXPath:@"//session_id" error:nil];
        element = [nodes objectAtIndex:0];
        NSString *sessionIdValue = [element stringValue];
        LOG(@"session_id: %@", sessionIdValue);
        if (resultValue) {
            _sessionId = [[NSString alloc] initWithString:sessionIdValue];
        }

    }           failure:^(__unused AFHTTPRequestOperation *operation, NSError *error) {
        LOG(@"error: %@", error);
    }];
}

- (void)getAlbumsPlain:(ServiceFacadeCallback)onFinish {

    NSURL *url = [NSURL URLWithString:FOTKI_SERVER_PATH];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
            _sessionId, @"session_id",
            nil];
    AFHTTPClient *httpClient = [[[AFHTTPClient alloc] initWithBaseURL:url] autorelease];
    [httpClient setDefaultHeader:@"Accept" value:@"text/xml"];
    [httpClient getPath:@"/get_albums_plain" parameters:params success:^(__unused AFHTTPRequestOperation *operation, id response) {
        CXMLDocument *document = [[[CXMLDocument alloc] initWithData:response options:0 error:nil] autorelease];
        NSArray *nodes = [document nodesForXPath:@"//album" error:nil];
        NSMutableArray *albums = [[[NSMutableArray alloc] init] autorelease];
        for (NSXMLElement *element in nodes) {
            NSString *albumName = [element stringValue];
            NSString *albumId = [[element attributeForName:@"id"] stringValue];
            Album *album = [[[Album alloc] initWithId:albumId andName:albumName] autorelease];
            [albums addObject:album];
        }

        if (onFinish) {
            onFinish(albums);
        }

    }           failure:^(__unused AFHTTPRequestOperation *operation, NSError *error) {
        LOG(@"error: %@", error);
    }];

}

- (void)uploadPicture:(NSString *)path toTheAlbum :(Album *)album onSuccess:(ServiceFacadeCallback)onSuccess onError:(ServiceFacadeCallback)onError {
    NSURL *url = [NSURL URLWithString:FOTKI_SERVER_PATH];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
            album.id, @"album_id",
            _sessionId, @"session_id",
            nil];
    AFHTTPClient *httpClient = [[[AFHTTPClient alloc] initWithBaseURL:url] autorelease];


    NSMutableURLRequest *request = [httpClient multipartFormRequestWithMethod:@"POST"
                                                                         path:@"/upload"
                                                                   parameters:params
                                                    constructingBodyWithBlock:^(id <AFMultipartFormData> formData) {
                                                        NSData *data = [NSData dataWithContentsOfFile:path];
                                                        [formData appendPartWithFileData:data name:@"photo" fileName:path mimeType:@"application/octet-stream"];
                                                    }];

    AFHTTPRequestOperation *requestOperation = [[[AFHTTPRequestOperation alloc] initWithRequest:request
    ] autorelease];

    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObjec) {
        CXMLDocument *document = [[[CXMLDocument alloc] initWithData:responseObjec options:0 error:nil] autorelease];
        NSArray *nodes = [document nodesForXPath:@"//result" error:nil];
        NSXMLElement *element = [nodes objectAtIndex:0];
        NSString *resultValue = [element stringValue];
        if ([@"error" isEqualToString:resultValue]) {
            nodes = [document nodesForXPath:@"//message" error:nil];
            element = [nodes objectAtIndex:0];
            NSString *errorMessageValue = [element stringValue];
            LOG(@"Error message: ", errorMessageValue);
            if (onError) {
                onError(errorMessageValue);
            }
        } else {
            if (onSuccess && [@"ok" isEqualToString:resultValue]) {
                onSuccess(nil);
            } else {
                LOG(@"Unknown response received: ", resultValue);
            }
        }
    }                                       failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        LOG(@"Upload failure", error);
    }];
    NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];
    [queue addOperation:requestOperation];
}


@end