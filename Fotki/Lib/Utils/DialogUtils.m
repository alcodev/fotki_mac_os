//
//  Created by aistomin on 1/31/12.
//
//


#import "DialogUtils.h"


@implementation DialogUtils {

}
+ (NSArray *)showOpenImageFileDialog {
    NSOpenPanel *openDlg = [NSOpenPanel openPanel];
    [openDlg setCanChooseFiles:YES];
    [openDlg setAllowsMultipleSelection:YES];
    NSMutableArray *imageTypes = [[NSMutableArray alloc] init];
    [imageTypes addObject:@"public.image"];
    [openDlg setAllowedFileTypes:imageTypes];

    if ([openDlg runModal] == NSOKButton) {
        NSArray *files = [openDlg URLs];
        return files;
    }
    return [[[NSMutableArray alloc] init] autorelease];
}
@end