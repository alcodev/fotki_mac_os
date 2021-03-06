//
//  Created by vavaka on 1/4/12.



#import <QuickLook/QuickLook.h>
#import "FileSystemHelper.h"
#import "NSImage+Helper.h"


@implementation FileSystemHelper

+ (BOOL)isImageFileAtPath:(NSString *)path {
    NSString *fileExtension = path.pathExtension;
    return [[FileSystemHelper supportedImageFilesTypes] containsObject:[fileExtension lowercaseString]];
}

+ (BOOL)isDirectoryAtPath:(NSString *)path {
    BOOL isDirectory;
    [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
    return isDirectory;
}

+ (NSImage *)imageWithPreviewOfFileAtPath:(NSString *)path ofSize:(NSSize)size asIcon:(BOOL)icon {
    NSURL *fileURL = [NSURL fileURLWithPath:path];
    if (!path || !fileURL) {
        return nil;
    }

    NSDictionary *dict = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:icon]
                                                     forKey:(NSString *) kQLThumbnailOptionIconModeKey];
    CGImageRef ref = QLThumbnailImageCreate(kCFAllocatorDefault,
            (CFURLRef) fileURL,
            CGSizeMake(size.width, size.height),
            (CFDictionaryRef) dict);

    if (ref != NULL) {
        // Take advantage of NSBitmapImageRep's -initWithCGImage: initializer, new in Leopard,
        // which is a lot more efficient than copying pixel data into a brand new NSImage.
        // Thanks to Troy Stephens @ Apple for pointing this new method out to me.
        NSBitmapImageRep *bitmapImageRep = [[NSBitmapImageRep alloc] initWithCGImage:ref];
        NSImage *newImage = nil;
        if (bitmapImageRep) {
            newImage = [[NSImage alloc] initWithSize:[bitmapImageRep size]];
            [newImage addRepresentation:bitmapImageRep];
            [bitmapImageRep release];

            if (newImage) {
                return [newImage autorelease];
            }
        }
        CFRelease(ref);
    } else {
        // If we couldn't get a Quick Look preview, fall back on the file's Finder icon.
        NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:path];
        if (icon) {
            [icon setSize:size];
        }
        return icon;
    }

    return nil;
}

+ (NSMutableArray *)getImagesFromFiles:(NSArray *)files {
    NSMutableArray *filesToUpload = [[[NSMutableArray alloc] init] autorelease];
    for (NSString *filePath in files) {
        if ([FileSystemHelper isDirectoryAtPath:filePath]) {
            NSArray *filesInDirectory = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:filePath error:nil];
            for (NSString *filePathInDirectory in filesInDirectory) {
                NSString *fileInDirectoryFullPath = [NSString stringWithFormat:@"%@/%@", filePath, filePathInDirectory];
                if ([FileSystemHelper isImageFileAtPath:fileInDirectoryFullPath]) {
                    [filesToUpload addObject:fileInDirectoryFullPath];
                }
            }
        } else if ([FileSystemHelper isImageFileAtPath:filePath]) {
            [filesToUpload addObject:filePath];
        }
    }
    return filesToUpload;
}

+ (NSData *)getFileData:(NSString *)filePath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return [fileManager contentsAtPath:filePath];
}

+ (long long int)sizeForFileAtPath:(NSString *)path {
    NSError *attributesError = nil;
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&attributesError];
    NSNumber *fileSizeNumber = [fileAttributes objectForKey:NSFileSize];
    long long fileSize = [fileSizeNumber longLongValue];
    return fileSize;
}

+ (long long int)sizeForFilesAtPaths:(NSArray *)paths {
    long long totalSize = 0;
    for (NSString *path in paths) {
        long long sizePath = [FileSystemHelper sizeForFileAtPath:path];
        totalSize += sizePath;
    }

    return totalSize;
}

+(NSArray *)supportedImageFilesTypes{
    return [NSMutableArray arrayWithObjects:@"jpg", @"jpeg", @"png", @"gif", nil];
}

@end