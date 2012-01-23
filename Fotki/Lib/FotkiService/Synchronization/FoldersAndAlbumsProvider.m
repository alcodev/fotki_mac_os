//
//  Created by aistomin on 1/23/12.
//
//


#import "FoldersAndAlbumsProvider.h"
#import "Folder.h"
#import "Album.h"
#import "ServiceFacadeCallbackCaller.h"
#import "Error.h"
#import "DirectoryUtils.h"
#import "Consts.h"


@implementation FoldersAndAlbumsProvider {

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

+ (void)getAlbumByFilePath:(NSString *)filePath serviceFacade:(FotkiServiceFacade *)fotkiServiceFacade onFinish:(ServiceFacadeCallback)onFinish {
    NSString *relativeFilePath = [filePath stringByReplacingOccurrencesOfString:[DirectoryUtils getFotkiPath] withString:@""];
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
                NSString *errorMessage = @"Folder with name: %@ does not exist.";
                LOG(errorMessage, folderName);
                Error *error = [[[Error alloc] initWithId:DEFAULT_ERROR_CODE andMessage:errorMessage] autorelease];
                [ServiceFacadeCallbackCaller callServiceFacadeCallback:onFinish withObject:error];
                return;
            }
        }
        if (folder) {
            NSUInteger albumNameIndex = [foldersWithAlbumInRelativePath count] - 1;
            NSString *albumName = [foldersWithAlbumInRelativePath objectAtIndex:albumNameIndex];
            Album *album = [self searchAlbumWithName:albumName inAlbums:folder.childAlbums];
            [ServiceFacadeCallbackCaller callServiceFacadeCallback:onFinish withObject:album];
        } else {
            NSString *errorMessage = @"Folder with was not found";
            LOG(errorMessage);
            Error *error = [[[Error alloc] initWithId:DEFAULT_ERROR_CODE andMessage:errorMessage] autorelease];
            [ServiceFacadeCallbackCaller callServiceFacadeCallback:onFinish withObject:error];
            return;
        }
    }                     onError:^(Error *error) {
        [ServiceFacadeCallbackCaller callServiceFacadeCallback:onFinish withObject:error];
    }];
}

@end