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
#import "FoldersAndAlbumsTreeBuilder.h"
#import "Photo.h"


@implementation FotkiServiceFacade {

}

- (void)dealloc {
    [_sessionId release];
    [_rootFolders release];
    [super dealloc];
}

- (void)authenticateWithLogin:(NSString *)login andPassword:(NSString *)password onSuccess:(ServiceFacadeCallback)onSuccess onError:(ServiceFacadeCallback)onError {

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
        if ([@"ok" isEqualToString:resultValue]) {
            nodes = [document nodesForXPath:@"//session_id" error:nil];
            element = [nodes objectAtIndex:0];
            NSString *sessionIdValue = [element stringValue];
            _sessionId = [[NSString alloc] initWithString:sessionIdValue];
            if (onSuccess) {
                onSuccess(sessionIdValue);
            }
        } else {
            if ([@"error" isEqualToString:resultValue]) {
                nodes = [document nodesForXPath:@"//message" error:nil];
                element = [nodes objectAtIndex:0];
                NSString *errorMessage = [element stringValue];
                if (onError) {
                    onError(errorMessage);
                }
            } else {
                if (onError) {
                    onError(@"Unknown result");
                }
            }
        }
    }           failure:^(__unused AFHTTPRequestOperation *operation, NSError *error) {
        if (onError) {
            onError(error);
        }
    }];
}

- (void)getAlbumsPlain:(ServiceFacadeCallback)onSuccess onError:(ServiceFacadeCallback)onError {
    if (!_sessionId) {
        if (onError) {
            onError(@"User is not authorized");
        }
        return;
    }
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

        if (onSuccess) {
            onSuccess(albums);
        }

    }           failure:^(__unused AFHTTPRequestOperation *operation, NSError *error) {
        if (onError) {
            onError(error);
        }
    }];

}

- (void)getAlbums:(ServiceFacadeCallback)onSuccess onError:(ServiceFacadeCallback)onError {
    if (!_sessionId) {
        if (onError) {
            onError(@"User is not authorized");
        }
        return;
    }
    NSURL *url = [NSURL URLWithString:FOTKI_SERVER_PATH];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
            _sessionId, @"session_id",
            nil];
    AFHTTPClient *httpClient = [[[AFHTTPClient alloc] initWithBaseURL:url] autorelease];
    [httpClient setDefaultHeader:@"Accept" value:@"text/xml"];
    [httpClient getPath:@"/get_albums" parameters:params success:^(__unused AFHTTPRequestOperation *operation, id response) {
        CXMLDocument *document = [[[CXMLDocument alloc] initWithData:response options:0 error:nil] autorelease];
        _rootFolders = [[FoldersAndAlbumsTreeBuilder buildTreeFromXmlDocument:document] retain];
        if (onSuccess) {
            onSuccess(_rootFolders);
        }
    }           failure:^(__unused AFHTTPRequestOperation *operation, NSError *error) {
        if (onError) {
            onError(error);
        }
    }];

}

- (void)uploadPicture:(NSString *)path toTheAlbum :(Album *)album onSuccess:(ServiceFacadeCallback)onSuccess onError:(ServiceFacadeCallback)onError {
    if (!_sessionId) {
        if (onError) {
            onError(@"User is not authorized");
        }
        return;
    }
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
            LOG(@"Error message: %@", errorMessageValue);
            if (onError) {
                onError(errorMessageValue);
            }
        } else {
            if (onSuccess && [@"ok" isEqualToString:resultValue]) {
                onSuccess(nil);
            } else {
                if (onError) {
                    onError([NSString stringWithFormat:@"Unknown result: %@", resultValue]);
                }
            }
        }
    }                                       failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (onError) {
            onError(error);
        }
    }];
    NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];
    [queue addOperation:requestOperation];
}

- (void)getPhotosFromTheAlbum:(Album *)album onSuccess:(ServiceFacadeCallback)onSuccess onError:(ServiceFacadeCallback)onError {
    if (!_sessionId) {
        if (onError) {
            onError(@"User is not authorized");
        }
        return;
    }
    NSURL *url = [NSURL URLWithString:FOTKI_SERVER_PATH];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
            _sessionId, @"session_id",
            album.id, @"album_id",
            nil];
    AFHTTPClient *httpClient = [[[AFHTTPClient alloc] initWithBaseURL:url] autorelease];
    [httpClient setDefaultHeader:@"Accept" value:@"text/xml"];
    [httpClient getPath:@"/get_photos" parameters:params success:^(__unused AFHTTPRequestOperation *operation, id response) {
        CXMLDocument *document = [[[CXMLDocument alloc] initWithData:response options:0 error:nil] autorelease];
        NSArray *nodes = [document nodesForXPath:@"//result" error:nil];
        NSXMLElement *element = [nodes objectAtIndex:0];
        NSString *resultValue = [element stringValue];
        if ([@"ok" isEqualToString:resultValue]) {
            NSMutableArray *photos = [[[NSMutableArray alloc] init] autorelease];
            nodes = [document nodesForXPath:@"//album/@id" error:nil];
            element = [nodes objectAtIndex:0];
            NSString *albumId = [element stringValue];

            nodes = [document nodesForXPath:@"///photo" error:nil];
            for (NSXMLElement *photoElement in nodes) {
                NSXMLElement *idElement = [[photoElement nodesForXPath:@"./@id" error:nil] objectAtIndex:0];
                NSString *id = [idElement stringValue];
                NSXMLElement *titleElement = [[photoElement nodesForXPath:@"./title" error:nil] objectAtIndex:0];
                NSString *title = [titleElement stringValue];
                NSXMLElement *originalUrlElement = [[photoElement nodesForXPath:@"./view_url" error:nil] objectAtIndex:0];
                NSString *originalUrl = [originalUrlElement stringValue];
                Photo *photo = [[[Photo alloc] initWithId:id title:title originalUrl:originalUrl albumId:albumId] autorelease];
                [photos addObject:photo];
            }

            if (onSuccess) {
                onSuccess(photos);
            }
        } else {
            if ([@"error" isEqualToString:resultValue]) {
                nodes = [document nodesForXPath:@"//message" error:nil];
                element = [nodes objectAtIndex:0];
                NSString *errorMessage = [element stringValue];
                if (onError) {
                    onError(errorMessage);
                }
            } else {
                if (onError) {
                    onError([NSString stringWithFormat:@"Unknown result: %@", resultValue]);;
                }
            }
        }

    }           failure:^(__unused AFHTTPRequestOperation *operation, NSError *error) {
        LOG(@"error: %@", error);
    }];
}

- (void)createFolder:(NSString *)name parentFolderId:(NSString *)parentFolderId onSuccess:(ServiceFacadeCallback)onSuccess onError:(ServiceFacadeCallback)onError {
    if (!_sessionId) {
        if (onError) {
            onError(@"User is not authorized");
        }
        return;
    }
    NSURL *url = [NSURL URLWithString:FOTKI_SERVER_PATH];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
            _sessionId, @"session_id",
            parentFolderId, @"folder_id",
            name, @"name",
            nil];
    AFHTTPClient *httpClient = [[[AFHTTPClient alloc] initWithBaseURL:url] autorelease];
    [httpClient setDefaultHeader:@"Accept" value:@"text/xml"];
    [httpClient getPath:@"/create_folder" parameters:params success:^(__unused AFHTTPRequestOperation *operation, id response) {
        CXMLDocument *document = [[[CXMLDocument alloc] initWithData:response options:0 error:nil] autorelease];
        NSArray *nodes = [document nodesForXPath:@"create_folder/result" error:nil];
        NSXMLElement *element = [nodes objectAtIndex:0];
        NSString *resultValue = [element stringValue];
        if ([@"ok" isEqualToString:resultValue]) {
            nodes = [document nodesForXPath:@"//folder_id" error:nil];
            element = [nodes objectAtIndex:0];
            NSString *folderIdValue = [element stringValue];
            _sessionId = [[NSString alloc] initWithString:folderIdValue];
            if (onSuccess) {
                onSuccess(folderIdValue);
            }
        } else {
            if ([@"error" isEqualToString:resultValue]) {
                nodes = [document nodesForXPath:@"//message" error:nil];
                element = [nodes objectAtIndex:0];
                NSString *errorMessage = [element stringValue];
                if (onError) {
                    onError(errorMessage);
                }
            } else {
                if (onError) {
                    onError(@"Unknown result");
                }
            }
        }
    }           failure:^(__unused AFHTTPRequestOperation *operation, NSError *error) {
        if (onError) {
            onError(error);
        }
    }];
}

- (void)createAlbum:(NSString *)name parentFolderId:(NSString *)parentFolderId onSuccess:(ServiceFacadeCallback)onSuccess onError:(ServiceFacadeCallback)onError {
    if (!_sessionId) {
        if (onError) {
            onError(@"User is not authorized");
        }
        return;
    }
    NSURL *url = [NSURL URLWithString:FOTKI_SERVER_PATH];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
            _sessionId, @"session_id",
            parentFolderId, @"folder_id",
            name, @"name",
            nil];
    AFHTTPClient *httpClient = [[[AFHTTPClient alloc] initWithBaseURL:url] autorelease];
    [httpClient setDefaultHeader:@"Accept" value:@"text/xml"];
    [httpClient getPath:@"/create_album" parameters:params success:^(__unused AFHTTPRequestOperation *operation, id response) {
        CXMLDocument *document = [[[CXMLDocument alloc] initWithData:response options:0 error:nil] autorelease];
        NSArray *nodes = [document nodesForXPath:@"create_album/result" error:nil];
        NSXMLElement *element = [nodes objectAtIndex:0];
        NSString *resultValue = [element stringValue];
        if ([@"ok" isEqualToString:resultValue]) {
            nodes = [document nodesForXPath:@"//album_id" error:nil];
            element = [nodes objectAtIndex:0];
            NSString *folderIdValue = [element stringValue];
            _sessionId = [[NSString alloc] initWithString:folderIdValue];
            if (onSuccess) {
                onSuccess(folderIdValue);
            }
        } else {
            if ([@"error" isEqualToString:resultValue]) {
                nodes = [document nodesForXPath:@"//message" error:nil];
                element = [nodes objectAtIndex:0];
                NSString *errorMessage = [element stringValue];
                if (onError) {
                    onError(errorMessage);
                }
            } else {
                if (onError) {
                    onError(@"Unknown result");
                }
            }
        }
    }           failure:^(__unused AFHTTPRequestOperation *operation, NSError *error) {
        if (onError) {
            onError(error);
        }
    }];
}

@end