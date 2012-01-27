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
#import "FileSystemHelper.h"
#import "FotkiServiceFacade.h"
#import "CheckoutManager.h"
#import "BadgeUtils.h"
#import "ImageWithSiteSynchronizator.h"
#import "Error.h"
#import "Folder.h"
#import "DirectoryUtils.h"
#import "NSImage+Helper.h"

#define APP_NAME @"Fotki"


@interface AppDelegate ()

@end

@implementation AppDelegate {
    FotkiServiceFacade *_fotkiServiceFacade;
}
@synthesize window = _window;
@synthesize lastEventId = _lastEventId;

- (id)init {
    self = [super init];
    if (self != nil) {
        _fm = [NSFileManager defaultManager];
        _files = [NSMutableArray new];
        _fotkiServiceFacade = [[FotkiServiceFacade alloc] init];
    }
    return self;
}

- (void)dealloc {
    [statusMenu release];
    [statusItem release];
    [loginButton release];
    [loginTextField release];
    [passwordSecureTextField release];
    [notificationLabel release];
    [synchronizeMenuItem release];

    [_files release];
    [_filesHashes release];
    [_lastEventId release];

    [_appStartedTimestamp release];

    [_fileSystemMonitor release];

    [_fotkiServiceFacade release];
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
}


- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)app {
    [_fileSystemMonitor shutDown];
    return NSTerminateNow;
}

- (void)handleFileAdd:(NSString *)path {
    BOOL isUserAuthenticated = _fotkiServiceFacade && _fotkiServiceFacade.sessionId;
    if (!isUserAuthenticated || ![FileSystemHelper isImageFileAtPath:path]) {
        return;
    }

    [NSThread doInNewThread:^{
        [BadgeUtils putUpdatedBadgeOnFileIconAtPath:path];
        [ImageWithSiteSynchronizator synchronize:path serviceFacade:_fotkiServiceFacade];
    }];
}

- (void)registerDefaults {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *appDefaults = [NSDictionary
            dictionaryWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithUnsignedLongLong:0], [NSMutableDictionary new], nil]
                          forKeys:[NSArray arrayWithObjects:@"lastEventId", @"filesHashes", nil]];
    [defaults registerDefaults:appDefaults];
}

- (void)addFotkiPathToFavourites {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isFotkiPathAlreadyExists = [fileManager fileExistsAtPath:[DirectoryUtils getFotkiPath]];
    if (!isFotkiPathAlreadyExists) {
        [fileManager createDirectoryAtPath:[DirectoryUtils getFotkiPath] withIntermediateDirectories:YES attributes:nil error:nil];
    }
    [Finder addPathToFavourites:[DirectoryUtils getFotkiPath]];
}

- (void)fileMonitorCreateAndStart {

    _lastEventId = [NSNumber numberWithUnsignedLongLong:0];

    NSArray *pathsToWatch = [NSArray arrayWithObject:[DirectoryUtils getFotkiPath]];
    _fileSystemMonitor = [[FileSystemMonitor alloc] initWithPaths:pathsToWatch lastEventId:_lastEventId filesHashes:_filesHashes];
    [_fileSystemMonitor startAndDoOnSyncNeeded:^(FileSystemMonitor *sender) {
        _lastEventId = sender.lastEventId;
        LOG(@"Saving last event %lu", [_lastEventId unsignedLongLongValue]);
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:sender.lastEventId forKey:@"lastEventId"];
        [defaults setObject:sender.filesHashes forKey:@"filesHashes"];
        [defaults synchronize];
    }                            doOnFileAdded:^(NSString *path) {
        [self handleFileAdd:path];
    }                          doOnFileUpdated:^(NSString *path) {

    }                          doOnFileDeleted:^(NSString *path) {

    }];
}

- (void)awakeFromNib {
    statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
    [statusItem setMenu:statusMenu];
    [statusMenu setAutoenablesItems:NO];
    NSImage *iconImage = [[NSImage imageNamed:@"fotki_icon.png"] extractAsImageRepresentationOfSize:0];
    [statusItem setImage:iconImage];
    [statusItem setHighlightMode:YES];

    [loginButton setTitle:@"Login"];

    [notificationLabel setTitle:@""];

    [self registerDefaults];

    [self addFotkiPathToFavourites];

    _appStartedTimestamp = [[NSDate date] retain];
    _filesHashes = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"filesHashes"] mutableCopy];

    [self fileMonitorCreateAndStart];

    __block NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *login = [defaults objectForKey:@"login"];
    NSString *password = [defaults objectForKey:@"password"];
    if (login) {
        [loginTextField setStringValue:login];
        [passwordSecureTextField setStringValue:password];
        [_fotkiServiceFacade authenticateWithLogin:login andPassword:password
                                         onSuccess:^(id sessionId) {
                                             LOG(@"Session ID is: %@", sessionId);
                                             defaults = [NSUserDefaults standardUserDefaults];
                                             [defaults setObject:login forKey:@"login"];
                                             [defaults setObject:password forKey:@"password"];
                                             [defaults synchronize];
                                         }
                                                 onError:^(id error) {
                                                     LOG(@"Authentication error: %@", error);
                                                     [self.window makeKeyAndOrderFront:self];
                                                 } onForbidden:^(id object) {
            LOG(@"Access is forbidden");
            [self.window makeKeyAndOrderFront:self];
        }];
    } else {
        LOG(@"User's login and password not assigned yet.");
        [self.window makeKeyAndOrderFront:self];
    }
}

- (IBAction)testMenuItemClicked:(id)sender {
    [Finder addPathToFavourites:[DirectoryUtils getFotkiPath]];
}

- (IBAction)settingsMenuItemClicked:(id)sender {
    //[self.window orderOut:self];
    [self.window makeKeyAndOrderFront:self];
}

- (void)synchronizationStart {
    [BadgeUtils putUpdatedBadgeOnFileIconAtPath:[DirectoryUtils getFotkiPath]];
    [synchronizeMenuItem setTitle:@"Synchronizing..."];
    [synchronizeMenuItem setEnabled:NO];
    [loginButton setEnabled:NO];
    [_fileSystemMonitor stop];
}

- (void)synchronizationFinished {
    [BadgeUtils putCheckBadgeOnFileIconAtPath:[DirectoryUtils getFotkiPath]];
    [synchronizeMenuItem setTitle:@"Synchronize"];
    [synchronizeMenuItem setEnabled:YES];
    [loginButton setEnabled:YES];
    [_fileSystemMonitor start];
}

- (IBAction)synchronizeMenuItemClicked:(id)sender {
    [self synchronizationStart];
    if (_fotkiServiceFacade) {
        [_fotkiServiceFacade getAlbumsPlain:^(NSMutableArray *albums) {
            if ([albums count] > 0) {
                [_fotkiServiceFacade getAlbums:^(id rootFolders) {
                    NSFileManager *fileManager = [NSFileManager defaultManager];
                    [NSThread doInNewThread:^{
                        NSString *fotkiPath = [DirectoryUtils getFotkiPath];
                        [CheckoutManager clearDirectory:fotkiPath withFileManager:fileManager];
                        [CheckoutManager createFoldersHierarchyOnHardDisk:rootFolders inDirectory:fotkiPath withFileManager:fileManager serviceFacade:_fotkiServiceFacade onFinish:^(id object) {
                        }];
                        LOG(@"Folders' hierarchy created successfully.");
                        [self synchronizationFinished];
                    }];
                }                      onError:^(Error *error) {
                    LOG(@"Checkout error: %@", error);
                    [self synchronizationFinished];
                }];
            } else {
                [_fotkiServiceFacade getPublicHomeFolder:^(Folder *publicHomeFolder) {
                    [_fotkiServiceFacade createAlbum:@"Mac album" parentFolderId:publicHomeFolder.id onSuccess:^(id object) {
                        LOG(@"Mac album successfully created");
                        [self synchronizationFinished];
                        [self synchronizeMenuItemClicked:sender];
                    }                        onError:^(Error *error) {
                        LOG(@"Error creating Mac album: %@", error);
                        [self synchronizationFinished];
                    }];
                }                                onError:^(Error *error) {
                    LOG(@"Error getting public home folder: %@", error);
                    [self synchronizationFinished];
                }];
            }
        }                           onError:^(Error *error) {
            LOG(@"Error getting albums plain: %@", error);
            [self synchronizationFinished];
        }];

    }
}

- (IBAction)exitMenuItemClicked:(id)sender {
    LOG(@"Application finished with exit code 0");
    [_fileSystemMonitor shutDown];
    exit(0);
}

- (void)showSuccessAccountSavedNotification {
    [notificationLabel setTextColor:[NSColor greenColor]];
    [notificationLabel setTitle:@"Authentification success"];
}

- (void)showErrorAccountNotification {
    [notificationLabel setTextColor:[NSColor redColor]];
    [notificationLabel setTitle:@"Authentification failed"];
}

- (void)showForbiddenAccessNotification {
    [notificationLabel setTextColor:[NSColor redColor]];
    [notificationLabel setTitle:@"This is a demo version. You should log in only from test account"];
}

- (void)authenticateWithLogin:(NSString *)login andPassword:(NSString *)password {
    [_fotkiServiceFacade authenticateWithLogin:login andPassword:password
                                     onSuccess:^(id sessionId) {
                                         LOG(@"Session ID is: %@", sessionId);
                                         NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                                         [defaults setObject:login forKey:@"login"];
                                         [defaults setObject:password forKey:@"password"];
                                         [defaults synchronize];
                                         [self showSuccessAccountSavedNotification];
                                         [loginButton setTitle:@"Login"];
                                     }
                                             onError:^(id error) {
                                                 LOG(@"Authentication error: %@", error);
                                                 [self showErrorAccountNotification];
                                                 [loginButton setTitle:@"Login"];
                                             } onForbidden:^(id object) {
        [self showForbiddenAccessNotification];
        [loginButton setTitle:@"Login"];
    }];
}

- (IBAction)loginButtonClicked:(id)sender {
    NSString *login = [loginTextField stringValue];
    NSString *password = [passwordSecureTextField stringValue];
    [loginButton setTitle:@"Logging in..."];
    [self authenticateWithLogin:login andPassword:password];
}

@end
