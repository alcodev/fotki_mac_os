//
//  Created by vavaka on 2/18/12.



#import "UploadWindowController.h"
#import "TextUtils.h"
#import "FileSystemHelper.h"
#import "Album.h"
#import "Async2SyncLock.h"
#import "NSThread+Helper.h"
#import "CRCUtils.h"
#import "DateUtils.h"
#import "Error.h"
#import "ApiException.h"
#import "FotkiServiceFacade.h"
#import "AccountInfo.h"
#import "Callbacks.h"

typedef enum {
    kStateUnknown, kStateInitialized, kStateUploading, kStateUploaded
} UploadWindowState;

@interface UploadWindowController()

@property(nonatomic, assign) UploadWindowState currentState;
@property(nonatomic, retain) FotkiServiceFacade *fotkiServiceFacade;

- (void)uploadSelectedPhotos:(id)sender album:(Album *)album;

- (void)changeApplyButtonStateBasedOnFormState;

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
@synthesize fotkiServiceFacade = _fotkiServiceFacade;

@synthesize onNeedAlbums = _onNeedAlbums;
@synthesize onNeedAcceptDrop = _onNeedAcceptDrop;
@synthesize onAddFileButtonClicked = _onAddFileButtonClicked;
@synthesize onDeleteFileButtonClicked = _onDeleteFileButtonClicked;
@synthesize onNeedUpload = _onNeedUpload;


- (id)init {
    self = [super initWithWindowNibName:@"UploadWindow"];
    if (self) {
        self.arrayFilesToUpload = [NSMutableArray array];
        self.fotkiServiceFacade = [[[FotkiServiceFacade alloc] init] autorelease];

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
    [_fotkiServiceFacade release];

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

    if (self.onNeedAcceptDrop) {
        self.onNeedAcceptDrop(info);

        [self.uploadFilesTable reloadData];
        [self changeApplyButtonStateBasedOnFormState];
    }
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

- (void)showUploadedAlbumLink:(NSString *)urlString failedFilesCount:(int)failedFilesCount {
    [self.albumLinkLabel setAllowsEditingTextAttributes:YES];
    [self.albumLinkLabel setSelectable:YES];
    [self.albumLinkLabel setHidden:NO];
    [self.uploadFilesAddButton setEnabled:YES];
    [self.uploadFilesDeleteButton setEnabled:YES];
    [self.uploadFilesTable setEnabled:YES];
    [self.uploadButton setEnabled:YES];
    //self.dragStatusView.isEnable = YES;

    if (failedFilesCount > 0) {
        //TODO: decide if we need self.uploadFilesLabel
        //[self.uploadFilesLabel setTextColor:[NSColor redColor]];
        //[self.uploadFilesLabel setStringValue:[NSString stringWithFormat:@"Error: %d files of %d was not uploaded", failedFilesCount, [_filesToUpload count]]];
    } else {
        NSURL *url = [NSURL URLWithString:urlString];
        NSMutableAttributedString *attributedString = [[[NSMutableAttributedString alloc] init] autorelease];
        [attributedString appendAttributedString:[TextUtils hyperlinkFromString:@"Files successfully uploaded. Click to open your album." withURL:url]];

        [self.albumLinkLabel setAttributedStringValue:attributedString];
    }


}


- (void)uploadSelectedPhotos:(id)sender album:(Album *)album {
    long long sizeFilesTotal = [FileSystemHelper sizeForFilesAtPaths:self.arrayFilesToUpload];
    long long sizeFilesUploaded = 0;
    int countFilesFailed = 0;

    NSDate *beginUploadDate = [NSDate date];

    for(NSInteger indexFilePath = 0; indexFilePath < self.arrayFilesToUpload.count; indexFilePath++) {
        BOOL isFileUploaded = NO;

        NSString *pathFile = [self.arrayFilesToUpload objectAtIndex:(NSUInteger) indexFilePath];
        NSString *crcFile = [CRCUtils crcFromDataAsString:[FileSystemHelper getFileData:pathFile]];

        if ([self.fotkiServiceFacade checkCrc32:crcFile inAlbum:album]){
            LOG(@"File %@ exist on server...", pathFile);
            sizeFilesUploaded += [FileSystemHelper sizeForFileAtPath:pathFile];
            isFileUploaded = YES;
        } else {
            LOG(@"File %@ not exist on server. Try to upload....", pathFile);

            int countAttempts = 0;
            __block long long sizeFileCurrentUploaded = 0;
            while (countAttempts < 1 && !isFileUploaded) {
                @try {
                    [self.fotkiServiceFacade uploadImageAtPath:pathFile crc32:crcFile toAlbum:album uploadProgressBlock:^(NSInteger bytesWrite, NSInteger totalBytesWrite, NSInteger totalBytesExpectedToWrite) {
                        sizeFileCurrentUploaded = totalBytesWrite;

                        NSDate *currentUploadDate = [NSDate date];
                        NSInteger timeInSecondsFromUploadBeginning = [DateUtils dateDiffInSecondsBetweenDate1:beginUploadDate andDate2:currentUploadDate];
                        LOG(@"Time in seconds from upload beginning: %ld", timeInSecondsFromUploadBeginning);
                        LOG(@"Current file's written bytes: %d", totalBytesWrite);

                        long long uploadedBytes = sizeFilesUploaded + totalBytesWrite;

                        float currentUploadingSpeed = timeInSecondsFromUploadBeginning > 0 ? ((float) uploadedBytes / (float) timeInSecondsFromUploadBeginning) : 0;
                        currentUploadingSpeed = currentUploadingSpeed / 1024;

                        long long leftBytes = sizeFilesTotal - uploadedBytes;
                        long long leftKBytes = leftBytes / 1024;
                        float leftTime = currentUploadingSpeed > 0 ? ((float) leftKBytes / currentUploadingSpeed) : 0;
                        LOG(@"Left time: %f from leftKBytes: %f and currentUploading speed: %f", leftTime, leftKBytes, currentUploadingSpeed);

                        [NSThread doInMainThread:^() {
                            double valueProgressFile = totalBytesWrite * 100 / totalBytesExpectedToWrite;
                            NSString *labelProgressFile = [NSString stringWithFormat:@"Uploading file %d of %d at %dKB/sec.", indexFilePath + 1, self.arrayFilesToUpload.count, (int) currentUploadingSpeed];
                            double valueProgressTotal = uploadedBytes * 100 / sizeFilesTotal;
                            NSString *labelProgressTotal = [DateUtils formatLeftTime:leftTime];

                            [self setStateUploadingWithFileProgressValue:valueProgressFile fileProgressLabel:labelProgressFile totalProgressValue:valueProgressTotal totalProgressLabel:labelProgressTotal];
                        } waitUntilDone:YES];

                        LOG(@"uploadedFilesSize: %d", totalBytesWrite);
                    }];

                    LOG(@"Image '%@' was successfully uploaded", pathFile);
                    sizeFilesUploaded += sizeFileCurrentUploaded;
                    LOG(@"Total Uploaded: %d", sizeFilesUploaded);
                    LOG(@"Total Calculated: %d", sizeFilesTotal);
                    isFileUploaded = YES;
                } @catch (ApiException *ex) {
                    LOG(@"Error uploading image '%@', reason: %@", pathFile, ex.description);
                    countAttempts++;
                    isFileUploaded = NO;
                }
            }

            countAttempts++;
        }

        if (!isFileUploaded) {
            countFilesFailed++;
        }
    }

    @try {
        NSString *albumUrl = [self.fotkiServiceFacade getAlbumUrl:album.id];
        [self showUploadedAlbumLink:albumUrl failedFilesCount:countFilesFailed];
    } @catch(ApiException *ex) {
        LOG(@"Error getting url for album: %@", album.id);
    }

    [NSThread doInMainThread:^() {
        [self setStateUploaded];
    } waitUntilDone:YES];
}

//-----------------------------------------------------------------------------------------
// UI helpers
//-----------------------------------------------------------------------------------------

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

- (void)setStateInitializedWithAccountInfo:(AccountInfo *)accountInfo {
    if (self.currentState == kStateInitialized) {
        return;
    }

    self.currentState = kStateInitialized;

    NSString *welcomeString = [NSString stringWithFormat:@"Logged in as %@", accountInfo.name];
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

- (void)setStateUploaded {
    if (self.currentState == kStateUploaded) {
        return;
    }

    self.currentState = kStateUploaded;

    [self setStateUploading];

    [self.albumLinkLabel setHidden:YES];
}

@end