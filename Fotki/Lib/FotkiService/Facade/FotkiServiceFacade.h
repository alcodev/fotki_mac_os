//
//  Created by aistomin on 1/9/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>

@class Album;
@class Folder;
@class AccountInfo;

typedef void (^ServiceFacadeCallback)(id);


@interface FotkiServiceFacade : NSObject {
    NSString *_sessionId;
    NSArray *_rootFolders;
}
@property(nonatomic, retain, readonly) NSString *sessionId;
@property(nonatomic, retain) AccountInfo *accountInfo;

- (void)authenticateWithLogin:(NSString *)login andPassword:(NSString *)password onSuccess:(ServiceFacadeCallback)onSuccess onError:(ServiceFacadeCallback)onError onForbidden:(ServiceFacadeCallback)onForbidden;

- (void)getAlbumsPlain:(ServiceFacadeCallback)onSuccess onError:(ServiceFacadeCallback)onError;

- (void)getAlbums:(ServiceFacadeCallback)onSuccess onError:(ServiceFacadeCallback)onError;

- (void)getAlbumUrl:(id)AlbumId :(int *)albumId onSuccess:(ServiceFacadeCallback)onSuccess onError:(ServiceFacadeCallback)onError;

- (void)uploadPicture:(NSString *)path toTheAlbum:(Album *)album onSuccess:(ServiceFacadeCallback)onSuccess onError:(ServiceFacadeCallback)onError;

- (void)getPhotosFromTheAlbum:(Album *)album onSuccess:(ServiceFacadeCallback)onSuccess onError:(ServiceFacadeCallback)onError;

- (void)createFolder:(NSString *)name parentFolderId:(NSString *)parentFolderId onSuccess:(ServiceFacadeCallback)onSuccess onError:(ServiceFacadeCallback)onError;

- (void)createAlbum:(NSString *)name parentFolderId:(NSString *)parentFolderId onSuccess:(ServiceFacadeCallback)onSuccess onError:(ServiceFacadeCallback)onError;

- (void)logOut;

- (void)getPublicHomeFolder:(ServiceFacadeCallback)onSuccess onError:(ServiceFacadeCallback)onError;

- (NSString *)getAlbumUrl:(NSString *)albumId onSuccess:(ServiceFacadeCallback)onSuccess onError:(ServiceFacadeCallback)onError;

@end