//
//  Created by aistomin on 2/1/12.
//
//
#import "DragStatusView.h"
#import "NSImage+Helper.h"
#import "FileSystemHelper.h"

@implementation DragStatusView {
@private
    BOOL _isOnline;
}


@synthesize statusItem = _statusItem;
@synthesize menu = _menu;
@synthesize onFilesDragged = _onFilesDragged;
@synthesize isOnline = _isOnline;
@synthesize isEnable = _isEnable;


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
    if (self.isOnline) {
        NSImage *iconImage = [[NSImage imageNamed:@"F-online.png"] extractAsImageRepresentationOfSize:0];
        [iconImage drawInRect:[self bounds] fromRect:NSZeroRect operation:NSCompositeCopy fraction:1];
    }
    else {
        NSImage *iconImage = [[NSImage imageNamed:@"F-offline.png"] extractAsImageRepresentationOfSize:0];
        [iconImage drawInRect:[self bounds] fromRect:NSZeroRect operation:NSCompositeCopy fraction:1];
    }
}

- (void)changeIconState:(BOOL)isOnline {
    self.isOnline = isOnline;
    [self setHidden:YES];
    [self setHidden:NO];

}

//we want to copy the files
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    return NSDragOperationCopy;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    if (!self.isEnable){
        return NO;
    }
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
        self.statusItem = statusItem;
        self.onFilesDragged = onFilesDragged;
        self.isEnable = YES;
    }
    return self;
}
@end