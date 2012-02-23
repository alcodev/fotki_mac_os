//
//  Created by vavaka on 2/18/12.



#import "UploadWindowController.h"
#import "TextUtils.h"
#import "Album.h"
#import "Account.h"
#import "UploadFilesDataSource.h"
#import "ErrorsDataSource.h"
#import "Lib/DataSources/UploadError.h"
#import "ClickableTextField.h"

typedef enum {
    kStateUnknown, kStateInitialized, kStateUploading, kStateUploaded
} UploadWindowState;

@interface UploadWindowController ()

@property(nonatomic, assign) UploadWindowState currentState;

- (void)makeErrorsTabActive;

- (void)prepareWindowBeforeClose;

- (IBAction)onCloseButtonClicked:(id)sender;

- (void)showLinkToAlbum:(NSString *)urlToAlbum withUrlText:(NSString *)urlText;

@end


@implementation UploadWindowController

@synthesize arrayAlbums = _arrayAlbums;

@synthesize welcomeLabel = _welcomeLabel;
@synthesize uploadFilesTable = _uploadFilesTable;
@synthesize uploadFilesAddButton = _uploadFilesAddButton;
@synthesize uploadFilesDeleteButton = _uploadFilesDeleteButton;
@synthesize uploadToAlbumComboBox = _uploadToAlbumComboBox;

@synthesize uploadProgressIndicator = _uploadProgressIndicator;
@synthesize albumLinkLabel = _albumLinkLabel;
@synthesize uploadButton = _uploadButton;
@synthesize uploadCancelButton = _uploadCancelButton;

@synthesize currentState = _currentState;

@synthesize onNeedAlbums = _onNeedAlbums;
@synthesize onNeedAcceptDrop = _onNeedAcceptDrop;
@synthesize onAddFileButtonClicked = _onAddFileButtonClicked;
@synthesize onDeleteFileButtonClicked = _onDeleteFileButtonClicked;
@synthesize onApplyButtonClicked = _onApplyButtonClicked;
@synthesize errorsUploadFilesLabel = _errorsUploadFilesLabel;
@synthesize progressStatisticLabel = _progressStatisticLabel;
@synthesize uploadFilesDataSource = _uploadFilesDataSource;
@synthesize errorsDataSource = _errorsDataSource;
@synthesize errorsTable = _errorsTable;
@synthesize tabWindow = _tabWindow;
@synthesize onWindowClose = _onWindowClose;
@synthesize uploadFilesClearListButton = _uploadFilesClearListButton;


- (id)init {
    self = [super initWithWindowNibName:@"UploadWindow"];
    if (self) {

        //HACK: http://borkware.com/quickies/single?id=276
        //The window controller nib doesn't get loaded until the window is manipulated.
        //This can cause confusion if you do any kind of setup before the window is shown.
        //If you call the window method, that will force the nib file to be loaded
        (void) [self window];

        self.currentState = kStateUnknown;

        self.uploadFilesDataSource = [UploadFilesDataSource dataSource];
        self.uploadFilesTable.dataSource = self.uploadFilesDataSource;

        self.errorsDataSource = [ErrorsDataSource dataSource];
        self.errorsTable.dataSource = self.errorsDataSource;

        self.errorsUploadFilesLabel.onMouseClicked = ^(NSEvent *event) {
            [self makeErrorsTabActive];
        };

        self.uploadToAlbumComboBox.dataSource = self;

        [self.uploadFilesAddButton setAction:@selector(onAddButtonClicked:)];
        [self.uploadFilesDeleteButton setAction:@selector(onDeleteButtonClicked:)];

        [self.uploadButton setAction:@selector(onApplyButtonClicked:)];
        [self.uploadCancelButton setAction:@selector(onCloseButtonClicked:)];

        [self.window registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
        [self.window setDelegate:self];
    }

    return self;
}

+ (id)controller {
    return [[[UploadWindowController alloc] init] autorelease];
}

- (void)dealloc {
    [_welcomeLabel release];
    [_uploadFilesTable release];
    [_uploadFilesAddButton release];
    [_uploadFilesDeleteButton release];
    [_uploadToAlbumComboBox release];

    [_uploadProgressIndicator release];
    [_albumLinkLabel release];
    [_uploadButton release];
    [_uploadCancelButton release];

    [_arrayAlbums release];

    [_onNeedAlbums release];
    [_onNeedAcceptDrop release];
    [_onAddFileButtonClicked release];
    [_onDeleteFileButtonClicked release];
    [_onApplyButtonClicked release];

    [_errorsUploadFilesLabel release];
    [_progressStatisticLabel release];
    [_uploadFilesDataSource release];
    [_errorsDataSource release];
    [_errorsTable release];
    [_tabWindow release];
    [_onWindowClose release];
    [_uploadFilesClearListButton release];
    [super dealloc];
}

- (IBAction)showWindow:(id)sender {
    [super showWindow:sender];
    [self.window makeKeyAndOrderFront:self];
    [self.window center];
    [NSApp activateIgnoringOtherApps:YES];
}

- (void)windowDidResignMain:(NSNotification *)notification {
    [[self window] setLevel:NSFloatingWindowLevel];
}

- (void)windowDidBecomeMain:(NSNotification *)notification {
    [[self window] setLevel:NSNormalWindowLevel];
}

- (void)windowWillClose :(NSNotification *)notification {
    [self prepareWindowBeforeClose];
}

- (NSArray *)selectedPaths {
    return self.uploadFilesDataSource.arrayFilesToUpload;
}

- (Album *)selectedAlbum {
    if (self.uploadToAlbumComboBox.indexOfSelectedItem >= 0 && self.uploadToAlbumComboBox.indexOfSelectedItem < self.arrayAlbums.count) {
        return [self.arrayAlbums objectAtIndex:(NSUInteger) self.uploadToAlbumComboBox.indexOfSelectedItem];
    } else {
        return nil;
    }
}

//-----------------------------------------------------------------------------------------
// Upload window handlers
//-----------------------------------------------------------------------------------------

- (IBAction)onAddButtonClicked:(id)sender {
    if (self.onAddFileButtonClicked) {
        self.onAddFileButtonClicked();

        [self.errorsDataSource.errors removeAllObjects];
        [self.errorsTable reloadData];
        [self.uploadFilesTable reloadData];
        [self changeApplyButtonStateBasedOnFormState];
    }
}

- (IBAction)onDeleteButtonClicked:(id)sender {
    if (self.onDeleteFileButtonClicked) {
        NSInteger selectedRowIndex = [self.uploadFilesTable selectedRow];
        self.onDeleteFileButtonClicked([NSNumber numberWithInteger:selectedRowIndex]);

        [self.uploadFilesTable reloadData];
        [self changeApplyButtonStateBasedOnFormState];
    }
}

- (IBAction)onApplyButtonClicked:(id)sender {
    if (self.onApplyButtonClicked) {
        self.onApplyButtonClicked();
    }
}

- (IBAction)onClearListButtonClicked:(id)sender {
    [self.uploadFilesDataSource.arrayFilesToUpload removeAllObjects];
    [self.uploadFilesTable reloadData];
}

- (void)makeUploadTabActive {
    [self.tabWindow selectTabViewItemAtIndex:0];
}

- (void)makeErrorsTabActive {
    [self.tabWindow selectTabViewItemAtIndex:1];
}

- (void)prepareWindowBeforeClose {
    [self makeUploadTabActive];
    self.onWindowClose();
}

- (IBAction)onCloseButtonClicked:(id)sender {
    [self prepareWindowBeforeClose];
    [self.window close];
}

//-----------------------------------------------------------------------------------------
// NSDraggingDestination implementation
//-----------------------------------------------------------------------------------------
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    return [self.uploadFilesTable isEnabled] ? NSDragOperationCopy : NSDragOperationNone;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    [self makeUploadTabActive];

    BOOL result = NO;
    if (self.onNeedAcceptDrop) {
        result = self.onNeedAcceptDrop(sender);

        [self.uploadFilesTable reloadData];
        [self changeApplyButtonStateBasedOnFormState];
    }

    return result;
}
//-----------------------------------------------------------------------------------------
// NSComboBoxDataSource implementation
//-----------------------------------------------------------------------------------------

- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox {
    return self.arrayAlbums.count;
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index {
    Album *album = [self.arrayAlbums objectAtIndex:(NSUInteger) index];
    return album.path;
}

//-----------------------------------------------------------------------------------------
// Helpers
//-----------------------------------------------------------------------------------------

- (void)showLinkToAlbum:(NSString *)urlToAlbum withUrlText:(NSString *)urlText {
    if (urlToAlbum) {
        [self.albumLinkLabel setAllowsEditingTextAttributes:YES];
        [self.albumLinkLabel setSelectable:YES];
        NSURL *url = [NSURL URLWithString:urlToAlbum];
        NSMutableAttributedString *attributedString = [[[NSMutableAttributedString alloc] init] autorelease];
        [attributedString appendAttributedString:[TextUtils hyperlinkFromString:urlText withURL:url]];

        [self.albumLinkLabel setAttributedStringValue:attributedString];
    } else {
        [self.albumLinkLabel setTitleWithMnemonic:@""];
    }
}

- (void)changeApplyButtonStateBasedOnFormState {
    [self.uploadButton setTitle:@"Upload"];
    BOOL hasFilesToUpload = self.uploadFilesTable.numberOfRows > 0;
    BOOL isAlbumSelected = self.selectedAlbum != nil;
    BOOL uploadButtonEnabledState = hasFilesToUpload && isAlbumSelected;
    [self.uploadButton setEnabled:uploadButtonEnabledState];
}

//-----------------------------------------------------------------------------------------
// State helpers
//-----------------------------------------------------------------------------------------

- (void)setStateInitializedWithAccount:(Account *)account {
    if (self.currentState == kStateInitialized) {
        return;
    }

    self.currentState = kStateInitialized;

    NSString *welcomeString = [NSString stringWithFormat:@"Logged in as %@", account.fullName];
    [self.welcomeLabel setTitleWithMnemonic:welcomeString];

    [self.uploadFilesDataSource.arrayFilesToUpload removeAllObjects];
    [self.uploadFilesTable reloadData];
    [self.uploadFilesTable setEnabled:YES];

    [self.errorsDataSource.errors removeAllObjects];
    [self.errorsTable reloadData];

    [self.uploadFilesAddButton setEnabled:YES];
    [self.uploadFilesDeleteButton setEnabled:YES];
    [self.uploadFilesClearListButton setEnabled:YES];

    [self.uploadToAlbumComboBox setEnabled:YES];

    self.arrayAlbums = self.onNeedAlbums();
    [self.uploadToAlbumComboBox reloadData];
    if ([self.arrayAlbums count] > 0) {
        [self.uploadToAlbumComboBox selectItemAtIndex:0];
    }

    [self.albumLinkLabel setHidden:YES];

    [self.errorsUploadFilesLabel setHidden:YES];

    [self.uploadProgressIndicator setHidden:YES];
    [self.albumLinkLabel setHidden:YES];
    [self.errorsUploadFilesLabel setHidden:YES];
    [self.progressStatisticLabel setHidden:YES];

    [self.uploadProgressIndicator startAnimation:self];
    [self changeApplyButtonStateBasedOnFormState];

    [self.uploadCancelButton setEnabled:YES];
    [self.uploadCancelButton setTitle:@"Close"];

    [self.errorsTable reloadData];
}

- (void)setStateUploadingWithFileProgressValue:(double)progressValueTotal totalProgressLabel:(NSString *)labelTotalProgress {
    self.currentState = kStateUploading;

    [self.uploadFilesTable setEnabled:NO];

    [self.uploadFilesAddButton setEnabled:NO];
    [self.uploadFilesDeleteButton setEnabled:NO];
    [self.uploadFilesClearListButton setEnabled:NO];

    [self.uploadToAlbumComboBox setEnabled:NO];

    [self.albumLinkLabel setHidden:YES];

    [self.uploadProgressIndicator setHidden:NO];
    [self.progressStatisticLabel setHidden:NO];

    [self.uploadProgressIndicator startAnimation:self];
    [self.uploadProgressIndicator setDoubleValue:progressValueTotal];

    [self.uploadButton setEnabled:NO];

    [self.uploadCancelButton setEnabled:YES];
    [self.uploadCancelButton setTitle:@"Cancel"];
    [self.progressStatisticLabel setTitleWithMnemonic:labelTotalProgress];
}

- (void)setStateUploadedWithException:(NSException *)exception {
    self.currentState = kStateUploaded;

    [self setStateUploadingWithFileProgressValue:100.0 totalProgressLabel:@"Error"];

    [self.albumLinkLabel setHidden:NO];
    [self.albumLinkLabel setTitleWithMnemonic:@"Upload error"];
    [self.uploadCancelButton setTitle:@"Close"];

    [self.uploadButton setEnabled:YES];
    [self.uploadButton setTitle:@"Start new upload"];

}

- (void)showErrorText:(NSString *)errorText {
    [self.errorsUploadFilesLabel setAllowsEditingTextAttributes:YES];
    [self.errorsUploadFilesLabel setSelectable:YES];

    //todo: make another solution: this hack to show link but really on click shows errors tab
    NSURL *url = [NSURL URLWithString:@"http://www.fotki.com"];

    NSMutableAttributedString *attributedString = [[[NSMutableAttributedString alloc] init] autorelease];
    [attributedString appendAttributedString:[TextUtils hyperlinkFromString:errorText withURL:url]];


    [self.errorsUploadFilesLabel setHidden:NO];
    [self.errorsUploadFilesLabel setAttributedStringValue:attributedString];
}

- (void)setStateUploadedWithLinkToAlbum:(NSString *)urlToAlbum arrayPathsFilesFailed:(NSMutableArray *)arrayPathsFilesFailed {
    self.currentState = kStateUploaded;
    [self setStateUploadingWithFileProgressValue:100.0 totalProgressLabel:@"Done"];

    [self.uploadProgressIndicator setHidden:YES];
    [self.progressStatisticLabel setHidden:YES];
    [self.albumLinkLabel setHidden:NO];
    [self.uploadCancelButton setTitle:@"Close"];
    [self.uploadButton setEnabled:YES];
    [self.uploadButton setTitle:@"Start new upload"];

    if (arrayPathsFilesFailed.count > 0) {
        [self showLinkToAlbum:urlToAlbum withUrlText:@"Click to open your album"];
        NSString *errorText = [NSString stringWithFormat:@"Failed to upload %d files", arrayPathsFilesFailed.count];
        [self showErrorText:errorText];
    } else {
        [self showLinkToAlbum:urlToAlbum withUrlText:@"Files successfully uploaded. Click to open your album"];
    }
}

- (void)addError:(NSString *)errorDescription forEvent:(NSString *)event {
    [self.errorsDataSource.errors addObject:[[[UploadError alloc] initWithEvent:event andErrorDescription:errorDescription] autorelease]];
    [self.errorsTable reloadData];
}
@end