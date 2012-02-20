//
//  AppDelegate.h
//  Fotki
//
//  Created by Vladimir Kuznetsov on 12/24/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class FileSystemMonitor;

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    IBOutlet NSMenu *statusMenu;
    IBOutlet NSMenuItem *synchronizeMenuItem;
    IBOutlet NSMenuItem *uploadMenuItem;

    NSStatusItem *statusItem;
}

@property(assign) IBOutlet NSWindow *settingsWindow;
@property(assign) IBOutlet NSWindow *uploadWindow;
@property(nonatomic, retain)IBOutlet NSTextField *albumLinkLabel;
@property(nonatomic, retain)IBOutlet NSTextField *totalProgressLabel;
@property(nonatomic, retain)IBOutlet NSTextField *currentFileProgressLabel;
@property(nonatomic, retain)IBOutlet NSTableView *uploadFilesTable;
@property(nonatomic, retain)IBOutlet NSProgressIndicator *currentFileProgressIndicator;
@property(nonatomic, retain)IBOutlet NSProgressIndicator *totalFileProgressIndicator;

- (IBAction)settingsMenuItemClicked:(id)sender;

- (IBAction)exitMenuItemClicked:(id)sender;

- (IBAction)uploadMenuClicked:(id)sender;

@end
