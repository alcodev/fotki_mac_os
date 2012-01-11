//
//  Created by aistomin on 1/11/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "Photo.h"


@implementation Photo {

}
@synthesize id = _id;
@synthesize title = _title;
@synthesize originalUrl = _originalUrl;
@synthesize albumId = _albumId;


- (Photo *)initWithId:(NSString *)id title:(NSString *)title originalUrl:(NSString *)url albumId:(NSString *)albumId {
    self = [super init];
    if (self) {
        self.id = id;
        self.title = title;
        self.originalUrl = url;
        self.albumId = albumId;
    }
    return (self);

}

- (void)dealloc {
    [_id release];
    [_title release];
    [_originalUrl release];
    [_albumId release];
    [super dealloc];
}
@end