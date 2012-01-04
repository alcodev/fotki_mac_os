//
//  Created by vavaka on 1/4/12.



#import <Foundation/Foundation.h>

@interface NSImage (Helper)

- (NSImage *)resizeTo:(NSSize)newSize;

- (void)saveTo:(NSString *)path as:(NSBitmapImageFileType)imageFileType;

- (NSImage *)extractAsImageRepresentationOfSize:(NSUInteger)size;

- (NSImage *)putOtherImage:(NSImage *)otherImage;

@end