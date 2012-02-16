//
//  Created by aistomin on 2/1/12.
//
//


#import <Foundation/Foundation.h>

typedef void (^DragFilesCallback)(id);

@interface DragStatusView : NSView

@property(nonatomic, retain)NSStatusItem *statusItem;
@property(nonatomic, retain)NSMenu *menu;
@property(nonatomic, copy) DragFilesCallback onFilesDragged;

//- (void)drawRect: (bool *)online;

@property(nonatomic) BOOL isOnline;

- (void)changeIconState:(BOOL)isOnline;

- (DragStatusView *)initWithFrame:(NSRect)rect andMenu:(NSMenu *)menu andStatusMenuItem:(NSStatusItem *)statusItem onFilesDragged:(DragFilesCallback)onFilesDragged;

@end