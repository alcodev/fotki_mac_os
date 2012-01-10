//
//  Created by aistomin on 1/9/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>

@class Album;

typedef void (^ServiceFacadeCallback)(id);


@interface FotkiServiceFacade : NSObject {
    NSString *_sessionId;
}
- (void)authenticateWithLogin:(NSString *)login andPassword:(NSString *)password;

- (void)getAlbumsPlain:(ServiceFacadeCallback)onFinish;

- (void)uploadPicture:(NSString *)path toTheAlbum:(Album *)album onSuccess:(ServiceFacadeCallback)onSuccess onError:(ServiceFacadeCallback)onError;
@end