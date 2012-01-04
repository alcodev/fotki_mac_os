//
//  Created by vavaka on 1/4/12.



#import "FileSystemHelper.h"
#import "NSImage+Helper.h"


@implementation FileSystemHelper

+ (BOOL)isImageFileAtPath:(NSString *)path {
    NSWorkspace *sharedWorkspace = [NSWorkspace sharedWorkspace];
    return [sharedWorkspace type:[sharedWorkspace typeOfFile:path error:NULL] conformsToType:@"public.image"];
}

+ (void)putBadge:(NSImage *)badge onFileIconAtPath:(NSString *)path {
    NSImage *fileIcon = [[[NSWorkspace sharedWorkspace] iconForFile:path] copy];
    NSImage *badgedIcon = [fileIcon putOtherImage:badge];
    [fileIcon release];

    [[NSWorkspace sharedWorkspace] setIcon:badgedIcon forFile:path options:nil];
}

@end