//
//  Created by aistomin on 1/12/12.
//
//


#import <Foundation/Foundation.h>
#import "FotkiServiceFacade.h"


@interface ServiceFacadeCallbackCaller : NSObject
+ (void)callServiceFacadeCallback:(ServiceFacadeCallback)callback withObject:(id)object;
@end