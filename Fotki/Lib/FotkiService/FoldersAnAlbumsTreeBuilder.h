//
//  Created by aistomin on 1/11/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>

@class CXMLDocument;


@interface FoldersAnAlbumsTreeBuilder : NSObject
+ (NSArray *)buildTreeFromXmlDocument:(CXMLDocument *)document;
@end