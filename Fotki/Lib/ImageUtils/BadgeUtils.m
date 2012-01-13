//
//  Created by aistomin on 1/13/12.
//
//


#import "BadgeUtils.h"
#import "NSImage+Helper.h"
#import "FileSystemHelper.h"


@implementation BadgeUtils {

}
+ (void)putBadge:(NSImage *)badge onFileIconAtPath:(NSString *)path {
    NSImage *fileIcon = [FileSystemHelper imageWithPreviewOfFileAtPath:path ofSize:NSMakeSize(64, 64) asIcon:YES];
    //NSImage *fileIcon = [[NSWorkspace sharedWorkspace] iconForFile:path];
    NSImage *badgedIcon = [[fileIcon putOtherImage:badge] retain];
    [[NSWorkspace sharedWorkspace] setIcon:badgedIcon forFile:path options:nil];

    [badgedIcon release];
}


+ (NSImage *)getBadgeImageWithName:(NSString *)name {
    return [[NSImage imageNamed:name] extractAsImageRepresentationOfSize:0];
}

+ (void)putUpdatedBadgeOnFileIconAtPath:(NSString *)path {
    [self putBadge:[self getBadgeImageWithName:@"updated.icns"] onFileIconAtPath:path];
}

+ (void)putCheckBadgeOnFileIconAtPath:(NSString *)path {
    [self putBadge:[self getBadgeImageWithName:@"check.icns"] onFileIconAtPath:path];

}

+ (void)putErrorBadgeOnFileIconAtPath:(NSString *)path {
    [self putBadge:[self getBadgeImageWithName:@"nosync.icns"] onFileIconAtPath:path];
}
@end