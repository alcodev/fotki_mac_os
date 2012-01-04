//
//  Created by vavaka on 1/4/12.



#import <Foundation/Foundation.h>


@interface FileSystemHelper : NSObject

+ (BOOL)isImageFileAtPath:(NSString *)path;

+ (NSImage *)imageWithPreviewOfFileAtPath:(NSString *)path ofSize:(NSSize)size asIcon:(BOOL)icon;

@end