//
//  Created by aistomin on 1/12/12.
//
//


#import <Foundation/Foundation.h>
#import "FotkiServiceFacade.h"

@class ApiCallResult;

typedef void (^ApiCallback)(ApiCallResult *result);

@interface ServiceUtils : NSObject

+ (void)asyncProcessXmlRequestForUrl:(NSString *)serviceUrl andPath:(NSString *)path andParams:(NSDictionary *)params finishCallback:(ApiCallback)finishCallback;

+ (id)syncProcessXmlRequestForUrl:(NSString *)serviceUrl andPath:(NSString *)path andParams:(NSDictionary *)params;

+ (void)asyncProcessImageRequestForUrl:(NSString *)serviceUrl path:(NSString *)path params:(NSDictionary *)params name:(NSString *)name imagePath:(NSString *)imagePath finishCallback:(ApiCallback)finishCallback uploadProgressBlock:(UploadProgressBlock)uploadProgressBlock;

+ (id)syncProcessImageRequestForUrl:(NSString *)serviceUrl path:(NSString *)path params:(NSDictionary *)params name:(NSString *)name imagePath:(NSString *)imagePath uploadProgressBlock:(UploadProgressBlock)uploadProgressBlock;

@end