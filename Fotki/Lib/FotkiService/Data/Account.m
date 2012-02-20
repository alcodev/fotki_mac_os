//
//  Created by dimakononov on 14.02.12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "Account.h"


@implementation Account

@synthesize username = _username;
@synthesize password = _password;
@synthesize fullName = _fullName;
@synthesize spaceLimit = _spaceLimit;
@synthesize spaceUsed = _spaceUsed;
@synthesize albums = _albums;


- (Account *)initWithFullName:(NSString *)fullName spaceLimit:(NSString *)spaceLimit spaceUsed:(NSString *)spaceUsed {
    self = [super init];
    if (self) {
        self.fullName = fullName;
        self.spaceLimit = spaceLimit;
        self.spaceUsed = spaceUsed;
    }
    return self;
}

- (void)dealloc {
    [_username release];
    [_password release];
    [_fullName release];
    [_spaceLimit release];
    [_spaceUsed release];
    [_albums release];

    [super dealloc];
}


@end