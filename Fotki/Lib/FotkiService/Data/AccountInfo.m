//
//  Created by dimakononov on 14.02.12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "AccountInfo.h"


@implementation AccountInfo

@synthesize username = _username;
@synthesize password = _password;
@synthesize spaceLimit = _spaceLimit;
@synthesize spaceUsed = _spaceUsed;
@synthesize name = _name;


- (AccountInfo *)initWithName:(NSString *)name spaceLimit:(NSString *)spaceLimit spaceUsed:(NSString *)spaceUsed {
    self = [super init];
    if (self) {
        self.name = name;
        self.spaceLimit = spaceLimit;
        self.spaceUsed = spaceUsed;
    }
    return self;
}

- (void)dealloc {
    [_username release];
    [_password release];
    [_name release];
    [_spaceLimit release];
    [_spaceUsed release];

    [super dealloc];
}


@end