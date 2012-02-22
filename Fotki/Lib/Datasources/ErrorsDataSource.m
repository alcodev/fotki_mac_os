//
//  Created by dimakononov on 22.02.12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "ErrorsDataSource.h"
#import "UploadError.h"


@implementation ErrorsDataSource {

}
@synthesize errors = _errors;


-(ErrorsDataSource *)init{
    self = [super init];
    if (self){
        self.errors = [[[NSMutableArray alloc] init] autorelease];
    }
    return self;
}

- (void)dealloc {
    [_errors release];
    [super dealloc];
}

+ (ErrorsDataSource *)dataSource {
    return [[[ErrorsDataSource alloc] init] autorelease];

}

- (int)numberOfRowsInTableView:(NSTableView *)tableView {
    return [self.errors count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
    UploadError *error = [self.errors objectAtIndex:rowIndex];

    if ([@"eventColumn" isEqualToString:aTableColumn.identifier]){
        return error.event;
    }
    if ([@"errorDescriptionColumn" isEqualToString:aTableColumn.identifier]){
        return error.errorDescription;
    }
    return nil;
}

@end