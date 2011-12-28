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

- (void)awakeFromNib {
    statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
    [statusItem setMenu:statusMenu];
    [statusItem setTitle:APP_NAME];
    [statusItem setHighlightMode:YES];
}


@end
