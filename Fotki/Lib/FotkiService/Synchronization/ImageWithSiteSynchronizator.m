//
//  Created by aistomin on 1/13/12.
//
//


#import "ImageWithSiteSynchronizator.h"
#import "Consts.h"
#import "FotkiServiceFacade.h"
#import "Error.h"
#import "Folder.h"
#import "Album.h"
#import "BadgeUtils.h"


@implementation ImageWithSiteSynchronizator {

}

+ (Folder *)searchFolderWithName:(id)name inFolders:(NSMutableArray *)folders {
    for (Folder *folder in  folders) {
        if ([name isEqualToString:folder.name]) {
            return (folder);
        }
    }
    return (nil);
}

+ (Album *)searchAlbumWithName:(NSString *)name inAlbums:(NSMutableArray *)albums {
    for (Album *album in  albums) {
        if ([name isEqualToString:album.name]) {
            return (album);
        }
    }
    return (nil);
}

+ (void)synchronize:(NSString *)filePath serviceFacade:(FotkiServiceFacade *)fotkiServiceFacade {
    NSString *relativeFilePath = [filePath stringByReplacingOccurrencesOfString:FOTKI_PATH withString:@""];
    relativeFilePath = [relativeFilePath substringFromIndex:1]; //remove first "/" in the path
    NSArray *foldersWithAlbumInRelativePath = [[relativeFilePath stringByDeletingLastPathComponent] pathComponents];
    [fotkiServiceFacade getAlbums:^(NSMutableArray *rootFolders) {
        NSMutableArray *foldersToFindIn = rootFolders;
        Folder *folder = nil;
        for (int i = 0; i < [foldersWithAlbumInRelativePath count] - 1; i++) {
            NSString *folderName = [foldersWithAlbumInRelativePath objectAtIndex:i];
            folder = [self searchFolderWithName:folderName inFolders:foldersToFindIn];
            if (folder) {
                foldersToFindIn = folder.childFolders;
            } else {
                LOG(@"Folder with name: %@ does not exist.", folderName);
                break;
            }
        }
        if (folder) {
            NSUInteger albumNameIndex = [foldersWithAlbumInRelativePath count] - 1;
            NSString *albumName = [foldersWithAlbumInRelativePath objectAtIndex:albumNameIndex];
            Album *album = [self searchAlbumWithName:albumName inAlbums:folder.childAlbums];
            if (album) {
                [fotkiServiceFacade uploadPicture:filePath toTheAlbum:album onSuccess:^(id object) {
                    [BadgeUtils putCheckBadgeOnFileIconAtPath:filePath];
                }                         onError:^(Error *error) {
                    LOG(@"Error uploading file: %@", error.message);
                    [BadgeUtils putErrorBadgeOnFileIconAtPath:filePath];
                }];
            }
        }
    }                     onError:^(Error *error) {
        LOG(@"Error synchronizing file: %@", error.message);
        [BadgeUtils putErrorBadgeOnFileIconAtPath:filePath];
    }];

}
@end