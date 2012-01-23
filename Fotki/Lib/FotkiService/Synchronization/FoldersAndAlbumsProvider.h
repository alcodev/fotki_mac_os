//
//  Created by aistomin on 1/23/12.
//
//


#import <Foundation/Foundation.h>
#import "FotkiServiceFacade.h"

@class FotkiServiceFacade;


@interface FoldersAndAlbumsProvider : NSObject
+ (void)getAlbumByFilePath:(NSString *)filePath serviceFacade:(FotkiServiceFacade *)fotkiServiceFacade onFinish:(ServiceFacadeCallback)onFinish;
@end