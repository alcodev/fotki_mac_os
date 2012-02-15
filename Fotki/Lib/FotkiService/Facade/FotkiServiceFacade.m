//
//  Created by aistomin on 1/9/12.
//
//


#import "FotkiServiceFacade.h"
#import "Consts.h"
#import "CXMLDocument.h"
#import "Album.h"
#import "FoldersAndAlbumsTreeBuilder.h"
#import "Photo.h"
#import "ServiceUtils.h"
#import "ServiceFacadeCallbackCaller.h"
#import "Folder.h"
#import "AccountInfo.h"


@interface FotkiServiceFacade ()
- (void)getAccountInfo:(ServiceFacadeCallback)onSuccess onError:(ServiceFacadeCallback)onError onForbidden:(ServiceFacadeCallback)onForbidden;

- (void)getAlbumUrl:(NSString *)albumId onSuccess:(ServiceFacadeCallback)onSuccess onError:(ServiceFacadeCallback)onError;


- (BOOL)checkIsUserAuthenticated:(ServiceFacadeCallback)onError;

@end

@implementation FotkiServiceFacade {

}

@synthesize sessionId = _sessionId;
@synthesize accountInfo = _accountInfo;


- (void)dealloc {
    [_sessionId release];
    [_rootFolders release];
    [_accountInfo release];
    [super dealloc];
}

- (void)authenticateWithLogin:(NSString *)login andPassword:(NSString *)password onSuccess:(ServiceFacadeCallback)onSuccess onError:(ServiceFacadeCallback)onError onForbidden:(ServiceFacadeCallback)onForbidden{

        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                login, @"login",
                password, @"password",
                nil];
    [ServiceUtils processXmlRequestForUrl:FOTKI_SERVER_PATH andPath:@"/new_session" andParams:params onSuccess:^(id document) {
        NSArray *nodes = [document nodesForXPath:@"//session_id" error:nil];
        NSXMLElement *element = [nodes objectAtIndex:0];
        NSString *sessionIdValue = [element stringValue];
        _sessionId = [[NSString alloc] initWithString:sessionIdValue];
        if (![@"alcodev" isEqualToString:login]){
            [ServiceFacadeCallbackCaller callServiceFacadeCallback:onForbidden withObject:nil];
            _sessionId = nil;
            return;
        }
        [self getAccountInfo:^(id object){
            self.accountInfo = object;
            [ServiceFacadeCallbackCaller callServiceFacadeCallback:onSuccess withObject:sessionIdValue];
        } onError:onError onForbidden:onForbidden];
    }                             onError:onError];
}
- (void)getAccountInfo:(ServiceFacadeCallback)onSuccess onError:(ServiceFacadeCallback)onError onForbidden:(ServiceFacadeCallback)onForbidden{

    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
            _sessionId, @"session_id",
            nil];
    [ServiceUtils processXmlRequestForUrl:FOTKI_SERVER_PATH andPath:@"/get_account_info" andParams:params onSuccess:^(id document) {
        NSArray *nodes = [document nodesForXPath:@"//disp_name" error:nil];
        NSXMLElement *element = [nodes objectAtIndex:0];
        NSString *displayName = [element stringValue];
        nodes = [document nodesForXPath:@"//space_used" error:nil];
        element = [nodes objectAtIndex:0];
        NSString *spaceUsed = [element stringValue];
        nodes = [document nodesForXPath:@"//space_limit" error:nil];
        element = [nodes objectAtIndex:0];
        NSString *spaceLimit = [element stringValue];

        AccountInfo *accountInfo = [[AccountInfo alloc] initWithName:displayName spaceLimit:spaceLimit spaceUsed:spaceUsed];

        [ServiceFacadeCallbackCaller callServiceFacadeCallback:onSuccess withObject:accountInfo];

    }onError:onError];
}

- (void)getAlbumsPlain:(ServiceFacadeCallback)onSuccess onError:(ServiceFacadeCallback)onError {
    if ([self checkIsUserAuthenticated:onError]) {
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                _sessionId, @"session_id",
                nil];
        [ServiceUtils processXmlRequestForUrl:FOTKI_SERVER_PATH andPath:@"/get_albums_plain" andParams:params onSuccess:^(id document) {
            NSArray *nodes = [document nodesForXPath:@"//album" error:nil];
            NSMutableArray *albums = [[[NSMutableArray alloc] init] autorelease];
            for (NSXMLElement *element in nodes) {
                NSString *albumName = [element stringValue];
                NSString *albumId = [[element attributeForName:@"id"] stringValue];
                Album *album = [[[Album alloc] initWithId:albumId andName:albumName] autorelease];
                [albums addObject:album];
            }
            [ServiceFacadeCallbackCaller callServiceFacadeCallback:onSuccess withObject:albums];
        }                             onError:onError];
    }
}

- (void)getAlbums:(ServiceFacadeCallback)onSuccess onError:(ServiceFacadeCallback)onError {
    if ([self checkIsUserAuthenticated:onError]) {
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                _sessionId, @"session_id",
                nil];
        [ServiceUtils processXmlRequestForUrl:FOTKI_SERVER_PATH andPath:@"/get_albums" andParams:params onSuccess:^(id document) {
            _rootFolders = [[FoldersAndAlbumsTreeBuilder buildTreeFromXmlDocument:document] retain];
            [ServiceFacadeCallbackCaller callServiceFacadeCallback:onSuccess withObject:_rootFolders];
        }                             onError:onError];
    }
}
- (void)getAlbumUrl:(NSString *)albumId onSuccess:(ServiceFacadeCallback)onSuccess onError:(ServiceFacadeCallback)onError {
    if ([self checkIsUserAuthenticated:onError]) {
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                _sessionId, @"session_id",
                albumId, @"album_id",
                nil];
        [ServiceUtils processXmlRequestForUrl:FOTKI_SERVER_PATH andPath:@"/get_album_url" andParams:params onSuccess:^(id document) {
            NSMutableArray *photos = [[[NSMutableArray alloc] init] autorelease];
            NSArray *nodes = [document nodesForXPath:@"//url" error:nil];
            NSXMLElement *element = [nodes objectAtIndex:0];
            NSString *albumUrl = [element stringValue];
            [ServiceFacadeCallbackCaller callServiceFacadeCallback:onSuccess withObject:albumUrl];
        } onError:onError];
    }
}

- (void)uploadPicture:(NSString *)path crc32:(NSString *)crc32 toTheAlbum :(Album *)album onSuccess:(ServiceFacadeCallback)onSuccess onError:(ServiceFacadeCallback)onError {
    if ([self checkIsUserAuthenticated:onError]) {
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                album.id, @"album_id",
                _sessionId, @"session_id",
                crc32, @"crc32",
                nil];
        [ServiceUtils processImageRequestForUrl:FOTKI_SERVER_PATH path:@"/upload"
                                         params:params
                                           name:@"photo"
                                      imagePath:path
                                      onSuccess:onSuccess onError:onError];
    }
}

- (void)getPhotosFromTheAlbum:(Album *)album onSuccess:(ServiceFacadeCallback)onSuccess onError:(ServiceFacadeCallback)onError {
    if ([self checkIsUserAuthenticated:onError]) {
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                _sessionId, @"session_id",
                album.id, @"album_id",
                nil];
        [ServiceUtils processXmlRequestForUrl:FOTKI_SERVER_PATH andPath:@"/get_photos" andParams:params onSuccess:^(id document) {
            NSMutableArray *photos = [[[NSMutableArray alloc] init] autorelease];
            NSArray *nodes = [document nodesForXPath:@"//album/@id" error:nil];
            NSXMLElement *element = [nodes objectAtIndex:0];
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
            [ServiceFacadeCallbackCaller callServiceFacadeCallback:onSuccess withObject:photos];
        }                             onError:onError];
    }
}

- (void)createFolder:(NSString *)name parentFolderId:(NSString *)parentFolderId onSuccess:(ServiceFacadeCallback)onSuccess onError:(ServiceFacadeCallback)onError {
    if ([self checkIsUserAuthenticated:onError]) {
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                _sessionId, @"session_id",
                parentFolderId, @"folder_id",
                name, @"name",
                nil];
        [ServiceUtils processXmlRequestForUrl:FOTKI_SERVER_PATH andPath:@"/create_folder" andParams:params onSuccess:^(id document) {
            NSArray *nodes = [document nodesForXPath:@"//folder_id" error:nil];
            NSXMLElement *element = [nodes objectAtIndex:0];
            NSString *folderIdValue = [element stringValue];
            [ServiceFacadeCallbackCaller callServiceFacadeCallback:onSuccess withObject:folderIdValue];
        }                             onError:onError];
    }
}

- (void)createAlbum:(NSString *)name parentFolderId:(NSString *)parentFolderId onSuccess:(ServiceFacadeCallback)onSuccess onError:(ServiceFacadeCallback)onError {
    if ([self checkIsUserAuthenticated:onError]) {
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                _sessionId, @"session_id",
                parentFolderId, @"folder_id",
                name, @"name",
                nil];
        [ServiceUtils processXmlRequestForUrl:FOTKI_SERVER_PATH andPath:@"/create_album" andParams:params onSuccess:^(id document) {
            NSArray *nodes = [document nodesForXPath:@"//album_id" error:nil];
            NSXMLElement *element = [nodes objectAtIndex:0];
            NSString *albumIdValue = [element stringValue];
            [ServiceFacadeCallbackCaller callServiceFacadeCallback:onSuccess withObject:albumIdValue];
        }                             onError:onError];
    }
}

- (BOOL)checkIsUserAuthenticated:(ServiceFacadeCallback)onError {
    if (!_sessionId) {
        if (onError) {
            onError(@"User is not authorized");
        }
        return (NO);
    } else {
        return (YES);
    }
}
- (void)logOut {
    if (!_sessionId) {
        LOG(@"User is not authorized");
    } else {
        _sessionId = nil;
    }
}

- (void)getPublicHomeFolder:(ServiceFacadeCallback)onSuccess onError:(ServiceFacadeCallback)onError {
    [self getAlbums:^(NSMutableArray *rootFolders) {
        for (Folder *folder in rootFolders) {
            if ([DEFAULT_FOLDER_NAME isEqualToString:folder.name]) {
                [ServiceFacadeCallbackCaller callServiceFacadeCallback:onSuccess withObject:folder];
                return;
            }
            [ServiceFacadeCallbackCaller callServiceFacadeCallback:onSuccess withObject:nil];
        }
    }       onError:onError];
}
@end