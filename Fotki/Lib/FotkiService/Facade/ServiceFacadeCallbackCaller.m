//
//  Created by aistomin on 1/12/12.
//
//


#import "ServiceFacadeCallbackCaller.h"


@implementation ServiceFacadeCallbackCaller {

}
+ (void)callServiceFacadeCallback:(ServiceFacadeCallback)callback withObject:(id)object {
    if (callback) {
        callback(object);
    }
}
@end