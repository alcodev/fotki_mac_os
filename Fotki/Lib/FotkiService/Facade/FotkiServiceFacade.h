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
typedef void (^UploadProgressBlock)(NSInteger, NSInteger, NSInteger);


@interface FotkiServiceFacade : NSObject {
    NSString *_sessionId;
    NSArray *_rootFolders;
}
@property(nonatomic, retain, readonly) NSString *sessionId;
@property(nonatomic, retain) AccountInfo *accountInfo;
@property(nonatomic, retain) id dragStatusView;


- (BOOL)isLoggedIn;

- (void)logOut;

- (AccountInfo *)authenticateWithLogin:(NSString *)login andPassword:(NSString *)password;

- (AccountInfo *)getAccountInfo;

- (NSInteger)createFolder:(NSString *)name parentFolderId:(NSString *)parentFolderId;

- (NSInteger)createAlbum:(NSString *)name parentFolderId:(NSString *)parentFolderId;

- (NSArray *)getAlbumsPlain;

- (NSArray *)getFolders;

- (NSArray *)getAlbums;

- (NSString *)getAlbumUrl:(NSString *)albumId;

- (NSArray *)getPhotosFromTheAlbum:(Album *)album;

- (BOOL)checkCrc32:(NSString *)crc32 inAlbum:(Album *)album;

- (void)uploadImageAtPath:(NSString *)path crc32:(NSString *)crc32 toAlbum:(Album *)album uploadProgressBlock:(UploadProgressBlock)uploadProgressBlock;

@end