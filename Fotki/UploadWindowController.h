//
//  Created by vavaka on 2/18/12.



#import <Foundation/Foundation.h>
#import "Callbacks.h"

@class Account;
@class Album;
@class UploadFilesDataSource;

@interface UploadWindowController : NSWindowController<NSComboBoxDataSource, NSWindowDelegate>

@property(nonatomic, retain) NSArray *arrayAlbums;

@property(nonatomic, retain) IBOutlet NSTextField *welcomeLabel;
@property(nonatomic, retain) IBOutlet NSTableView *uploadFilesTable;
@property(nonatomic, retain) IBOutlet NSButton *uploadFilesAddButton;
@property(nonatomic, retain) IBOutlet NSButton *uploadFilesDeleteButton;
@property(nonatomic, retain) IBOutlet NSComboBox *uploadToAlbumComboBox;
@property(nonatomic, retain) IBOutlet NSButton *uploadButton;
@property(nonatomic, retain) IBOutlet NSButton *uploadCancelButton;

@property(nonatomic, retain) IBOutlet NSProgressIndicator *uploadProgressIndicator;
@property(nonatomic, retain) IBOutlet NSTextField *errorsUploadFilesLabel;
@property(nonatomic, retain) IBOutlet NSTextField *progressStatisticLabel;
@property(nonatomic, retain) IBOutlet NSTextField *albumLinkLabel;

@property(nonatomic, readonly) NSArray *selectedPaths;
@property(nonatomic, readonly) Album *selectedAlbum;

@property(nonatomic, copy) ReturnableCallback onNeedAlbums;
@property(nonatomic, copy) AcceptDropCallback onNeedAcceptDrop;
@property(nonatomic, copy) Callback onAddFileButtonClicked;
@property(nonatomic, copy) ParametrizedCallback onDeleteFileButtonClicked;
@property(nonatomic, copy) Callback onNeedUpload;

@property(nonatomic, retain)UploadFilesDataSource *uploadFilesDataSource;

+ (id)controller;

- (void)setStateInitializedWithAccount:(Account *)account;

- (void)changeApplyButtonStateBasedOnFormState;

- (void)setStateUploadingWithFileProgressValue:(double)progressValueTotal totalProgressLabel:(NSString *)labelTotalProgress;

- (void)setStateUploadedWithException:(NSException *)exception;

- (void)setStateUploadedWithLinkToAlbum:(NSString *)urlToAlbum arrayPathsFilesFailed:(NSMutableArray *)arrayPathsFilesFailed;
@end