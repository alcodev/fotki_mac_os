//
//  Created by aistomin on 1/11/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "FoldersAndAlbumsTreeBuilder.h"
#import "CXMLDocument.h"
#import "Folder.h"
#import "Album.h"


@implementation FoldersAndAlbumsTreeBuilder {

}

+ (void)fillFolder:(Folder *)folder fromXml:(NSXMLElement *)element {
    NSArray *childElements = [element nodesForXPath:@"./folders/folder" error:nil];
    for (NSXMLElement *childElement in childElements) {
        if (!folder.childFolders) {
            folder.childFolders = [[[NSMutableArray alloc] init] autorelease];
        }
        NSString *folderName = [[childElement attributeForName:@"folder_name"] stringValue];
        NSString *folderId = [[childElement attributeForName:@"folder_id"] stringValue];
        Folder *childFolder = [[[Folder alloc] initWithId:folderId andName:folderName] autorelease];
        [self fillFolder:childFolder fromXml:childElement];
        [folder.childFolders addObject:childFolder];
    }

    NSArray *albumElements = [element nodesForXPath:@"./albums/album" error:nil];
    for (NSXMLElement *albumElement in albumElements) {
        if (!folder.childAlbums) {
            folder.childAlbums = [[[NSMutableArray alloc] init] autorelease];
        }
        NSString *albumName = [[[albumElement nodesForXPath:@"./name" error:nil] lastObject] stringValue];
        NSString *albumId = [[[albumElement nodesForXPath:@"./id" error:nil] lastObject] stringValue];
        Album *album = [[[Album alloc] initWithId:albumId andName:albumName] autorelease];
        [folder.childAlbums addObject:album];
    }
}

+ (NSArray *)buildTreeFromXmlDocument:(CXMLDocument *)document {
    NSMutableArray *rootFolders = [[[NSMutableArray alloc] init] autorelease];
    NSArray *nodes = [document nodesForXPath:@"get_albums/folders/folder" error:nil];
    for (NSXMLElement *element in nodes) {
        NSString *folderName = [[element attributeForName:@"folder_name"] stringValue];
        NSString *folderId = [[element attributeForName:@"folder_id"] stringValue];
        Folder *rootFolder = [[[Folder alloc] initWithId:folderId andName:folderName] autorelease];
        [self fillFolder:rootFolder fromXml:element];
        [rootFolders addObject:rootFolder];
    }
    return (rootFolders);
}
@end