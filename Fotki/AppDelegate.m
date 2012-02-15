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
#import "DialogUtils.h"
#import "AlbumsExtracter.h"
#import "Album.h"
#import "Async2SyncLock.h"
#import "DragStatusView.h"
#import "AccountInfo.h"
#import "TextUtils.h"
#import "CRCUtils.h"

#define APP_NAME @"Fotki"


@interface AppDelegate ()
- (void)logOuted;

- (void)updateUploadButton;


- (void)logined;


@end

@implementation AppDelegate {
    FotkiServiceFacade *_fotkiServiceFacade;
    NSMutableArray *_filesToUpload;

@private
    NSMutableArray *_albums;

}
@synthesize settingsWindow = _settingsWindow;
@synthesize lastEventId = _lastEventId;
@synthesize uploadWindow = _uploadWindow;
@synthesize albumLinkLabel = _albumLinkLabel;
@synthesize uploadFilesTable = _uploadFilesTable;


- (id)init {
    self = [super init];
    if (self != nil) {
        _fm = [NSFileManager defaultManager];
        _files = [NSMutableArray new];
        _fotkiServiceFacade = [[FotkiServiceFacade alloc] init];
        _filesToUpload = [[NSMutableArray alloc] init];
        [_uploadWindow registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
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
    [_albumLinkLabel release];
    [_uploadFilesTable release];
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
    [self.uploadFilesTable setEnabled:YES];
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
    NSString *sessionId = _fotkiServiceFacade.sessionId;
    if (sessionId) {
        [welcomeLabel setTextColor:[NSColor greenColor]];
        NSString *currentUsername = _fotkiServiceFacade.accountInfo.name;
        NSString *welcomeString = [NSString stringWithFormat:@"Logged in as %@", currentUsername];
        [welcomeLabel setTitleWithMnemonic:welcomeString];

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
        [self.uploadFilesTable registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
        [self.uploadFilesTable setDraggingSourceOperationMask:NSDragOperationCopy forLocal:NO];

        [NSApp activateIgnoringOtherApps:YES];

        [self.albumLinkLabel setHidden:true];
        [self updateUploadButton];
    }
    else {
        [self.settingsWindow center];
        [self.settingsWindow makeKeyAndOrderFront:self];
        [NSApp activateIgnoringOtherApps:YES];
        [self logOuted];
    }

}

- (IBAction)uploadAddFileButtonClicked:(id)sender {
    NSArray *filesUrls = [DialogUtils showOpenImageFileDialog];
    for (NSURL *url in filesUrls) {
        [_filesToUpload addObject:[url path]];
        [self.uploadFilesTable reloadData];
    }
    [self updateUploadButton];
}

- (IBAction)uploadDeleteFileButtonClicked:(id)sender {
    NSInteger selectedRowIndex = [self.uploadFilesTable selectedRow];
    if (selectedRowIndex >= 0) {
        [_filesToUpload removeObjectAtIndex:selectedRowIndex];
        [self.uploadFilesTable reloadData];
    }
    [self updateUploadButton];
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
        [uploadFilesLabel setStringValue:[NSString stringWithFormat:@"Error: %d files of %d was not uploaded", failedFilesCount, [_filesToUpload count]]];
    } else {
        [uploadFilesLabel setTextColor:[NSColor greenColor]];
        [uploadFilesLabel setStringValue:@"Files successfully uploaded"];
    }
    [uploadProgressIndicator stopAnimation:self];
    [uploadButton setEnabled:NO];
    [uploadCancelButton setTitle:@"Close"];
    [uploadCancelButton setEnabled:YES];
    [uploadFilesAddButton setEnabled:NO];
    [uploadFilesDeleteButton setEnabled:NO];
    [self.uploadFilesTable setEnabled:NO];
    [_filesToUpload removeAllObjects];
    [self.uploadFilesTable reloadData];
    [uploadToAlbumComboBox setEnabled:NO];
}

- (void)showUploadedAlbumLink:(NSString *)urlString {
    [self.albumLinkLabel setAllowsEditingTextAttributes:YES];
    [self.albumLinkLabel setSelectable:YES];
    [self.albumLinkLabel setHidden:false];

    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableAttributedString *attributedString = [[[NSMutableAttributedString alloc] init] autorelease];
    [attributedString appendAttributedString:[TextUtils hyperlinkFromString:@"Click to open your album" withURL:url]];

    [self.albumLinkLabel setAttributedStringValue:attributedString];

}

- (void)uploadSelectedPhotos:(id)sender album:(Album *)album {
    int i = 1;
    __block int failedFilesCount = 0;
    for (NSString *filePath in _filesToUpload) {
        [NSThread doInMainThread:^() {
            [self changeUploadFilesLabelText:i :[_filesToUpload count]];
        }          waitUntilDone:YES];
        __block int attemptCount = 0;
        __block BOOL isFileUploaded = NO;
        NSData *data = [FileSystemHelper getFileData:filePath];
        uint32_t crc32sum = [CRCUtils _crcFromData:data];
        NSString *crc32String = [NSString stringWithFormat:@"%lu", (unsigned long)crc32sum];
        [NSThread runAsyncBlockSynchronously:^(Async2SyncLock *lock) {
            [_fotkiServiceFacade checkCRC:crc32String toTheAlbum:album
                                     onSuccess:^(NSString *exist) {
                                         LOG(@"File %@ exist on server...", filePath);
                                         isFileUploaded = YES;
                                         [lock asyncFinished];
                                     } onError:^(Error *error) {
                LOG(@"File %@ not exist on server. Try to upload....", filePath);

                while (attemptCount < 1 && !isFileUploaded) {
                    [NSThread runAsyncBlockSynchronously:^(Async2SyncLock *lock) {
                        [_fotkiServiceFacade uploadPicture:filePath crc32:crc32String toTheAlbum:album
                                                 onSuccess:^(id object) {
                                                     LOG(@"File %@ successfully uploaded.", filePath);
                                                     isFileUploaded = YES;
                                                     [lock asyncFinished];
                                                 } onError:^(Error *error) {
                            [lock asyncFinished];
                            LOG(@"Error uploading file %@. Error: %@", filePath, error);
                            attemptCount++;
                        }];
                    }];
                }
                [lock asyncFinished];
                attemptCount++;
            }];
        }];
        

        if (!isFileUploaded){
            failedFilesCount++;
        }
        i++;
    }
    [NSThread runAsyncBlockSynchronously:^(Async2SyncLock *lock) {
        [_fotkiServiceFacade getAlbumUrl:album.id
                               onSuccess:^(NSString *albumUrl) {
                                   LOG(@"Url Loaded: %@", albumUrl);
                                   [self showUploadedAlbumLink:albumUrl];
                                   [lock asyncFinished];
                               }
                                 onError:^(id error) {
                                     LOG(@"Url Not Loaded error: %@"), error;
                                     [lock asyncFinished];
                                 }];
    }];

    [NSThread doInMainThread:^() {
        [self setUploadWindowFinishState:failedFilesCount];
    }          waitUntilDone:YES];
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
    [self.uploadFilesTable reloadData];
    [self.uploadWindow close];

}

- (int)numberOfRowsInTableView:(NSTableView *)tableView {
    return [_filesToUpload count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
    NSString *valueToDisplay = [_filesToUpload objectAtIndex:rowIndex];
    return valueToDisplay;
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation {
    NSPasteboard *pasteboard;
    pasteboard = [info draggingPasteboard];

    if ([[pasteboard types] containsObject:NSFilenamesPboardType]) {
        NSArray *files = [pasteboard propertyListForType:NSFilenamesPboardType];
        NSMutableArray *images = [[FileSystemHelper getImagesFromFiles:files] retain];
        [_filesToUpload addObjectsFromArray:images];
        [images release];
        [self.uploadFilesTable reloadData];

        [self updateUploadButton];
    }
}

- (NSDragOperation)tableView:(NSTableView *)pTableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)op {
    // Add code here to validate the drop
    //NSLog(@"validate Drop");
    return NSDragOperationEvery;
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

    [statusItem setHighlightMode:YES];

    DragStatusView *dragView = [[[DragStatusView alloc] initWithFrame:NSMakeRect(0, 0, 24, 24)
                                                              andMenu:statusMenu
                                                    andStatusMenuItem:statusItem onFilesDragged:^(NSArray *files) {
                [_filesToUpload removeAllObjects];
                [_filesToUpload addObjectsFromArray:files];
                [self.uploadFilesTable reloadData];

                [self uploadMenuClicked:nil];
            }] autorelease];
    [statusItem setView:dragView];

    [loginButton setTitle:@"Login"];
    [notificationLabel setTitle:@""];

    [self registerDefaults];
    [self addFotkiPathToFavourites];

    [self.uploadFilesTable setDataSource:self];
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
    NSString *sessionId = _fotkiServiceFacade.sessionId;
    if (sessionId) {
        [self logined];
    }
    else {
        [self logOuted];
    }
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
    NSString *currentUsername = _fotkiServiceFacade.accountInfo.name;
    NSString *welcomeString = [NSString stringWithFormat:@"Welcome %@!", currentUsername];
    [notificationLabel setTitle:welcomeString];
    [loginTextField setEnabled:false];
    [passwordSecureTextField setEnabled:false];
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
                                         [loginButton setTitle:@"Logout"];
                                     }
                                             onError:^(id error) {
                                                 LOG(@"Authentication error: %@", error);
                                                 [self showErrorAccountNotification];
                                                 [loginButton setTitle:@"Login"];
                                             } onForbidden:^(id object) {
        [self showForbiddenAccessNotification];

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

- (void)logined {
    [notificationLabel setTextColor:[NSColor greenColor]];
    NSString *currentUsername = _fotkiServiceFacade.accountInfo.name;
    NSString *welcomeString = [NSString stringWithFormat:@"Logged in as %@", currentUsername];
    [notificationLabel setTitle:welcomeString];
    [loginTextField setEnabled:false];
    [passwordSecureTextField setEnabled:false];
    [loginButton setTitle:@"Logout"];
}

- (void)logOuted {
    [notificationLabel setTitle:@""];
    [loginTextField setEnabled:true];
    [passwordSecureTextField setEnabled:true];
    [loginButton setTitle:@"Login"];
}

- (IBAction)loginButtonClicked:(id)sender {
    NSString *sessionId = _fotkiServiceFacade.sessionId;
    if (sessionId) {
        _fotkiServiceFacade.logOut;
        [notificationLabel setTitle:@""];
        [loginTextField setEnabled:true];
        [passwordSecureTextField setEnabled:true];
        [loginButton setTitle:@"Login"];
    }
    else {
        NSString *login = [loginTextField stringValue];
        NSString *password = [passwordSecureTextField stringValue];
        [loginButton setTitle:@"Logging in..."];
        [self authenticateWithLogin:login andPassword:password];
        [notificationLabel setTextColor:[NSColor greenColor]];
    }
}

- (void)updateUploadButton {
    if (self.uploadFilesTable.numberOfRows > 0) {
        [uploadButton setEnabled:YES];
    } else {
        [uploadButton setEnabled:NO];
    }
}
@end
