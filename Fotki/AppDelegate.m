//
//  AppDelegate.m
//  Fotki
//
//  Created by Vladimir Kuznetsov on 12/24/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"

#define APP_NAME @"Fotki"
#define FOTKI_PATH @"/Users/vavaka/tmp/fotki"

@implementation AppDelegate

@synthesize window = _window;

- (void)dealloc {
    [statusMenu release];
    [statusItem release];

    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
}

- (void)addPathToSharedItem:(NSString *)path {
    CFURLRef url = (CFURLRef) [NSURL fileURLWithPath:path];

    // Create a reference to the shared file list.
    LSSharedFileListRef favoriteItems = LSSharedFileListCreate(NULL, kLSSharedFileListFavoriteItems, NULL);
    if (favoriteItems) {
        //Insert an item to the list.
        LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(favoriteItems, kLSSharedFileListItemLast, NULL, NULL, url, NULL, NULL);
        if (item) {
            CFRelease(item);
        }
    }

    CFRelease(favoriteItems);
}

- (IBAction)testMenuItemClicked:(id)sender {
    [self addPathToSharedItem:FOTKI_PATH];
}

- (IBAction)settingsMenuItemClicked:(id)sender {
    //[self.window orderOut:self];
    [self.window makeKeyAndOrderFront:self];
}

- (NSImage *)image:(NSImage *)sourceImage resizeTo:(NSSize)newSize {
    NSImage *resizedImage = [[[NSImage alloc] initWithSize:newSize] autorelease];

    NSSize originalSize = [sourceImage size];

    [resizedImage lockFocus];
    [sourceImage drawInRect:NSMakeRect(0, 0, newSize.width, newSize.height) fromRect:NSMakeRect(0, 0, originalSize.width, originalSize.height) operation:NSCompositeSourceOver fraction:1.0];
    [resizedImage unlockFocus];

    return resizedImage;
}

- (void)image:(NSImage *)image saveTo:(NSString *)path as:(NSBitmapImageFileType)imageFileType {
    NSData *imageData = [image TIFFRepresentation];
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
    NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
    imageData = [imageRep representationUsingType:imageFileType properties:imageProps];
    [imageData writeToFile:path atomically:NO];
}

- (NSImage *)extractFromIcon:(NSImage *)iconImage imageOfSize:(NSUInteger)size{
    //sizes -> { 0=>512, 1=>128, 2=>48, 3=>32, 4=>16 }
    NSImageRep *imageRep = [[iconImage representations] objectAtIndex:size];

    NSImage *image = [[[NSImage alloc] initWithSize:[imageRep size]] autorelease];
    [image addRepresentation: imageRep];
    
    return image;
}

- (NSImage *)compositeBadge:(NSImage *)badge onImage:(NSImage *)image {
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];

    NSImage *resultImage = [[[NSImage alloc] initWithSize:badge.size] autorelease];
    [resultImage lockFocus];
    [image drawInRect:NSMakeRect(0, 0, resultImage.size.width, resultImage.size.height) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0f];
    [badge drawInRect:NSMakeRect(0, 0, resultImage.size.width, resultImage.size.height) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0f];
    [resultImage unlockFocus];

    return resultImage;
    /*[image setSize:badge.size];

    [image lockFocus];
    [badge drawInRect:NSMakeRect(0, 0, image.size.width, image.size.height) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    [image unlockFocus];*/
}

- (IBAction)itemClicked:(id)sender {
    //[self addPathToSharedItem:FOTKI_PATH];
    NSImage *badge = [self extractFromIcon:[NSImage imageNamed:@"updated.icns"] imageOfSize:0];

    NSImage *fileIcon = [[[NSWorkspace sharedWorkspace] iconForFile:@"/Users/vavaka/tmp/fotki/alcodev.png"] copy];
    NSImage *badgedIcon = [self compositeBadge:badge onImage:fileIcon];
    [fileIcon release];

    [[NSWorkspace sharedWorkspace] setIcon:badgedIcon forFile:@"/Users/vavaka/tmp/fotki/en2.yml" options:nil];
}

- (void)awakeFromNib {
    statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
    [statusItem setMenu:statusMenu];
    [statusItem setTitle:APP_NAME];
    [statusItem setHighlightMode:YES];
}


@end
