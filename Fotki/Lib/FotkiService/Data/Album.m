//
//  Created by aistomin on 1/10/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "Album.h"


@implementation Album {

}
@synthesize name = _name;
@synthesize id = _id;


- (void)dealloc {
    [_name release];
    [_id release];
    [super dealloc];
}

- (id)initWithId:(NSString *)id andName:(NSString *)name {
    self = [super init];
    if (self) {
        self.id = id;
        self.name = name;
    }
    return (self);
}
@end