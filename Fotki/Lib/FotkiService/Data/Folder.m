//
//  Created by aistomin on 1/11/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "Folder.h"


@implementation Folder {

}
@synthesize id = _id;
@synthesize name = _name;
@synthesize childFolders = _childFolders;
@synthesize childAlbums = _childAlbums;


- (Folder *)initWithId:(NSString *)id andName:(NSString *)name {
    self = [super init];
    if (self) {
        self.id = id;
        self.name = name;
    }
    return (self);
}

- (void)dealloc {
    [_name release];
    [_id release];
    [_childFolders release];
    [_childAlbums release];
    [super dealloc];
}
@end