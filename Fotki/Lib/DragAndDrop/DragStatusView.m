//
//  Created by aistomin on 2/1/12.
//
//
#import "DragStatusView.h"
#import "NSImage+Helper.h"
#import "FileSystemHelper.h"

@interface DragStatusView ()
- (void)manuallyCallRedraw;

@end

@implementation DragStatusView {
@private
    BOOL _isOnline;
}


@synthesize statusItem = _statusItem;
@synthesize menu = _menu;
@synthesize onFilesDragged = _onFilesDragged;
@synthesize isOnline = _isOnline;
@synthesize isEnable = _isEnable;
@synthesize isMenuVisible = _isMenuVisible;


- (void)dealloc {
    [_statusItem release];
    [_onFilesDragged release];
    [_menu release];
    [super dealloc];
}

- (void)mouseDown:(NSEvent *)event {
    [self.statusItem popUpStatusItemMenu:self.menu];
}

- (void)drawRect:(NSRect)dirtyRect {
    [_statusItem drawStatusBarBackgroundInRect:[self bounds]
                                 withHighlight:self.isMenuVisible];
    if (self.isOnline) {
        NSImage *iconImage = [[NSImage imageNamed:@"F-online.png"] extractAsImageRepresentationOfSize:0];
        [iconImage drawInRect:CGRectMake(3, 3, iconImage.size.width, iconImage.size.height) fromRect:NSZeroRect operation:NSCompositeHighlight fraction:1];
    }
    else {
        NSImage *iconImage = [[NSImage imageNamed:@"F-offline.png"] extractAsImageRepresentationOfSize:0];
        [iconImage drawInRect:CGRectMake(3, 3, iconImage.size.width, iconImage.size.height) fromRect:NSZeroRect operation:NSCompositeHighlight fraction:1];
    }
}


- (void)menuWillOpen:(NSMenu *)menu NS_AVAILABLE_MAC(10_5) {
    self.isMenuVisible = YES;
    [self manuallyCallRedraw];
}

- (void)menuDidClose:(NSMenu *)menu NS_AVAILABLE_MAC(10_5) {
    self.isMenuVisible = NO;
    [self manuallyCallRedraw];
}

- (void)changeIconState:(BOOL)isOnline {
    self.isOnline = isOnline;
    [self manuallyCallRedraw];
}
- (void)manuallyCallRedraw {
    [self setHidden:YES];
    [self setHidden:NO];
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    return self.isEnable ? NSDragOperationCopy : NSDragOperationNone;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    NSPasteboard *pasteboard;
    pasteboard = [sender draggingPasteboard];

    if ([[pasteboard types] containsObject:NSFilenamesPboardType]) {
        NSArray *files = [pasteboard propertyListForType:NSFilenamesPboardType];
        NSMutableArray *filesToUpload = [FileSystemHelper getImagesFromFiles:files];
        self.onFilesDragged(filesToUpload);
    }
    return YES;
}

- (DragStatusView *)initWithFrame:(NSRect)rect andMenu:(NSMenu *)menu andStatusMenuItem:(NSStatusItem *)statusItem onFilesDragged:(DragFilesCallback)onFilesDragged {
    self = [super initWithFrame:rect];
    if (self) {
        [self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
        self.menu = menu;
        self.menu.delegate = self;
        self.statusItem = statusItem;
        self.onFilesDragged = onFilesDragged;
        self.isEnable = YES;
    }
    return self;
}
@end