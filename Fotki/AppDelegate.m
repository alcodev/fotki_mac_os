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
#import "Error.h"
#import "DialogUtils.h"
#import "AlbumsExtracter.h"
#import "Album.h"
#import "Async2SyncLock.h"
#import "DragStatusView.h"
#import "AccountInfo.h"
#import "TextUtils.h"
#import "CRCUtils.h"
#import "DateUtils.h"
#import "SettingsWindowController.h"
#import "ApiServiceException.h"
#import "ApiConnectionException.h"
#import "UploadWindowController.h"

#define APP_NAME @"Fotki"


@interface AppDelegate ()

@property(nonatomic, retain) SettingsWindowController *controllerSettingsWindow;

@property(nonatomic, retain) UploadWindowController *controllerUploadWindow;

@property(nonatomic, retain) DragStatusView *dragStatusView;

- (AccountInfo *)doSyncLoginWithUsername:(NSString *)username password:(NSString *)password;

- (AccountInfo *)doAsyncLoginWithUsername:(NSString *)username password:(NSString *)password;

- (void)doClearSession;

- (void)doLogout;

- (void)restoreSession;

- (void)uploadSelectedPhotos:(id)sender album:(Album *)album;

@end

@implementation AppDelegate {
    FotkiServiceFacade *_fotkiServiceFacade;
    NSMutableArray *_filesToUpload;

@private
    NSMutableArray *_albums;

}
@synthesize settingsWindow = _settingsWindow;
@synthesize uploadWindow = _uploadWindow;
@synthesize albumLinkLabel = _albumLinkLabel;
@synthesize uploadFilesTable = _uploadFilesTable;
@synthesize dragStatusView = _dragStatusView;
@synthesize totalProgressLabel = _totalProgressLabel;
@synthesize currentFileProgressLabel = _currentFileProgressLabel;
@synthesize currentFileProgressIndicator = _currentFileProgressIndicator;
@synthesize totalFileProgressIndicator = _totalFileProgressIndicator;
@synthesize controllerSettingsWindow = _controllerSettingsWindow;
@synthesize controllerUploadWindow = _controllerUploadWindow;


- (id)init {
    self = [super init];
    if (self != nil) {
        _fm = [NSFileManager defaultManager];
        _fotkiServiceFacade = [[FotkiServiceFacade alloc] init];
        _filesToUpload = [[NSMutableArray alloc] init];
        [_uploadWindow registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
    }
    return self;
}

- (void)dealloc {
    [statusMenu release];
    [statusItem release];
    [synchronizeMenuItem release];

    [_fotkiServiceFacade release];
    [_albums release];
    [_filesToUpload release];
    [_albumLinkLabel release];
    [_uploadFilesTable release];
    [_dragStatusView release];
    [_totalProgressLabel release];
    [_currentFileProgressLabel release];
    [_currentFileProgressIndicator release];
    [_totalFileProgressIndicator release];
    [_controllerSettingsWindow release];
    [_controllerUploadWindow release];
    [super dealloc];
}

//-----------------------------------------------------------------------------------------
// Main menu handlers
//-----------------------------------------------------------------------------------------

- (IBAction)uploadMenuClicked:(id)sender {
    [self.controllerUploadWindow setStateInitializedWithAccountInfo:_fotkiServiceFacade.accountInfo];
    [self.controllerUploadWindow showWindow:self];
}

- (IBAction)settingsMenuItemClicked:(id)sender {
    [self.controllerSettingsWindow showWindow:self];
}

- (IBAction)exitMenuItemClicked:(id)sender {
    LOG(@"Application finished with exit code 0");
    exit(0);
}

- (IBAction)uploadCancelButtonClicked:(id)sender {
    [_filesToUpload removeAllObjects];
    [self.uploadFilesTable reloadData];
    [self.uploadWindow close];

}

//-----------------------------------------------------------------------------------------

- (AccountInfo *)doSyncLoginWithUsername:(NSString *)username password:(NSString *)password {
    @try {
        [self.controllerSettingsWindow setStateAsLoggingIn];

        AccountInfo *accountInfo = [_fotkiServiceFacade authenticateWithLogin:username andPassword:password];
        accountInfo.username = username;
        accountInfo.password = password;
        LOG(@"Authentication success, session ID is: %@", _fotkiServiceFacade.sessionId);

        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:username forKey:@"login"];
        [defaults setObject:password forKey:@"password"];
        [defaults synchronize];

        [self.dragStatusView changeIconState:YES];

        [self.controllerSettingsWindow setStateAsLoggedInWithAccountInfo:accountInfo];
    } @catch(ApiConnectionException *ex) {
        LOG(@"Authentication error: %@", ex.description);
        [self.controllerSettingsWindow setStateAsErrorWithUsername:username passowrd:password status:@"Connection error"];
    } @catch(ApiException *ex) {
        LOG(@"Authentication error: %@", ex.description);
        [self.controllerSettingsWindow setStateAsNotLoggedInWithStatus:@"Authentication error"];
    }
}

- (AccountInfo *)doAsyncLoginWithUsername:(NSString *)username password:(NSString *)password {
   [NSThread doInNewThread:^{
       [self doSyncLoginWithUsername:username password:password];
   }];
}

- (void)doClearSession {
    [self.controllerSettingsWindow setStateAsNotLoggedInWithStatus:@"Logged out"];
}

- (void)doLogout {
    [_fotkiServiceFacade logOut];
    [self doClearSession];
}

- (void)restoreSession {
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
        [self.controllerUploadWindow setStateInitializedWithAccountInfo:_fotkiServiceFacade.accountInfo];
        [self.controllerUploadWindow showWindow:self];
        [self.controllerUploadWindow.arrayFilesToUpload addObjectsFromArray:files];
        [self.controllerUploadWindow.uploadFilesTable reloadData];
    }] autorelease];
    [statusItem setView:self.dragStatusView];

    [self.uploadFilesTable setDataSource:self];
    [uploadProgressIndicator setDisplayedWhenStopped:NO];

    self.controllerSettingsWindow = [SettingsWindowController controllerWithOnNeedLogIn:^(NSString *username, NSString *password) {
        [self doAsyncLoginWithUsername:username password:password];
    } onNeedLogoutCallback:^{
        [self doLogout];
    }];

    self.controllerUploadWindow = [UploadWindowController controller];
    self.controllerUploadWindow.onNeedAlbums = ^{
        return [_fotkiServiceFacade getAlbums];
    };
    self.controllerUploadWindow.onNeedAcceptDrop = ^(id<NSDraggingInfo> draggingInfo) {
        NSPasteboard *pasteboard;
        pasteboard = [draggingInfo draggingPasteboard];
        if ([[pasteboard types] containsObject:NSFilenamesPboardType]) {
            NSArray *pathsAll = [pasteboard propertyListForType:NSFilenamesPboardType];
            NSArray *pathsImages = [FileSystemHelper getImagesFromFiles:pathsAll];
            [self.controllerUploadWindow.arrayFilesToUpload addObjectsFromArray:pathsImages];
        }
    };
    self.controllerUploadWindow.onAddFileButtonClicked = ^{
        NSArray *arraySelectedUrls = [DialogUtils showOpenImageFileDialog];
        for (NSURL *url in arraySelectedUrls) {
            [self.controllerUploadWindow.arrayFilesToUpload addObject:[url path]];
        }
    };
    self.controllerUploadWindow.onDeleteFileButtonClicked = ^(NSNumber *selectedRowIndex){
        if ([selectedRowIndex integerValue] >= 0) {
            [self.controllerUploadWindow.arrayFilesToUpload removeObjectAtIndex:(NSUInteger) [selectedRowIndex integerValue]];
        }
    };
    self.controllerUploadWindow.onNeedUpload = ^{
        self.dragStatusView.isEnable = NO;
        [self.controllerUploadWindow setStateUploading];

        [NSThread doInNewThread:^{
            //[self uploadSelectedPhotos:sender album:self.controllerUploadWindow.selectedAlbum];
        }];
    };

    [self restoreSession];
}

@end
