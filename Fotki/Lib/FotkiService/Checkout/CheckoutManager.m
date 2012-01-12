//
//  Created by aistomin on 1/12/12.
//
//


#import "CheckoutManager.h"
#import "Folder.h"
#import "Album.h"
#import "Error.h"
#import "ImageDownloader.h"
#import "Photo.h"
#import "NSThread+Helper.h"
#import "Async2SyncLock.h"


@implementation CheckoutManager {
}


+ (void)createAlbums:(NSMutableArray *)albums inDirectory:(NSString *)directory withFileManager:(NSFileManager *)fileManager serviceFacade:(FotkiServiceFacade *)serviceFacade {
    for (Album *album in albums) {
        NSString *albumsDirectory = [NSString stringWithFormat:@"%@/%@", directory, album.name];
        [fileManager createDirectoryAtPath:albumsDirectory withIntermediateDirectories:YES attributes:nil error:nil];
        LOG(@"Run async block synchronously");
        [NSThread runAsyncBlockSynchronously:^(Async2SyncLock *lock) {
            LOG(@"Loading photos' list from album %@", album.name);
            [serviceFacade getPhotosFromTheAlbum:album onSuccess:^(NSMutableArray *photos) {
                LOG(@"Photos' list successfully received.");
                for (Photo *photo in photos) {
                    NSString *filePath = [NSString stringWithFormat:@"%@/%@.%@",
                                                                    albumsDirectory,
                                                                    photo.title,
                                                                    [photo.originalUrl pathExtension]];
                    LOG(@"Downloading photo %@ in album %@.", photo.title, album.name);
                    [ImageDownloader downloadImageFromUrl:photo.originalUrl toFile:filePath];
                    LOG(@"Photo %@ in album %@ successfully downloaded.", photo.title, album.name);
                }

                [lock asyncFinished];
            }                            onError:^(Error *error) {
                [lock asyncFinished];
                LOG(@"Unable to get photos for album %@. Error: %@:%@.", album.name, error.id, error.message);
            }];
        }];
    }
}

+ (void)createFoldersHierarchyOnHardDisk:(NSMutableArray *)folders inDirectory:(NSString *)directory withFileManager:(NSFileManager *)fileManager serviceFacade:(FotkiServiceFacade *)serviceFacade onFinish:(ServiceFacadeCallback)onFinish {
    for (Folder *folder in folders) {
        NSString *foldersDirectory = [NSString stringWithFormat:@"%@/%@", directory, folder.name];
        [fileManager createDirectoryAtPath:foldersDirectory withIntermediateDirectories:YES attributes:nil error:nil];
        [self createFoldersHierarchyOnHardDisk:folder.childFolders inDirectory:foldersDirectory withFileManager:fileManager serviceFacade:serviceFacade onFinish:onFinish];
        [self createAlbums:folder.childAlbums inDirectory:foldersDirectory withFileManager:fileManager serviceFacade:serviceFacade];
    }
}

+ (void)clearDirectory:(NSString *)path withFileManager:(NSFileManager *)fileManager {
    NSError *error = nil;
    NSArray *files = [fileManager contentsOfDirectoryAtPath:path
                                                      error:&error];

    if (error) {
        LOG(@"Error getting content of directory %@. Error: %@", path, error);
    }

    for (NSString *file in files) {
        [fileManager removeItemAtPath:[path stringByAppendingPathComponent:file]
                                error:&error];
        if (error) {
            LOG(@"Error deleting content of directory %@. Error: %@", path, error);
        }
    }
    LOG(@"Directory %@ successfully cleared", path);
}


@end