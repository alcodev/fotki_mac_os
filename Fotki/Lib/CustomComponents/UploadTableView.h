//
//  Created by dimakononov on 24.02.12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>


@interface UploadTableView :  NSTableView

@property(nonatomic, retain) NSMutableArray *successUploadRows;
@property(nonatomic, retain) NSMutableArray *errorUploadRows;
@property(nonatomic, retain) NSMutableArray *existFilesRows;

@end