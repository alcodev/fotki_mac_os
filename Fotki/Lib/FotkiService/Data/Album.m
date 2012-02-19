//
//  Created by aistomin on 1/10/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "Album.h"


@implementation Album {

@private

}
@synthesize id = _id;
@synthesize name = _name;
@synthesize path = _path;


- (void)dealloc {
    [_name release];
    [_id release];
    [_path release];
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

- (id)copyWithZone:(NSZone *)zone {
    Album *copy = [[[self class] allocWithZone: zone] init];
    copy.id = [[self.id copy] autorelease];
    copy.name = [[self.name copy] autorelease];
    return copy;
}

@end