//
//  Created by vavaka on 2/18/12.



#import "UploadWindowController.h"
#import "TextUtils.h"
#import "Album.h"
#import "Account.h"

typedef enum {
    kStateUnknown, kStateInitialized, kStateUploading, kStateUploaded
} UploadWindowState;

@interface UploadWindowController()

@property(nonatomic, assign) UploadWindowState currentState;

- (void)changeApplyButtonStateBasedOnFormState;

- (void)showLinkToAlbum:(NSString *)urlToAlbum;

- (void)setProgressBarsHidden:(BOOL)isHidden;

@end


@implementation UploadWindowController

@synthesize arrayFilesToUpload = _arrayFilesToUpload;
@synthesize arrayAlbums = _arrayAlbums;

@synthesize welcomeLabel = _welcomeLabel;
@synthesize uploadFilesTable = _uploadFilesTable;
@synthesize uploadFilesAddButton = _uploadFilesAddButton;
@synthesize uploadFilesDeleteButton = _uploadFilesDeleteButton;
@synthesize uploadToAlbumComboBox = _uploadToAlbumComboBox;
@synthesize currentFileProgressLabel = _currentFileProgressLabel;
@synthesize currentFileProgressIndicator = _currentFileProgressIndicator;
@synthesize totalProgressLabel = _totalProgressLabel;
@synthesize totalFileProgressIndicator = _totalFileProgressIndicator;
@synthesize albumLinkLabel = _albumLinkLabel;
@synthesize uploadButton = _uploadButton;
@synthesize uploadCancelButton = _uploadCancelButton;

@synthesize currentState = _currentState;

@synthesize onNeedAlbums = _onNeedAlbums;
@synthesize onNeedAcceptDrop = _onNeedAcceptDrop;
@synthesize onAddFileButtonClicked = _onAddFileButtonClicked;
@synthesize onDeleteFileButtonClicked = _onDeleteFileButtonClicked;
@synthesize onNeedUpload = _onNeedUpload;


- (id)init {
    self = [super initWithWindowNibName:@"UploadWindow"];
    if (self) {
        self.arrayFilesToUpload = [NSMutableArray array];

        //HACK: http://borkware.com/quickies/single?id=276
        //The window controller nib doesn't get loaded until the window is manipulated.
        //This can cause confusion if you do any kind of setup before the window is shown.
        //If you call the window method, that will force the nib file to be loaded
        (void) [self window];

        self.currentState = kStateUnknown;

        self.uploadFilesTable.dataSource = self;
        self.uploadToAlbumComboBox.dataSource = self;

        [self.uploadFilesAddButton setAction:@selector(onAddButtonClicked:)];
        [self.uploadFilesDeleteButton setAction:@selector(onDeleteButtonClicked:)];

        [self.uploadButton setAction:@selector(onApplyButtonClicked:)];
        [self.uploadCancelButton setAction:@selector(onCloseButtonClicked:)];

        //NSImage *image = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kAlertNoteIcon)];
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
    [_currentFileProgressLabel release];
    [_currentFileProgressIndicator release];
    [_totalProgressLabel release];
    [_totalFileProgressIndicator release];
    [_albumLinkLabel release];
    [_uploadButton release];
    [_uploadCancelButton release];

    [_arrayFilesToUpload release];
    [_arrayAlbums release];

    [_onNeedAlbums release];
    [_onNeedAcceptDrop release];
    [_onAddFileButtonClicked release];
    [_onDeleteFileButtonClicked release];
    [_onNeedUpload release];

    [super dealloc];
}

- (IBAction)showWindow:(id)sender {
    [super showWindow:sender];

    [self.window makeKeyAndOrderFront:self];
    [self.window center];
    [NSApp activateIgnoringOtherApps:YES];
}

- (NSArray *)selectedPaths {
    return self.arrayFilesToUpload;
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
    if(self.onAddFileButtonClicked) {
        self.onAddFileButtonClicked();

        [self.uploadFilesTable reloadData];
        [self changeApplyButtonStateBasedOnFormState];
    }
}

- (IBAction)onDeleteButtonClicked:(id)sender {
    if(self.onDeleteFileButtonClicked) {
        NSInteger selectedRowIndex = [self.uploadFilesTable selectedRow];
        self.onDeleteFileButtonClicked([NSNumber numberWithInteger:selectedRowIndex]);

        [self.uploadFilesTable reloadData];
        [self changeApplyButtonStateBasedOnFormState];
    }
}

- (IBAction)onApplyButtonClicked:(id)sender {
    if (self.onNeedUpload) {
        self.onNeedUpload();
    }
}

- (IBAction)onCloseButtonClicked:(id)sender {
    [self.arrayFilesToUpload removeAllObjects];
    [self.uploadFilesTable reloadData];
    [self.window close];
}

//-----------------------------------------------------------------------------------------
// NSTableViewDataSource implementation
//-----------------------------------------------------------------------------------------

- (int)numberOfRowsInTableView:(NSTableView *)tableView {
    return [self.arrayFilesToUpload count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
    NSString *valueToDisplay = [self.arrayFilesToUpload objectAtIndex:(NSUInteger) rowIndex];
    return valueToDisplay;
}

//-----------------------------------------------------------------------------------------
// NSTableView drag-n-drop implementation
//-----------------------------------------------------------------------------------------

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation {
    if (![tableView isEnabled]) {
        return NO;
    }

    BOOL result = NO;
    if (self.onNeedAcceptDrop) {
        result = self.onNeedAcceptDrop(info);

        [self.uploadFilesTable reloadData];
        [self changeApplyButtonStateBasedOnFormState];
    }

    return result;
}

- (NSDragOperation)tableView:(NSTableView *)pTableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)op {
    // Add code here to validate the drop
    //NSLog(@"validate Drop");
    return NSDragOperationEvery;
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

- (void)showLinkToAlbum:(NSString *)urlToAlbum {
    NSURL *url = [NSURL URLWithString:urlToAlbum];
    NSMutableAttributedString *attributedString = [[[NSMutableAttributedString alloc] init] autorelease];
    [attributedString appendAttributedString:[TextUtils hyperlinkFromString:@"Files successfully uploaded. Click to open your album." withURL:url]];

    [self.albumLinkLabel setAttributedStringValue:attributedString];
}

- (void)setProgressBarsHidden:(BOOL)isHidden {
    [self.totalFileProgressIndicator setHidden:isHidden];
    [self.totalProgressLabel setHidden:isHidden];
    [self.currentFileProgressIndicator setHidden:isHidden];
    [self.currentFileProgressLabel setHidden:isHidden];
}

- (void)changeApplyButtonStateBasedOnFormState {
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

    [self.arrayFilesToUpload removeAllObjects];
    [self.uploadFilesTable reloadData];
    [self.uploadFilesTable setEnabled:YES];
    [self.uploadFilesTable registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
    [self.uploadFilesTable setDraggingSourceOperationMask:NSDragOperationCopy forLocal:NO];

    [self.uploadFilesAddButton setEnabled:YES];
    [self.uploadFilesDeleteButton setEnabled:YES];

    [self.uploadToAlbumComboBox setEnabled:YES];

    self.arrayAlbums = self.onNeedAlbums();
    [self.uploadToAlbumComboBox reloadData];
    if ([self.arrayAlbums count] > 0) {
        [self.uploadToAlbumComboBox selectItemAtIndex:0];
    }

    [self.albumLinkLabel setHidden:YES];

    [self setProgressBarsHidden:YES];

    [self changeApplyButtonStateBasedOnFormState];

    [self.uploadCancelButton setEnabled:YES];
    [self.uploadCancelButton setTitle:@"Close"];
}

- (void)setStateUploadingWithFileProgressValue:(double)progressValueFile fileProgressLabel:(NSString *)labelFileProgress totalProgressValue:(double)progressValueTotal totalProgressLabel:(NSString *)labelTotalProgress {
    self.currentState = kStateUploading;

    [self.uploadFilesTable setEnabled:NO];

    [self.uploadFilesAddButton setEnabled:NO];
    [self.uploadFilesDeleteButton setEnabled:NO];

    [self.uploadToAlbumComboBox setEnabled:NO];

    [self.albumLinkLabel setHidden:YES];

    [self setProgressBarsHidden:NO];

    [self.currentFileProgressIndicator startAnimation:self];
    [self.currentFileProgressLabel setTitleWithMnemonic:labelFileProgress];
    [self.currentFileProgressIndicator setDoubleValue:progressValueFile];

    [self.totalFileProgressIndicator startAnimation:self];
    [self.totalFileProgressIndicator setDoubleValue:progressValueTotal];
    [self.totalProgressLabel setTitleWithMnemonic:labelTotalProgress];

    [self.uploadButton setEnabled:NO];

    [self.uploadCancelButton setEnabled:YES];
    [self.uploadCancelButton setTitle:@"Cancel"];
}

- (void)setStateUploadedWithLinkToAlbum:(NSString *)urlToAlbum {
    self.currentState = kStateUploaded;

    [self setStateUploadingWithFileProgressValue:100.0 fileProgressLabel:@"Done" totalProgressValue:100.0 totalProgressLabel:@"Done"];

    [self.albumLinkLabel setHidden:NO];
    [self showLinkToAlbum:urlToAlbum];
}

@end