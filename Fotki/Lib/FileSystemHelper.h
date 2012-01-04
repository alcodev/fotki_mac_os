//
//  Created by vavaka on 1/4/12.



#import <Foundation/Foundation.h>


@interface FileSystemHelper : NSObject

+ (BOOL)isImageFileAtPath:(NSString *)path;

+ (void)putBadge:(NSImage *)badge onFileIconAtPath:(NSString *)path;

@end