//
//  Created by aistomin on 1/9/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>

typedef void (^ServiceFacadeCallback)(id);


@interface FotkiServiceFacade : NSObject {
    NSString *_sessionId;
}
- (void)authenticateWithLogin:(NSString *)login andPassword:(NSString *)password;

- (void)getAlbumsPlain:(ServiceFacadeCallback)onFinish;
@end