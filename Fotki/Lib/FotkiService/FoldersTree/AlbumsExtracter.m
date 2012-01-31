//
//  Created by aistomin on 1/31/12.
//
//


#import "AlbumsExtracter.h"
#import "Folder.h"
#import "Album.h"


@implementation AlbumsExtracter {

}

+ (void)extractAlbumsFromFolder:(Folder *)folder toArray:(NSMutableArray *)albums currentFolderPath:(NSString *)currentFolderPath {
    currentFolderPath = [NSString stringWithFormat:@"%@%@/", currentFolderPath, folder.name];
    for (Album *album in folder.childAlbums) {
        album.path = [NSString stringWithFormat:@"%@%@", currentFolderPath, album.name];
        [albums addObject:album];
    }
    for(Folder *childFolder in folder.childFolders){
        [self extractAlbumsFromFolder:childFolder toArray:albums currentFolderPath:currentFolderPath];
    }
}

+ (NSMutableArray *)extractAlbums:(NSArray *)rootFolders {
    NSMutableArray *albums = [[[NSMutableArray alloc] init] autorelease];
    NSString *currentFolderPath = @"/";
    for (Folder *folder in rootFolders) {
        [self extractAlbumsFromFolder:folder toArray:albums currentFolderPath:currentFolderPath];
    }
    return albums;
}
@end