//
//  Created by aistomin on 1/12/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "Error.h"


@implementation Error {

}
@synthesize id = _id;
@synthesize message = _message;


- (Error *)initWithId:(NSString *)id andMessage:(NSString *)message {
    self = [super init];
    if (self) {
        self.id = id;
        self.message = message;
    }
    return (self);
}

- (void)dealloc {
    [_id release];
    [_message release];
    [super dealloc];
}

-(NSString *)description{
    return [NSString stringWithFormat:@"%@:%@", self.id, self.message];
}
@end