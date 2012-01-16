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

    IBOutlet NSButton *loginButton;
    IBOutlet NSTextField *loginTextField;
    IBOutlet NSSecureTextField *passwordSecureTextField;
    IBOutlet NSTextFieldCell *notificationLabel;

    NSStatusItem *statusItem;

    NSFileManager *_fm;
    NSMutableArray *_files;
    NSMutableDictionary *_filesHashes;
    NSDate *_appStartedTimestamp;
    FSEventStreamRef _stream;

    FileSystemMonitor *_fileSystemMonitor;
}

@property(assign) IBOutlet NSWindow *window;
@property(readonly) NSNumber *lastEventId;

- (IBAction)testMenuItemClicked:(id)sender;

- (IBAction)settingsMenuItemClicked:(id)sender;

- (IBAction)synchronizeMenuItemClicked:(id)sender;

- (IBAction)exitMenuItemClicked:(id)sender;

- (IBAction)loginButtonClicked:(id)sender;

- (void)registerDefaults;

@end
