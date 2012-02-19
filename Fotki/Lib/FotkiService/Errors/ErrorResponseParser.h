//
//  Created by aistomin on 1/12/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>

@class Error;
@class CXMLDocument;


@interface ErrorResponseParser : NSObject

+ (NSString *)extractErrorFromXmlDocument:(CXMLDocument *)document;

@end