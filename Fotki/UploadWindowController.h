//
//  Created by vavaka on 2/18/12.



#import <Foundation/Foundation.h>
#import "Callbacks.h"

@class Account;
@class Album;
@class UploadFilesDataSource;
@class ErrorsDataSource;

@interface UploadWindowController : NSWindowController<NSComboBoxDataSource, NSWindowDelegate, NSDraggingDestination>

@property(nonatomic, retain) NSArray *arrayAlbums;

@property(nonatomic, retain) IBOutlet NSTextField *welcomeLabel;
@property(nonatomic, retain) IBOutlet NSTableView *uploadFilesTable;
@property(nonatomic, retain) UploadFilesDataSource *uploadFilesDataSource;
@property(nonatomic, retain) IBOutlet NSButton *uploadFilesAddButton;
@property(nonatomic, retain) IBOutlet NSButton *uploadFilesDeleteButton;
@property(nonatomic, retain) IBOutlet NSButton *uploadFilesClearListButton;
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
@property(nonatomic, copy) Callback onWindowClose;

@property(nonatomic, retain) IBOutlet NSTableView *errorsTable;
@property(nonatomic, retain) ErrorsDataSource *errorsDataSource;

@property(nonatomic, retain) IBOutlet NSTabView *tabWindow;

+ (id)controller;

- (void)setStateInitializedWithAccount:(Account *)account;

- (IBAction)onClearListButtonClicked:(id)sender;

- (void)makeUploadTabActive;

- (void)changeApplyButtonStateBasedOnFormState;

- (void)setStateUploadingWithFileProgressValue:(double)progressValueTotal totalProgressLabel:(NSString *)labelTotalProgress;

- (void)setStateUploadedWithException:(NSException *)exception;

- (void)setStateUploadedWithLinkToAlbum:(NSString *)urlToAlbum arrayPathsFilesFailed:(NSMutableArray *)arrayPathsFilesFailed;

- (void)addError:(NSString *)errorDescription forEvent:(NSString *)event;
@end