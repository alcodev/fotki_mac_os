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
#import "Album.h"
#import "Photo.h"
#import "ImageDownloader.h"
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
        _isCheckoutMode = NO;
    }
    return self;
}

- (void)dealloc {
    [statusMenu release];
    [statusItem release];
    [loginButton release];
    [uploadPhotoButton release];
    [downloadButton release];
    [createFolderButton release];
    [createAlbumButton release];

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
    [uploadPhotoButton setTitle:@"Upload"];
    [buildFoldersTreeButton setTitle:@"Get Folders Tree"];
    [downloadButton setTitle:@"Download"];
    [createFolderButton setTitle:@"Create Folder"];
    [createAlbumButton setTitle:@"Create Album"];

    [checkoutButton setTitle:@"Checkout"];

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
    _fotkiServiceFacade = [[FotkiServiceFacade alloc] init];
    [_fotkiServiceFacade authenticateWithLogin:@"alcodev" andPassword:@"alcodev"
                                     onSuccess:^(id sessionId) {
                                         LOG(@"Session ID is: %@", sessionId);
                                     }
                                       onError:^(id error) {
                                           LOG(@"Authentication error: %@", error);
                                       }];
}

- (IBAction)uploadPhotoButtonClicked:(id)sender {
    if (_fotkiServiceFacade) {
        [_fotkiServiceFacade getAlbumsPlain:^(id albums) {
            if (albums && [albums count] > 0) {
                Album *album = (Album *) [albums objectAtIndex:0];
                if (album) {
                    LOG(@"Album: id - %@ name - %@ \n", album.id, album.name);
                    [_fotkiServiceFacade uploadPicture:@"/Users/aistomin/Pictures/7973801.jpg" toTheAlbum:[albums lastObject] onSuccess:^(id object) {
                        LOG(@"File successfully uploaded");
                    }                          onError:^(id object) {
                        LOG(@"Error uploading file: %@", object);
                    }];
                } else {
                    LOG(@"Create album first");
                }
            }
        }                           onError:^(id error) {
            LOG(@"Error getting albums");
        }];

    } else {
        LOG(@"Press login button first");
    }

}

- (IBAction)buildFoldersTreeButtonClicked:(id)sender {
    if (_fotkiServiceFacade) {
        [_fotkiServiceFacade getAlbums:^(id rootFolders) {
            LOG(@"Folders Tree built successfully");
        }                      onError:^(id error) {
            LOG(@"Error building folders tree: %@", error);
        }];
    }

}

- (IBAction)downloadButtonClicked:(id)sender {

    if (_fotkiServiceFacade) {
        [_fotkiServiceFacade getAlbumsPlain:^(id albums) {
            for (Album *album in albums) {
                [_fotkiServiceFacade getPhotosFromTheAlbum:album onSuccess:^(id photos) {
                    for (Photo *photo in photos) {
                        LOG(@"Photo id=%@; title=%@; original_url=%@; album_id=%@",
                        photo.id,
                        photo.title,
                        photo.originalUrl,
                        photo.albumId);
                        NSString *filePath = [NSString stringWithFormat:@"/Users/aistomin/tmp/%@.%@",
                                                                        photo.title,
                                                                        [photo.originalUrl pathExtension]];
                        [ImageDownloader downloadImageFromUrl:photo.originalUrl toFile:filePath];
                    }
                }                                  onError:^(id error) {
                    LOG(@"Error building folders tree: %@", error);
                }];
            }
        }                           onError:^(id error) {
            LOG(@"Error getting albums");
        }];

    } else {
        LOG(@"Press login button first");
    }
}

- (IBAction)createFolderButtonClicked:(id)sender {
    if (_fotkiServiceFacade) {
        [_fotkiServiceFacade createFolder:@"TestFolderCreatedByApp" parentFolderId:@"4293823877" onSuccess:^(id folderId) {
            LOG(@"Folder successfully created, folder id: %@", folderId);
        }                         onError:^(id error) {
            LOG(@"Error creating folder: %@", error);
        }];
    }
}

- (IBAction)createAlbumButtonClicked:(id)sender {
    if (_fotkiServiceFacade) {
        [_fotkiServiceFacade createAlbum:@"TestAlbumCreatedByApp" parentFolderId:@"4293823877" onSuccess:^(id folderId) {
            LOG(@"Album successfully created, album id: %@", folderId);
        }                        onError:^(id error) {
            LOG(@"Album creating folder: %@", error);
        }];
    }
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
