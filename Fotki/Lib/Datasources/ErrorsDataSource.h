//
//  Created by dimakononov on 22.02.12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>


@interface ErrorsDataSource : NSObject<NSTableViewDataSource>
@property(nonatomic, retain) NSMutableArray *errors;

+ (ErrorsDataSource *)dataSource;
@end
