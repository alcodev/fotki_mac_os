//
//  Created by dimakononov on 22.02.12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "UploadError.h"


@implementation UploadError {

}
@synthesize errorDescription = _errorDescription;
@synthesize event = _event;

-(UploadError *)initWithEvent:(NSString *)event andErrorDescription:(NSString *) errorDescription{
    self = [super init];
    if (self){
        self.event = event;
        self.errorDescription = errorDescription;
    }
    return self;
}

- (void)dealloc {
    [_errorDescription release];
    [_event release];
    [super dealloc];
}


@end