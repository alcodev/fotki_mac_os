//
//  Created by vavaka on 2/18/12.



#import <Foundation/Foundation.h>
#import "Callbacks.h"

@class Account;
@class Album;

@interface UploadWindowController : NSWindowController<NSTableViewDataSource, NSComboBoxDataSource, NSWindowDelegate>

@property(nonatomic, retain) NSMutableArray *arrayFilesToUpload;
@property(nonatomic, retain) NSArray *arrayAlbums;

@property(nonatomic, retain) IBOutlet NSTextField *welcomeLabel;
@property(nonatomic, retain) IBOutlet NSTableView *uploadFilesTable;
@property(nonatomic, retain) IBOutlet NSButton *uploadFilesAddButton;
@property(nonatomic, retain) IBOutlet NSButton *uploadFilesDeleteButton;
@property(nonatomic, retain) IBOutlet NSComboBox *uploadToAlbumComboBox;
@property(nonatomic, retain) IBOutlet NSTextField *currentFileProgressLabel;
@property(nonatomic, retain) IBOutlet NSProgressIndicator *currentFileProgressIndicator;
@property(nonatomic, retain) IBOutlet NSTextField *totalProgressLabel;
@property(nonatomic, retain) IBOutlet NSProgressIndicator *totalFileProgressIndicator;
@property(nonatomic, retain) IBOutlet NSTextField *albumLinkLabel;
@property(nonatomic, retain) IBOutlet NSTextField *countErrorsUploadFilesLabel;
@property(nonatomic, retain) IBOutlet NSButton *uploadButton;
@property(nonatomic, retain) IBOutlet NSButton *uploadCancelButton;

@property(nonatomic, readonly) NSArray *selectedPaths;
@property(nonatomic, readonly) Album *selectedAlbum;

@property(nonatomic, copy) ReturnableCallback onNeedAlbums;
@property(nonatomic, copy) AcceptDropCallback onNeedAcceptDrop;
@property(nonatomic, copy) Callback onAddFileButtonClicked;
@property(nonatomic, copy) ParametrizedCallback onDeleteFileButtonClicked;
@property(nonatomic, copy) Callback onNeedUpload;

+ (id)controller;

- (void)setStateInitializedWithAccount:(Account *)account;

- (void)setStateUploadingWithFileProgressValue:(double)progressValueFile fileProgressLabel:(NSString *)labelFileProgress totalProgressValue:(double)progressValueTotal totalProgressLabel:(NSString *)labelTotalProgress;

- (void)changeApplyButtonStateBasedOnFormState;

- (void)setStateUploadedWithException:(NSException *)exception;

- (void)setStateUploadedWithLinkToAlbum:(NSString *)urlToAlbum arrayPathsFilesFailed:(NSMutableArray *)arrayPathsFilesFailed;
@end