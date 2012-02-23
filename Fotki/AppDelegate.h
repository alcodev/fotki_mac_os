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

@property(nonatomic, retain)IBOutlet NSTextField *albumLinkLabel;
@property(nonatomic, retain)IBOutlet NSTextField *totalProgressLabel;
@property(nonatomic, retain)IBOutlet NSTextField *currentFileProgressLabel;
@property(nonatomic, retain)IBOutlet NSProgressIndicator *currentFileProgressIndicator;
@property(nonatomic, retain)IBOutlet NSProgressIndicator *totalFileProgressIndicator;

@property(nonatomic) BOOL isUploadFinished;

- (IBAction)settingsMenuItemClicked:(id)sender;

- (IBAction)aboutMenuClicked:(id)sender;

- (IBAction)exitMenuItemClicked:(id)sender;

- (IBAction)uploadMenuClicked:(id)sender;

@end
