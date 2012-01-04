//
//  Created by vavaka on 1/4/12.



#import "NSImage+Helper.h"


@implementation NSImage (Helper)

- (NSImage *)resizeTo:(NSSize)newSize {
    NSImage *resizedImage = [[[NSImage alloc] initWithSize:newSize] autorelease];

    [resizedImage lockFocus];

    NSSize originalSize = [self size];
    [self drawInRect:NSMakeRect(0, 0, newSize.width, newSize.height) fromRect:NSMakeRect(0, 0, originalSize.width, originalSize.height) operation:NSCompositeSourceOver fraction:1.0];

    [resizedImage unlockFocus];

    return resizedImage;
}

- (void)saveTo:(NSString *)path as:(NSBitmapImageFileType)imageFileType {
    NSData *imageData = [self TIFFRepresentation];
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
    NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
    imageData = [imageRep representationUsingType:imageFileType properties:imageProps];
    [imageData writeToFile:path atomically:NO];
}

//sizes -> { 0=>512, 1=>128, 2=>48, 3=>32, 4=>16 }
- (NSImage *)extractAsImageRepresentationOfSize:(NSUInteger)size {
    NSImageRep *imageRep = [[self representations] objectAtIndex:size];

    NSImage *image = [[[NSImage alloc] initWithSize:[imageRep size]] autorelease];
    [image addRepresentation:imageRep];

    return image;
}

- (NSImage *)putOtherImage:(NSImage *)otherImage {
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];

    NSImage *resultImage = [[[NSImage alloc] initWithSize:otherImage.size] autorelease];
    [resultImage lockFocus];
    [self drawInRect:NSMakeRect(0, 0, resultImage.size.width, resultImage.size.height) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0f];
    [otherImage drawInRect:NSMakeRect(0, 0, resultImage.size.width, resultImage.size.height) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0f];
    [resultImage unlockFocus];

    return resultImage;
}

@end