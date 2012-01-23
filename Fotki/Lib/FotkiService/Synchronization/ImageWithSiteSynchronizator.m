//
//  Created by aistomin on 1/13/12.
//
//


#import "ImageWithSiteSynchronizator.h"
#import "FotkiServiceFacade.h"
#import "Error.h"
#import "Album.h"
#import "BadgeUtils.h"
#import "FoldersAndAlbumsProvider.h"


@implementation ImageWithSiteSynchronizator {

}

+ (void)addFile:(NSString *)filePath serviceFacade:(FotkiServiceFacade *)fotkiServiceFacade {
    [FoldersAndAlbumsProvider getAlbumByFilePath:filePath serviceFacade:fotkiServiceFacade onFinish:^(Album *album) {
        if (!album || [album isKindOfClass:[Error class]]) {
            LOG(@"Error uploading file: album not found. Error: %@", album);
            [BadgeUtils putErrorBadgeOnFileIconAtPath:filePath];
        } else {
            [fotkiServiceFacade uploadPicture:filePath toTheAlbum:album onSuccess:^(id object) {
                [BadgeUtils putCheckBadgeOnFileIconAtPath:filePath];
            }                         onError:^(Error *error) {
                LOG(@"Error uploading file: %@", error.message);
                [BadgeUtils putErrorBadgeOnFileIconAtPath:filePath];
            }];
        }
    }];

}

+ (void)deleteFile:(NSString *)filePath serviceFacade:(FotkiServiceFacade *)fotkiServiceFacade {
    NSString *fileName = [filePath lastPathComponent];
    [fotkiServiceFacade deletePhoto:fileName onSuccess:^(id object) {
        LOG(@"Photo successfully deleted.");
    }                       onError:^(Error *error) {
        LOG(@"Error occurred while deleting photo: %@", error);
    }];
}

@end