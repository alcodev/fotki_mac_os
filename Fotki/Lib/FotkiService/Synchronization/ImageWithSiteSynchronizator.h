//
//  Created by aistomin on 1/13/12.
//
//


#import <Foundation/Foundation.h>

@class FotkiServiceFacade;


@interface ImageWithSiteSynchronizator : NSObject
+ (void)addFile:(NSString *)filePath serviceFacade:(FotkiServiceFacade *)fotkiServiceFacade;
@end