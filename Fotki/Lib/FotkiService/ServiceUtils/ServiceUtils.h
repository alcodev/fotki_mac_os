//
//  Created by aistomin on 1/12/12.
//
//


#import <Foundation/Foundation.h>
#import "FotkiServiceFacade.h"


@interface ServiceUtils : NSObject
+ (void)processXmlRequestForUrl:(NSString *)url andPath:(NSString *)path andParams:(NSDictionary *)params onSuccess:(ServiceFacadeCallback)onSuccess onError:(ServiceFacadeCallback)onError;

+ (void)processImageRequestForUrl:(NSString *)url path:(NSString *)path params:(NSDictionary *)params name:(NSString *)name imagePath:(NSString *)imagePath onSuccess:(ServiceFacadeCallback)onSuccess onError:(ServiceFacadeCallback)onError;
@end