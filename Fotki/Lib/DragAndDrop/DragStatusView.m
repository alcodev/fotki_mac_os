//
//  Created by aistomin on 2/1/12.
//
//

#import "DragStatusView.h"
#import "NSImage+Helper.h"

@implementation DragStatusView {
    NSMenu *_menu;
    NSStatusItem *_statusItem;

    DragFilesCallback _onFilesDragged;

}
- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
    }

    return self;
}

- (void)mouseDown:(NSEvent *)event {
    [_statusItem popUpStatusItemMenu:_menu];
}


- (void)drawRect:(NSRect)dirtyRect {
    NSImage *iconImage = [[NSImage imageNamed:@"fotki_icon.png"] extractAsImageRepresentationOfSize:0];
    [iconImage drawInRect:[self bounds] fromRect:NSZeroRect operation:NSCompositeCopy fraction:1];
}

//we want to copy the files
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    return NSDragOperationCopy;
}

//perform the drag and log the files that are dropped
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;

    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];

    if ([[pboard types] containsObject:NSFilenamesPboardType]) {
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
        if (_onFilesDragged) {
            _onFilesDragged(files);
        }
    }
    return YES;
}


- (DragStatusView *)initWithFrame:(NSRect)rect andMenu:(NSMenu *)menu andStatusMenuItem:(NSStatusItem *)statusItem onFilesDragged:(DragFilesCallback)onFilesDragged {
    self = [super initWithFrame:rect];
    if (self) {
        [self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
        _menu = menu;
        _statusItem = statusItem;
        _onFilesDragged = Block_copy(onFilesDragged);
    }

    return self;

}
@end