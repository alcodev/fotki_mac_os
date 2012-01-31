//
//  Created by aistomin on 1/31/12.
//
//


#import "DialogUtils.h"


@implementation DialogUtils {

}
+ (NSArray *)showOpenFileDialog {
    NSOpenPanel *openDlg = [NSOpenPanel openPanel];
    [openDlg setCanChooseFiles:YES];
    [openDlg setAllowsMultipleSelection:YES];
    [openDlg setAllowedFileTypes:[NSImage imageFileTypes]];

    if ([openDlg runModal] == NSOKButton) {
        NSArray *files = [openDlg URLs];
        return files;
    }
    return [[[NSMutableArray alloc] init] autorelease];
}
@end