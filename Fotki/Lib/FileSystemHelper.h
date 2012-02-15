//
//  Created by vavaka on 1/4/12.



#import <Foundation/Foundation.h>


@interface FileSystemHelper : NSObject

+ (BOOL)isImageFileAtPath:(NSString *)path;

+ (BOOL)isDirectoryAtPath:(NSString *)path;

+ (NSImage *)imageWithPreviewOfFileAtPath:(NSString *)path ofSize:(NSSize)size asIcon:(BOOL)icon;

+ (NSMutableArray *)getImagesFromFiles:(NSArray *)files;

+ (NSData *)getFileData:(NSString *)filePath;
@end