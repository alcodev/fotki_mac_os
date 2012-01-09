//
//  AppDelegate.m
//  Fotki
//
//  Created by Vladimir Kuznetsov on 12/24/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "NSThread+Helper.h"
#import "FileSystemMonitor.h"
#import "Finder.h"
#import "NSImage+Helper.h"
#import "FileSystemHelper.h"
#import "FotkiServiceFacade.h"

#define APP_NAME @"Fotki"
#define FOTKI_PATH @"/Users/aistomin/tmp/fotki"

void fsevents_callback(ConstFSEventStreamRef streamRef, void *userData, size_t numEvents, void *eventPaths, const FSEventStreamEventFlags eventFlags[], const FSEventStreamEventId eventIds[]) {
    AppDelegate *appDelegate = (AppDelegate *) userData;
    size_t i;
    for (i = 0; i < numEvents; i++) {
        if (eventIds[i] <= [appDelegate.lastEventId unsignedLongLongValue]) {
            continue;
        }

        LOG(@"Handling fs event %lu", eventIds[i]);
        [appDelegate addModifiedImagesAtPath:[(NSArray *) eventPaths objectAtIndex:i]];
        [appDelegate updateLastEventId:eventIds[i]];
        [appDelegate synchronizeData];
    }
}

@interface AppDelegate ()

- (NSImage *)getBadgeImageWithName:(NSString *)name;

@end

@implementation AppDelegate

@synthesize window = _window;
@synthesize lastEventId = _lastEventId;

- (id)init {
    self = [super init];
    if (self != nil) {
        _fm = [NSFileManager defaultManager];
        _files = [NSMutableArray new];
    }
    return self;
}

- (void)dealloc {
    [statusMenu release];
    [statusItem release];
    [loginButton release];

    [_files release];
    [_filesHashes release];
    [_lastEventId release];

    [_appStartedTimestamp release];

    [_fileSystemMonitor release];

    [super dealloc];
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)app {
    [_fileSystemMonitor stop];
    return NSTerminateNow;
}

- (void)putBadge:(NSImage *)badge onFileIconAtPath:(NSString *)path {
    NSImage *fileIcon = [FileSystemHelper imageWithPreviewOfFileAtPath:path ofSize:NSMakeSize(64, 64) asIcon:YES];
    //NSImage *fileIcon = [[NSWorkspace sharedWorkspace] iconForFile:path];
    NSImage *badgedIcon = [[fileIcon putOtherImage:badge] retain];    
    [[NSWorkspace sharedWorkspace] setIcon:badgedIcon forFile:path options:nil];
    
    [badgedIcon release];
}

- (void)handleFileAdd:(NSString *)path {
    if (![FileSystemHelper isImageFileAtPath:path]) {
        return;
    }

    [NSThread doInNewThread:^{
        [self putBadge:[self getBadgeImageWithName:@"updated.icns"] onFileIconAtPath:path];
        [NSThread sleepForTimeInterval:5];
        [self putBadge:[self getBadgeImageWithName:@"check.icns"] onFileIconAtPath:path];
    }];
}

- (void)registerDefaults {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *appDefaults = [NSDictionary
        dictionaryWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithUnsignedLongLong:kFSEventStreamEventIdSinceNow], [NSMutableDictionary new], nil]
                      forKeys:[NSArray arrayWithObjects:@"lastEventId", @"filesHashes", nil]];
    [defaults registerDefaults:appDefaults];
}

- (void)awakeFromNib {
    statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
    [statusItem setMenu:statusMenu];
    [statusItem setTitle:APP_NAME];
    [statusItem setHighlightMode:YES];
    [loginButton setTitle:@"Login"];

    [self registerDefaults];

    _appStartedTimestamp = [[NSDate date] retain];
    _filesHashes = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"filesHashes"] mutableCopy];
    _lastEventId = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastEventId"];

    NSArray *pathsToWatch = [NSArray arrayWithObject:FOTKI_PATH];
    _fileSystemMonitor = [[FileSystemMonitor alloc] initWithPaths:pathsToWatch lastEventId:_lastEventId filesHashes:_filesHashes];
    [_fileSystemMonitor startAndDoOnSyncNeeded:^(FileSystemMonitor *sender) {
        LOG(@"Saving last event %lu", [_lastEventId unsignedLongLongValue]);

        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:sender.lastEventId forKey:@"lastEventId"];
        [defaults setObject:sender.filesHashes forKey:@"filesHashes"];
        [defaults synchronize];
    } doOnFileAdded:^(NSString *path){
        [self handleFileAdd:path];
    } doOnFileUpdated:^(NSString *path){

    } doOnFileDeleted:^(NSString *path){

    }];
}

- (IBAction)testMenuItemClicked:(id)sender {
    [Finder addPathToFavourites:FOTKI_PATH];
}

- (IBAction)settingsMenuItemClicked:(id)sender {
    //[self.window orderOut:self];
    [self.window makeKeyAndOrderFront:self];
}

- (IBAction)itemClicked:(id)sender {
    [Finder addPathToFavourites:FOTKI_PATH];
    return;
    NSImage *badge = [[NSImage imageNamed:@"check.icns"] extractAsImageRepresentationOfSize:0];

    NSImage *fileIcon = [[[NSWorkspace sharedWorkspace] iconForFile:@"/Users/vavaka/tmp/fotki/alcodev.png"] copy];
    NSImage *badgedIcon = [fileIcon putOtherImage:badge];
    [fileIcon release];

    [[NSWorkspace sharedWorkspace] setIcon:badgedIcon forFile:@"/Users/vavaka/tmp/fotki/en2.yml" options:nil];
}

- (IBAction)exitMenuItemClicked:(id)sender {
    //exit
}

- (IBAction)loginButtonClicked:(id)sender {
    FotkiServiceFacade *fotkiServiceFacade = [[[FotkiServiceFacade alloc] init]autorelease];
    [fotkiServiceFacade authenticateWithLogin:@"alcodev" andPassword:@"alcodev"];
}


- (NSImage *)getBadgeImageWithName:(NSString *)name {
    return [[NSImage imageNamed:name] extractAsImageRepresentationOfSize:0];
}

@end
