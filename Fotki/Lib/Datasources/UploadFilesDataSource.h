//
//  Created by dimakononov on 22.02.12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>


@interface UploadFilesDataSource : NSObject<NSTableViewDataSource>
@property(nonatomic, retain) NSMutableArray *arrayFilesToUpload;

+ (UploadFilesDataSource *)dataSource;
@end