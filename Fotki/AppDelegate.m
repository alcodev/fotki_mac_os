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
#import "DialogUtils.h"
#import "AlbumsExtracter.h"
#import "Album.h"
#import "Async2SyncLock.h"

#define APP_NAME @"Fotki"


@interface AppDelegate ()

@end

@implementation AppDelegate {
    FotkiServiceFacade *_fotkiServiceFacade;
    NSMutableArray *_filesToUpload;
@private
    NSWindow *_uploadWindow;
    NSMutableArray *_albums;
}
@synthesize settingsWindow = _settingsWindow;
@synthesize lastEventId = _lastEventId;
@synthesize uploadWindow = _uploadWindow;
@synthesize filesToUpload = _filesToUpload;


- (id)init {
    self = [super init];
    if (self != nil) {
        _fm = [NSFileManager defaultManager];
        _files = [NSMutableArray new];
        _fotkiServiceFacade = [[FotkiServiceFacade alloc] init];
        _filesToUpload = [[NSMutableArray alloc] init];
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
    [_albums release];
    [_filesToUpload release];
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

- (void)setUploadWindowStartState {
    [uploadFilesTable setEnabled:YES];
    [uploadFilesAddButton setEnabled:YES];
    [uploadFilesDeleteButton setEnabled:YES];
    [uploadButton setEnabled:YES];
    [uploadCancelButton setEnabled:YES];
    [uploadCancelButton setTitle:@"Cancel"];
    [uploadFilesLabel setHidden:YES];
    [uploadFilesLabel setTextColor:[NSColor blackColor]];
    [uploadToAlbumComboBox setEnabled:YES];
}

- (IBAction)uploadMenuClicked:(id)sender {
    [uploadToAlbumComboBox removeAllItems];
    for (Album *album in _albums) {
        [uploadToAlbumComboBox addItemWithObjectValue:album.path];
    }
    if ([_albums count] > 0) {
        [uploadToAlbumComboBox selectItemAtIndex:0];
    }
    [self setUploadWindowStartState];
    [self.uploadWindow center];
    [self.uploadWindow makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)uploadAddFileButtonClicked:(id)sender {
    NSArray *filesUrls = [DialogUtils showOpenFileDialog];
    for (NSURL *url in filesUrls) {
        [_filesToUpload addObject:[url path]];
        [uploadFilesTable reloadData];
    }
}

- (IBAction)uploadDeleteFileButtonClicked:(id)sender {
    NSInteger selectedRowIndex = [uploadFilesTable selectedRow];
    if (selectedRowIndex >= 0) {
        [_filesToUpload removeObjectAtIndex:selectedRowIndex];
        [uploadFilesTable reloadData];
    }
}

- (Album *)searchAlbumByPath:(NSString *)albumsPath {
    for (Album *album in _albums) {
        if ([albumsPath isEqualToString:album.path]) {
            return album;
        }
    }
    return nil;
}

- (void)setUploadWindowFinishState:(int)failedFilesCount {
    if (failedFilesCount > 0) {
        [uploadFilesLabel setTextColor:[NSColor redColor]];
        [uploadFilesLabel setStringValue: [NSString stringWithFormat:@"Error: %d files of %d was not uploaded", failedFilesCount, [_filesToUpload count]]];
    }else{
        [uploadFilesLabel setTextColor:[NSColor greenColor]];
        [uploadFilesLabel setStringValue:@"Files successfully uploaded"];
    }
    [uploadProgressIndicator stopAnimation:self];
    [uploadButton setEnabled:NO];
    [uploadCancelButton setTitle:@"Close"];
    [uploadCancelButton setEnabled:YES];
    [uploadFilesAddButton setEnabled:NO];
    [uploadFilesDeleteButton setEnabled:NO];
    [uploadFilesTable setEnabled:NO];
    [_filesToUpload removeAllObjects];
    [uploadFilesTable reloadData];
    [uploadToAlbumComboBox setEnabled:NO];
}

- (void)uploadSelectedPhotos:(id)sender album:(Album *)album {
    int i = 1;
    __block int failedFilesCount = 0;
    for (NSString *filePath in _filesToUpload) {
        [NSThread doInMainThread:^(){
            [self changeUploadFilesLabelText:i :[_filesToUpload count]];
        } waitUntilDone:YES];

        [NSThread runAsyncBlockSynchronously:^(Async2SyncLock *lock) {
            [_fotkiServiceFacade uploadPicture:filePath toTheAlbum:album
                                     onSuccess:^(id object) {
                                         LOG(@"File %@ successfully uploaded.", filePath);
                                         [lock asyncFinished];
                                     } onError:^(Error *error) {
                failedFilesCount++;
                [lock asyncFinished];
                LOG(@"Error uploading file %@. Error: %@", filePath, error);
            }];
        }];
        i++;
    }
    [NSThread doInMainThread:^(){
        [self setUploadWindowFinishState:failedFilesCount];
    } waitUntilDone:YES];
}

- (void)changeUploadFilesLabelText:(int)current:(int)total {
    [uploadFilesLabel setStringValue:[NSString stringWithFormat:@"Uploading %d/%d", current, total]];
}

- (IBAction)uploadButtonClicked:(id)sender {

    NSString *selectedAlbumsPath = [uploadToAlbumComboBox objectValueOfSelectedItem];
    if (!selectedAlbumsPath) {
        LOG(@"Select album to upload");
        return;
    }
    Album *album = [self searchAlbumByPath:selectedAlbumsPath];
    if (!album) {
        LOG(@"Album by path %@ not found.", selectedAlbumsPath);
        return;
    }
    [uploadProgressIndicator startAnimation:sender];
    [uploadFilesLabel setHidden:NO];
    [uploadButton setEnabled:NO];
    [uploadCancelButton setEnabled:NO];
    [self changeUploadFilesLabelText:0 :[_filesToUpload count]];
    [NSThread doInNewThread:^{
        [self uploadSelectedPhotos:sender album:album];
    }];
}

- (IBAction)uploadCancelButtonClicked:(id)sender {
    [_filesToUpload removeAllObjects];
    [uploadFilesTable reloadData];
    [self.uploadWindow close];
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView {
    return [_filesToUpload count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
    NSString *valueToDisplay = [_filesToUpload objectAtIndex:rowIndex];
    return valueToDisplay;
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

    [uploadFilesTable setDataSource:self];
    [uploadProgressIndicator setDisplayedWhenStopped:NO];

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
                                             [self loadAlbumsList];
                                             defaults = [NSUserDefaults standardUserDefaults];
                                             [defaults setObject:login forKey:@"login"];
                                             [defaults setObject:password forKey:@"password"];
                                             [defaults synchronize];
                                         }
                                                 onError:^(id error) {
                                                     LOG(@"Authentication error: %@", error);
                                                     [self.settingsWindow center];
                                                     [self.settingsWindow makeKeyAndOrderFront:self];
                                                     [NSApp activateIgnoringOtherApps:YES];
                                                 } onForbidden:^(id object) {
            LOG(@"Access is forbidden");
            [self.settingsWindow center];
            [self.settingsWindow makeKeyAndOrderFront:self];
            [NSApp activateIgnoringOtherApps:YES];
        }];
    } else {
        LOG(@"User's login and password not assigned yet.");
        [self.settingsWindow center];
        [self.settingsWindow makeKeyAndOrderFront:self];
        [NSApp activateIgnoringOtherApps:YES];
    }
}

- (IBAction)testMenuItemClicked:(id)sender {
    [Finder addPathToFavourites:[DirectoryUtils getFotkiPath]];
}

- (IBAction)settingsMenuItemClicked:(id)sender {
    //[self.window orderOut:self];
    [self.settingsWindow center];
    [self.settingsWindow makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];
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
                                         [self loadAlbumsList];
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

- (void)loadAlbumsList {
    [_fotkiServiceFacade getAlbums:^(NSArray *rootFolders) {
        _albums = [[AlbumsExtracter extractAlbums:rootFolders] retain];
    }
                           onError:^(Error *error) {
                               LOG(@"Error loading albums list: %@", error);
                           }];
}

- (IBAction)loginButtonClicked:(id)sender {
    NSString *login = [loginTextField stringValue];
    NSString *password = [passwordSecureTextField stringValue];
    [loginButton setTitle:@"Logging in..."];
    [self authenticateWithLogin:login andPassword:password];
}

@end
