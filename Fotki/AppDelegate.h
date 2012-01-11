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
    IBOutlet NSButton *loginButton;
    IBOutlet NSButton *getAlbumsButton;
    IBOutlet NSButton *buildFoldersTreeButton;
    IBOutlet NSButton *downloadButton;
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

- (IBAction)itemClicked:(id)sender;

- (IBAction)exitMenuItemClicked:(id)sender;

- (IBAction)loginButtonClicked:(id)sender;

- (IBAction)getAlbumsButtonClicked:(id)sender;

- (IBAction)buildFoldersTreeButtonClicked:(id)sender;

- (IBAction)downloadButtonClicked:(id)sender;

- (void)synchronizeData;

- (void)registerDefaults;

- (void)initializeEventStream;

- (void)addModifiedImagesAtPath:(NSString *)path;

- (void)updateLastEventId:(uint64_t)eventId;

- (BOOL)fileIsImage:(NSString *)path;

@end
