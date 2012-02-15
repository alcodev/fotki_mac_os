//
//  Created by aistomin on 2/1/12.
//
//
#import "DragStatusView.h"
#import "NSImage+Helper.h"
#import "FileSystemHelper.h"

@implementation DragStatusView

@synthesize statusItem = _statusItem;
@synthesize menu = _menu;
@synthesize onFilesDragged = _onFilesDragged;

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
    NSImage *iconImage = [[NSImage imageNamed:@"fotki_icon.png"] extractAsImageRepresentationOfSize:0];
    [iconImage drawInRect:[self bounds] fromRect:NSZeroRect operation:NSCompositeCopy fraction:1];
}

//we want to copy the files
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    return NSDragOperationCopy;
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
        self.statusItem = statusItem;
        self.onFilesDragged = onFilesDragged;
    }
    return self;
}
@end