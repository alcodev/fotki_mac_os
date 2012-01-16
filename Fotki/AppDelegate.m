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
#import "Consts.h"
#import "CheckoutManager.h"
#import "BadgeUtils.h"
#import "ImageWithSiteSynchronizator.h"
#import "Error.h"
#import "Folder.h"

#define APP_NAME @"Fotki"


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

@end

@implementation AppDelegate {
    FotkiServiceFacade *_fotkiServiceFacade;
    BOOL _isCheckoutMode;
}
@synthesize window = _window;
@synthesize lastEventId = _lastEventId;

- (id)init {
    self = [super init];
    if (self != nil) {
        _fm = [NSFileManager defaultManager];
        _files = [NSMutableArray new];
        _fotkiServiceFacade = [[FotkiServiceFacade alloc] init];
        _isCheckoutMode = NO;
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

    [checkoutButton release];

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
    [_fileSystemMonitor stop];
    return NSTerminateNow;
}


- (void)handleFileAdd:(NSString *)path {
    BOOL isUserAuthenticated = _fotkiServiceFacade && _fotkiServiceFacade.sessionId;
    if (!isUserAuthenticated || ![FileSystemHelper isImageFileAtPath:path] || _isCheckoutMode) {
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

- (void)awakeFromNib {
    statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
    [statusItem setMenu:statusMenu];
    [statusItem setTitle:APP_NAME];
    [statusItem setHighlightMode:YES];

    [loginButton setTitle:@"Login"];

    [notificationLabel setTitle:@""];

    [self registerDefaults];

    _appStartedTimestamp = [[NSDate date] retain];
    _filesHashes = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"filesHashes"] mutableCopy];
    _lastEventId = [NSNumber numberWithUnsignedLongLong:0];

    NSArray *pathsToWatch = [NSArray arrayWithObject:FOTKI_PATH];
    _fileSystemMonitor = [[FileSystemMonitor alloc] initWithPaths:pathsToWatch lastEventId:_lastEventId filesHashes:_filesHashes];
    [_fileSystemMonitor startAndDoOnSyncNeeded:^(FileSystemMonitor *sender) {
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
                                           }];
    } else {
        LOG(@"User's login and password not assigned yet.");
        [self.window makeKeyAndOrderFront:self];
    }
}

- (IBAction)testMenuItemClicked:(id)sender {
    [Finder addPathToFavourites:FOTKI_PATH];
}

- (IBAction)settingsMenuItemClicked:(id)sender {
    //[self.window orderOut:self];
    [self.window makeKeyAndOrderFront:self];
}

- (IBAction)synchronizeMenuItemClicked:(id)sender {
    _isCheckoutMode = YES;
    [synchronizeMenuItem setTitle:@"Synchronizing"];
    if (_fotkiServiceFacade) {
        [_fotkiServiceFacade getAlbumsPlain:^(NSMutableArray *albums) {
            if ([albums count] > 0) {
                [_fotkiServiceFacade getAlbums:^(id rootFolders) {
                    NSFileManager *fileManager = [NSFileManager defaultManager];
                    [NSThread doInNewThread:^{
                        [CheckoutManager clearDirectory:FOTKI_PATH withFileManager:fileManager];
                        [CheckoutManager createFoldersHierarchyOnHardDisk:rootFolders inDirectory:FOTKI_PATH withFileManager:fileManager serviceFacade:_fotkiServiceFacade onFinish:^(id object) {
                        }];
                        LOG(@"Folders' hierarchy created successfully.");
                        [synchronizeMenuItem setTitle:@"Synchronize"];
                        _isCheckoutMode = NO;
                    }];
                }                      onError:^(Error *error) {
                    LOG(@"Checkout error: %@", error);
                    [synchronizeMenuItem setTitle:@"Synchronize"];
                    _isCheckoutMode = NO;
                }];
            } else {
                [_fotkiServiceFacade getPublicHomeFolder:^(Folder *publicHomeFolder) {
                    [_fotkiServiceFacade createAlbum:@"Mac album" parentFolderId:publicHomeFolder.id onSuccess:^(id object) {
                        LOG(@"Mac album successfully created");
                        [synchronizeMenuItem setTitle:@"Synchronize"];
                        [self checkoutButtonClicked:sender];
                    }                        onError:^(Error *error) {
                        LOG(@"Error creating Mac album: %@", error);
                        [synchronizeMenuItem setTitle:@"Synchronize"];
                        _isCheckoutMode = NO;
                    }];
                }                                onError:^(Error *error) {
                    LOG(@"Error getting public home folder: %@", error);
                    [synchronizeMenuItem setTitle:@"Synchronize"];
                    _isCheckoutMode = NO;
                }];
            }
        }                           onError:^(Error *error) {
            LOG(@"Error getting albums plain: %@", error);
            [synchronizeMenuItem setTitle:@"Synchronize"];
            _isCheckoutMode = NO;
        }];

    }
}

- (IBAction)exitMenuItemClicked:(id)sender {
    LOG(@"Application finished with exit code 0");
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

- (void)authenticateWithLogin:(NSString *)login andPassword:(NSString *)password {
    [_fotkiServiceFacade authenticateWithLogin:login andPassword:password
                                     onSuccess:^(id sessionId) {
                                         LOG(@"Session ID is: %@", sessionId);
                                         NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                                         [defaults setObject:login forKey:@"login"];
                                         [defaults setObject:password forKey:@"password"];
                                         [defaults synchronize];
                                         [self showSuccessAccountSavedNotification];
                                     }
                                       onError:^(id error) {
                                           LOG(@"Authentication error: %@", error);
                                           [self showErrorAccountNotification];
                                       }];
}

- (IBAction)loginButtonClicked:(id)sender {
    NSString *login = [loginTextField stringValue];
    NSString *password = [passwordSecureTextField stringValue];

    [self authenticateWithLogin:login andPassword:password];
}

- (IBAction)checkoutButtonClicked:(id)sender {
    _isCheckoutMode = YES;
    [checkoutButton setTitle:@"Wait..."];
    if (_fotkiServiceFacade) {
        [_fotkiServiceFacade getAlbumsPlain:^(NSMutableArray *albums) {
            if ([albums count] > 0) {
                [_fotkiServiceFacade getAlbums:^(id rootFolders) {
                    NSFileManager *fileManager = [NSFileManager defaultManager];
                    [NSThread doInNewThread:^{
                        [CheckoutManager clearDirectory:FOTKI_PATH withFileManager:fileManager];
                        [CheckoutManager createFoldersHierarchyOnHardDisk:rootFolders inDirectory:FOTKI_PATH withFileManager:fileManager serviceFacade:_fotkiServiceFacade onFinish:^(id object) {
                        }];
                        LOG(@"Folders' hierarchy created successfully.");
                        [checkoutButton setTitle:@"Checkout"];
                        _isCheckoutMode = NO;
                    }];
                }                      onError:^(Error *error) {
                    LOG(@"Checkout error: %@", error);
                    _isCheckoutMode = NO;
                }];
            } else {
                [_fotkiServiceFacade getPublicHomeFolder:^(Folder *publicHomeFolder) {
                    [_fotkiServiceFacade createAlbum:@"Mac album" parentFolderId:publicHomeFolder.id onSuccess:^(id object) {
                        LOG(@"Mac album successfully created");
                        [self checkoutButtonClicked:sender];
                    }                        onError:^(Error *error) {
                        LOG(@"Error creating Mac album: %@", error);
                        _isCheckoutMode = NO;
                    }];
                }                                onError:^(Error *error) {
                    LOG(@"Error getting public home folder: %@", error);
                    _isCheckoutMode = NO;
                }];
            }
        }                           onError:^(Error *error) {
            LOG(@"Error getting albums plain: %@", error);
            _isCheckoutMode = NO;
        }];

    }
}
@end
