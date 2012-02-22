//
//  AppDelegate.m
//  Fotki
//
//  Created by Vladimir Kuznetsov on 12/24/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "NSThread+Helper.h"
#import "FileSystemHelper.h"
#import "FotkiServiceFacade.h"
#import "DialogUtils.h"
#import "Album.h"
#import "DragStatusView.h"
#import "Account.h"
#import "CRCUtils.h"
#import "DateUtils.h"
#import "SettingsWindowController.h"
#import "ApiServiceException.h"
#import "ApiConnectionException.h"
#import "UploadWindowController.h"
#import "UploadFilesStatisticsCalculator.h"
#import "UploadFilesDataSource.h"
#import "AboutWindowController.h"

#define APP_NAME @"Fotki"


@interface AppDelegate ()

@property(nonatomic, retain) FotkiServiceFacade *serviceFacade;
@property(nonatomic, retain) Account *currentAccount;
@property(nonatomic, retain) UploadWindowController *controllerUploadWindow;
@property(nonatomic, retain) SettingsWindowController *controllerSettingsWindow;
@property(nonatomic, retain) AboutWindowController *controllerAboutWindow;
@property(nonatomic, retain) DragStatusView *dragStatusView;

- (void)doSyncLoginWithUsername:(NSString *)username password:(NSString *)password;

- (void)doAsyncLoginWithUsername:(NSString *)username password:(NSString *)password;

- (void)doClearSession;

- (void)doLogout;

- (void)restoreSession;

- (void)uploadImagesAtPaths:(NSArray *)pathsFiles toAlbum:(Album *)album;

- (void)doUploadImagesAtPaths:(NSArray *)arrayPathsFiles toAlbum:(Album *)album;

- (NSString *)getUrlToAlbum:(Album *)album;

- (void)setStateAsLoggedIn;

- (void)setStateAsLoggedOut;

- (void)addUniqueElementsFromArray:(NSArray *)srcArray toArray:(NSMutableArray *)dstArray;


@end

@implementation AppDelegate

@synthesize serviceFacade = _serviceFacade;
@synthesize currentAccount = _currentAccount;

@synthesize settingsWindow = _settingsWindow;
@synthesize uploadWindow = _uploadWindow;
@synthesize albumLinkLabel = _albumLinkLabel;
@synthesize dragStatusView = _dragStatusView;
@synthesize totalProgressLabel = _totalProgressLabel;
@synthesize currentFileProgressLabel = _currentFileProgressLabel;
@synthesize currentFileProgressIndicator = _currentFileProgressIndicator;
@synthesize totalFileProgressIndicator = _totalFileProgressIndicator;

@synthesize controllerSettingsWindow = _controllerSettingsWindow;
@synthesize controllerUploadWindow = _controllerUploadWindow;
@synthesize isUploadFinished = _isUploadFinished;
@synthesize controllerAboutWindow = _controllerAboutWindow;


- (id)init {
    self = [super init];
    if (self != nil) {
        self.serviceFacade = [[[FotkiServiceFacade alloc] init] autorelease];
        [_uploadWindow registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
    }
    return self;
}

- (void)dealloc {
    [_serviceFacade release];
    [_currentAccount release];

    [statusMenu release];
    [statusItem release];
    [synchronizeMenuItem release];

    [_albumLinkLabel release];
    [_dragStatusView release];
    [_totalProgressLabel release];
    [_currentFileProgressLabel release];
    [_currentFileProgressIndicator release];
    [_totalFileProgressIndicator release];
    [_controllerSettingsWindow release];
    [_controllerUploadWindow release];

    [_controllerAboutWindow release];
    [super dealloc];
}

//-----------------------------------------------------------------------------------------
// Main menu handlers
//-----------------------------------------------------------------------------------------

- (IBAction)uploadMenuClicked:(id)sender {
    [self.controllerUploadWindow showWindow:self];
}

- (IBAction)settingsMenuItemClicked:(id)sender {
    [self.controllerSettingsWindow showWindow:self];
}

- (IBAction)aboutMenuClicked:(id)sender {
    [self.controllerAboutWindow showWindow:self];
}

- (IBAction)exitMenuItemClicked:(id)sender {
    LOG(@"Application finished with exit code 0");
    exit(0);
}

//-----------------------------------------------------------------------------------------

- (void)doSyncLoginWithUsername:(NSString *)username password:(NSString *)password {
    @try {
        [self.controllerSettingsWindow setStateAsLoggingInWithUsername:username passowrd:password];

        self.currentAccount = [self.serviceFacade authenticateWithLogin:username andPassword:password];
        self.currentAccount.username = username;
        self.currentAccount.password = password;
        LOG(@"Authentication success, session ID is: %@", self.serviceFacade.sessionId);

        self.currentAccount.albums = [self.serviceFacade getAlbums];

        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:username forKey:@"login"];
        [defaults setObject:password forKey:@"password"];
        [defaults synchronize];

        [self.dragStatusView changeIconState:YES];

        [self setStateAsLoggedIn];
        [self.controllerSettingsWindow setStateAsLoggedInWithAccount:self.currentAccount];
    } @catch (ApiConnectionException *ex) {
        LOG(@"Authentication error: %@", ex.description);
        [self setStateAsLoggedOut];
        [self.controllerSettingsWindow setStateAsErrorWithUsername:username passowrd:password status:@"Connection error"];
    } @catch (ApiException *ex) {
        LOG(@"Authentication error: %@", ex.description);
        [self setStateAsLoggedOut];
        [self.controllerSettingsWindow setStateAsNotLoggedInWithStatus:@"Authentication error"];
    }
}

- (void)doAsyncLoginWithUsername:(NSString *)username password:(NSString *)password {
    [NSThread doInNewThread:^{
        [self doSyncLoginWithUsername:username password:password];
        [self.controllerUploadWindow setStateInitializedWithAccount:self.currentAccount];
    }];
}

- (void)doClearSession {
    [self setStateAsLoggedOut];
    [self.controllerSettingsWindow setStateAsNotLoggedInWithStatus:@"Logged out"];
}

- (void)doLogout {
    [self.serviceFacade logOut];
    [self doClearSession];
}

- (void)restoreSession {
    [self setStateAsLoggedOut];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *login = [defaults objectForKey:@"login"];
    NSString *password = [defaults objectForKey:@"password"];
    if (login && password) {
        LOG(@"User's login and password were found in Defaults, auto logging in");
        [self doAsyncLoginWithUsername:login password:password];
    } else {
        LOG(@"User's login and password were not found in Defaults, clearing session");
        [self doClearSession];
    }
}

- (void)awakeFromNib {
    statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
    [statusMenu setAutoenablesItems:NO];
    [statusItem setHighlightMode:YES];
    [statusItem setMenu:statusMenu];

    self.dragStatusView = [[[DragStatusView alloc] initWithFrame:NSMakeRect(0, 0, 24, 24) andMenu:statusMenu andStatusMenuItem:statusItem onFilesDragged:^(NSArray *files) {
        [self.controllerUploadWindow setStateInitializedWithAccount:self.currentAccount];
        [self.controllerUploadWindow showWindow:self];
        [self addUniqueElementsFromArray:files toArray:self.controllerUploadWindow.uploadFilesDataSource.arrayFilesToUpload];
        [self.controllerUploadWindow.uploadFilesTable reloadData];
        [self.controllerUploadWindow changeApplyButtonStateBasedOnFormState];
    }] autorelease];
    [statusItem setView:self.dragStatusView];

    self.controllerSettingsWindow = [SettingsWindowController controllerWithOnNeedLogIn:^(NSString *username, NSString *password) {
        [self doAsyncLoginWithUsername:username password:password];
    }                                                              onNeedLogoutCallback:^{
        [self doLogout];
    }];

    self.controllerUploadWindow = [UploadWindowController controller];
    self.controllerUploadWindow.onNeedAlbums = ^{
        return self.currentAccount.albums;
    };
    self.controllerUploadWindow.onNeedAcceptDrop = ^(id <NSDraggingInfo> draggingInfo) {
        NSPasteboard *pasteboard;
        pasteboard = [draggingInfo draggingPasteboard];
        if ([[pasteboard types] containsObject:NSFilenamesPboardType]) {
            NSArray *pathsAll = [pasteboard propertyListForType:NSFilenamesPboardType];
            NSArray *pathsImages = [FileSystemHelper getImagesFromFiles:pathsAll];
            [self addUniqueElementsFromArray:pathsImages toArray:self.controllerUploadWindow.uploadFilesDataSource.arrayFilesToUpload];
            return YES;
        } else {
            return NO;
        }
    };
    self.controllerUploadWindow.onAddFileButtonClicked = ^{
        NSArray *arraySelectedUrls = [DialogUtils showOpenImageFileDialog];
        for (NSURL *url in arraySelectedUrls) {
            if (![self.controllerUploadWindow.uploadFilesDataSource.arrayFilesToUpload containsObject:url.path]) {
                [self.controllerUploadWindow.uploadFilesDataSource.arrayFilesToUpload addObject:[url path]];
            }
        }
    };
    self.controllerUploadWindow.onDeleteFileButtonClicked = ^(NSNumber *selectedRowIndex) {
        if ([selectedRowIndex integerValue] >= 0) {
            [self.controllerUploadWindow.uploadFilesDataSource.arrayFilesToUpload removeObjectAtIndex:(NSUInteger) [selectedRowIndex integerValue]];
        }
    };
    self.controllerUploadWindow.onNeedUpload = ^{
        self.dragStatusView.isEnable = NO;
        [self.controllerUploadWindow setStateUploadingWithFileProgressValue:0.0 totalProgressLabel:@"Start"];

        [NSThread doInNewThread:^{
            [self uploadImagesAtPaths:self.controllerUploadWindow.selectedPaths toAlbum:self.controllerUploadWindow.selectedAlbum];
        }];
    };
    self.controllerUploadWindow.onWindowClose = ^{
        if (self.isUploadFinished){
            self.dragStatusView.isEnable = YES;
            [self.controllerUploadWindow setStateInitializedWithAccount:self.currentAccount];
            self.isUploadFinished = NO;
        }
    };

    self.controllerAboutWindow = [AboutWindowController controller];

    [self restoreSession];
}

- (void)uploadImagesAtPaths:(NSArray *)arrayPathsFiles toAlbum:(Album *)album {
    @try {
        [self doUploadImagesAtPaths:arrayPathsFiles toAlbum:album];
    } @catch (NSException *exception) {
        LOG(@"Error occurred: %@", exception.description);
        [self.controllerUploadWindow addError:exception.description forEvent:@"Upload images"];
        self.dragStatusView.isEnable = YES;
        [self.controllerUploadWindow setStateUploadedWithException:exception];
    }

}

- (void)doUploadImagesAtPaths:(NSArray *)arrayPathsFiles toAlbum:(Album *)album {
    NSString *linkToAlbum = [self getUrlToAlbum:album];

    UploadFilesStatisticsCalculator *statisticsCalculator = [UploadFilesStatisticsCalculator calculatorWithPathsFiles:arrayPathsFiles];
    LOG(@"bytesTotalExpectedToWrite: %d", statisticsCalculator.bytesTotalExpectedToWrite / 1024);
    LOG(@"");
    for (NSInteger indexFilePath = 0; indexFilePath < arrayPathsFiles.count; indexFilePath++) {
        NSString *pathFile = [arrayPathsFiles objectAtIndex:(NSUInteger) indexFilePath];

        BOOL isFileUploaded = NO;

        int countAttempts = 0;
        while (countAttempts < 1 && !isFileUploaded) {
            @try {
                NSString *crcFile = [CRCUtils crcFromDataAsString:[FileSystemHelper getFileData:pathFile]];
                if ([self.serviceFacade checkCrc32:crcFile inAlbum:album]) {
                    LOG(@"File '%@' already exists on server, skipping it", pathFile);
                    isFileUploaded = YES;
                    [statisticsCalculator setUploadSuccessForPath:pathFile];
                } else {
                    LOG(@"File '%@' does not exist on server, uploading it", pathFile);
                    [self.serviceFacade uploadImageAtPath:pathFile crc32:crcFile toAlbum:album uploadProgressBlock:^(NSInteger bytesCurrentLastWritten, NSInteger bytesCurrentTotalWritten, NSInteger bytesCurrentTotalExpectedToWrite) {
                        [statisticsCalculator setCurrentStatisticsWithBytesLastWritten:(NSUInteger) bytesCurrentLastWritten bytesTotalWritten:(NSUInteger) bytesCurrentTotalWritten bytesTotalExpectedToWrite:(NSUInteger) bytesCurrentTotalExpectedToWrite];

                        LOG(@"speed: %f", statisticsCalculator.speed / 1024);

                        LOG(@"bytesCurrentLastWritten: %d", statisticsCalculator.bytesCurrentLastWritten / 1024);
                        LOG(@"bytesCurrentTotalWritten: %d", statisticsCalculator.bytesCurrentTotalWritten / 1024);
                        LOG(@"bytesCurrentTotalExpectedToWrite: %d", statisticsCalculator.bytesCurrentTotalExpectedToWrite / 1024);
                        LOG(@"bytesCurrentLeft: %d", statisticsCalculator.bytesCurrentLeft / 1024);
                        LOG(@"secondsCurrentLeft: %d", statisticsCalculator.secondsCurrentLeft);

                        LOG(@"bytesTotalWritten: %d", statisticsCalculator.bytesTotalWritten / 1024);
                        LOG(@"bytesTotalExpectedToWrite: %d", statisticsCalculator.bytesTotalExpectedToWrite / 1024);
                        LOG(@"bytesTotalLeft: %d", statisticsCalculator.bytesTotalLeft / 1024);
                        LOG(@"secondsTotalLeft: %d", statisticsCalculator.secondsTotalLeft);


                        [NSThread doInMainThread:^() {
                            double valueProgressTotal = statisticsCalculator.bytesTotalWritten * 100 / statisticsCalculator.bytesTotalExpectedToWrite;


                            NSString *statisticText =
                                    [NSString stringWithFormat:@"Uploading %d of %d (%@ of %@) at speed %@. Estimated time left: %@",
                                                               indexFilePath, arrayPathsFiles.count,
                                                               [FileSystemHelper formatFileSize:statisticsCalculator.bytesCurrentTotalWritten],
                                                               [FileSystemHelper formatFileSize:statisticsCalculator.bytesTotalExpectedToWrite],
                                                               [FileSystemHelper formatSpeed:statisticsCalculator.speed],
                                                               [DateUtils formatLeftTime:statisticsCalculator.secondsTotalLeft]];

                            [self.controllerUploadWindow setStateUploadingWithFileProgressValue:valueProgressTotal totalProgressLabel:statisticText];
                        }          waitUntilDone:YES];

                        LOG(@"");
                        LOG(@"");
                    }];

                    LOG(@"File '%@' was successfully uploaded", pathFile);
                    [statisticsCalculator setUploadSuccessForPath:pathFile];
                    isFileUploaded = YES;
                }
            } @catch (ApiException *ex) {
                LOG(@"Error uploading file '%@', reason: %@", pathFile, ex.description);
                [self.controllerUploadWindow addError:ex.description forEvent:[NSString stringWithFormat:@"Uploading file: %@", pathFile]];
                countAttempts++;
                isFileUploaded = NO;
            }
        }

        if (!isFileUploaded) {
            [statisticsCalculator setUploadFailedForPath:pathFile];
        }
    }
    self.isUploadFinished = YES;

    [NSThread doInMainThread:^() {
        [self.controllerUploadWindow setStateUploadedWithLinkToAlbum:linkToAlbum arrayPathsFilesFailed:[statisticsCalculator arrayPathsFilesFailed]];
    }          waitUntilDone:YES];
}

- (NSString *)getUrlToAlbum:(Album *)album {
    @try {
        return [self.serviceFacade getAlbumUrl:album.id];
    } @catch (ApiException *ex) {
        LOG(@"Error getting url for album: %@", album.path);
        [self.controllerUploadWindow addError:ex.description forEvent:@"Error getting url for album"];
        return nil;
    }
}

- (void)setStateAsLoggedIn {
    [uploadMenuItem setEnabled:YES];
    self.dragStatusView.isEnable = YES;
    [self.dragStatusView changeIconState:YES];
}

- (void)setStateAsLoggedOut {
    [uploadMenuItem setEnabled:NO];
    self.dragStatusView.isEnable = NO;
    [self.dragStatusView changeIconState:NO];
}

- (void)addUniqueElementsFromArray:(NSArray *)srcArray toArray:(NSMutableArray *)dstArray {
    NSSet *set = [NSSet setWithArray:srcArray];
    for (NSObject *object in set) {
        if (![dstArray containsObject:object]) {
            [dstArray addObject:object];
        }
    }
}
@end
