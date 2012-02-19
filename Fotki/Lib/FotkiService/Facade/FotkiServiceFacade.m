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
#import "Folder.h"
#import "AccountInfo.h"
#import "ApiServiceException.h"
#import "AlbumsExtracter.h"


@interface FotkiServiceFacade ()

- (void)callServiceFacadeCallback:(ServiceFacadeCallback)callback withObject:(id)object;

@end

@implementation FotkiServiceFacade

@synthesize sessionId = _sessionId;
@synthesize accountInfo = _accountInfo;


- (void)dealloc {
    [_sessionId release];
    [_rootFolders release];
    [_accountInfo release];
    [super dealloc];
}

- (void)callServiceFacadeCallback:(ServiceFacadeCallback)callback withObject:(id)object {
    if (callback) {
        callback(object);
    }
}

- (BOOL)isLoggedIn {
    return _sessionId != nil;
}

- (void)logOut {
    if (!_sessionId) {
        LOG(@"User is not authorized");
    } else {
        _sessionId = nil;
    }
}

- (AccountInfo *)authenticateWithLogin:(NSString *)login andPassword:(NSString *)password {
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
            login, @"login",
            password, @"password",
            nil];

    id document = [ServiceUtils syncProcessXmlRequestForUrl:FOTKI_SERVER_PATH andPath:@"/new_session" andParams:params];
    NSArray *nodes = [document nodesForXPath:@"//session_id" error:nil];
    NSXMLElement *element = [nodes objectAtIndex:0];
    NSString *sessionIdValue = [element stringValue];
    _sessionId = [[NSString alloc] initWithString:sessionIdValue];

    return [self getAccountInfo];
}

- (AccountInfo *)getAccountInfo {
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
            _sessionId, @"session_id",
            nil];

    id document = [ServiceUtils syncProcessXmlRequestForUrl:FOTKI_SERVER_PATH andPath:@"/get_account_info" andParams:params];
    NSArray *nodes = [document nodesForXPath:@"//disp_name" error:nil];

    NSXMLElement *element = [nodes objectAtIndex:0];
    NSString *displayName = [element stringValue];

    nodes = [document nodesForXPath:@"//space_used" error:nil];
    element = [nodes objectAtIndex:0];
    NSString *spaceUsed = [element stringValue];

    nodes = [document nodesForXPath:@"//space_limit" error:nil];
    element = [nodes objectAtIndex:0];
    NSString *spaceLimit = [element stringValue];

    return [[[AccountInfo alloc] initWithName:displayName spaceLimit:spaceLimit spaceUsed:spaceUsed] autorelease];
}

- (NSInteger)createFolder:(NSString *)name parentFolderId:(NSString *)parentFolderId {
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
        _sessionId, @"session_id",
        parentFolderId, @"folder_id",
        name, @"name",
        nil
    ];

    id document = [ServiceUtils syncProcessXmlRequestForUrl:FOTKI_SERVER_PATH andPath:@"/create_folder" andParams:params];
    NSArray *nodes = [document nodesForXPath:@"//folder_id" error:nil];
    NSXMLElement *element = [nodes objectAtIndex:0];
    return [[element stringValue] integerValue];
}

- (NSInteger)createAlbum:(NSString *)name parentFolderId:(NSString *)parentFolderId {
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
        _sessionId, @"session_id",
        parentFolderId, @"folder_id",
        name, @"name",
        nil
    ];

    id document = [ServiceUtils syncProcessXmlRequestForUrl:FOTKI_SERVER_PATH andPath:@"/create_album" andParams:params];
    NSArray *nodes = [document nodesForXPath:@"//album_id" error:nil];
    NSXMLElement *element = [nodes objectAtIndex:0];
    return [[element stringValue] integerValue];
}

- (NSArray *)getAlbumsPlain {
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
        _sessionId, @"session_id",
        nil
    ];

    id document = [ServiceUtils syncProcessXmlRequestForUrl:FOTKI_SERVER_PATH andPath:@"/get_albums_plain" andParams:params];
    NSArray *nodes = [document nodesForXPath:@"//album" error:nil];
    NSMutableArray *albums = [[[NSMutableArray alloc] init] autorelease];
    for (NSXMLElement *element in nodes) {
        NSString *albumName = [element stringValue];
        NSString *albumId = [[element attributeForName:@"id"] stringValue];
        [albums addObject:[[[Album alloc] initWithId:albumId andName:albumName] autorelease]];
    }

    return albums;
}

- (NSArray *)getFolders {
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
        _sessionId, @"session_id",
        nil
    ];

    id document = [ServiceUtils syncProcessXmlRequestForUrl:FOTKI_SERVER_PATH andPath:@"/get_albums" andParams:params];
    return [FoldersAndAlbumsTreeBuilder buildTreeFromXmlDocument:document];
}

- (NSArray *)getAlbums {
    NSArray *rootFolders = [self getFolders];
    return [AlbumsExtracter extractAlbums:rootFolders];
}

- (id)getPublicHomeFolder {
    NSArray *rootFolders = [self getFolders];
    for (Folder *folder in rootFolders) {
        if ([DEFAULT_FOLDER_NAME isEqualToString:folder.name]) {
            return folder;
        }
    }

    return nil;
}

- (NSString *)getAlbumUrl:(NSString *)albumId {
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
        _sessionId, @"session_id",
        albumId, @"album_id",
        nil
    ];

    id document = [ServiceUtils syncProcessXmlRequestForUrl:FOTKI_SERVER_PATH andPath:@"/get_album_url" andParams:params];
    NSArray *nodes = [document nodesForXPath:@"//url" error:nil];
    NSXMLElement *element = [nodes objectAtIndex:0];
    return [element stringValue];
}

- (NSArray *)getPhotosFromTheAlbum:(Album *)album {
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
        _sessionId, @"session_id",
        album.id, @"album_id",
        nil
    ];

    id document = [ServiceUtils syncProcessXmlRequestForUrl:FOTKI_SERVER_PATH andPath:@"/get_photos" andParams:params];
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

    return photos;
}

- (BOOL)checkCrc32:(NSString *)crc32 inAlbum :(Album *)album {
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
        album.id, @"album_id",
        _sessionId, @"session_id",
        crc32, @"crc32",
        nil
    ];

    //TODO: check if this fucking logic is valid
    @try {
        id document = [ServiceUtils syncProcessXmlRequestForUrl:FOTKI_SERVER_PATH andPath:@"/check_crc32" andParams:params];
        NSArray *nodes = [document nodesForXPath:@"//exists" error:nil];
        NSXMLElement *element = [nodes objectAtIndex:0];
        return [element stringValue] != nil;
    } @catch (ApiServiceException *ex) {
        return NO;
    }
}

- (void)uploadImageAtPath:(NSString *)path crc32:(NSString *)crc32 toAlbum :(Album *)album uploadProgressBlock:(UploadProgressBlock)uploadProgressBlock {
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
            album.id, @"album_id",
            _sessionId, @"session_id",
            crc32, @"crc32",
            nil
    ];

    [ServiceUtils syncProcessImageRequestForUrl:FOTKI_SERVER_PATH path:@"/upload" params:params name:@"photo" imagePath:path uploadProgressBlock:uploadProgressBlock];
}

@end