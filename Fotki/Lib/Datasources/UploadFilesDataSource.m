//
//  Created by dimakononov on 22.02.12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "UploadFilesDataSource.h"


@implementation UploadFilesDataSource {

}
@synthesize arrayFilesToUpload = _arrayFilesToUpload;

-(UploadFilesDataSource *)init{
   self = [super init];
    if (self){
        self.arrayFilesToUpload = [[[NSMutableArray alloc] init] autorelease];
    }
    return self;
}

+ (UploadFilesDataSource *)dataSource {
 return [[[UploadFilesDataSource alloc] init] autorelease];

}

- (int)numberOfRowsInTableView:(NSTableView *)tableView {
    return [self.arrayFilesToUpload count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
    NSString *valueToDisplay = [self.arrayFilesToUpload objectAtIndex:(NSUInteger) rowIndex];
    return valueToDisplay;
}

- (void)dealloc {
    [_arrayFilesToUpload release];
    [super dealloc];
}
@end