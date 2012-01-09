//
//  Created by aistomin on 1/9/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>


@interface FotkiServiceFacade : NSObject
- (void)authenticateWithLogin:(NSString *)login andPassword:(NSString *)password;
@end