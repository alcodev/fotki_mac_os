//
//  Created by aistomin on 1/31/12.
//
//


#import "DialogUtils.h"
#import "FileSystemHelper.h"


@implementation DialogUtils {

}
+ (NSArray *)showOpenImageFileDialog {
    NSOpenPanel *openImageFilesDialog = [NSOpenPanel openPanel];
    [openImageFilesDialog setCanChooseFiles:YES];
    [openImageFilesDialog setAllowsMultipleSelection:YES];
    [openImageFilesDialog setAllowedFileTypes:[FileSystemHelper supportedImageFilesTypes]];

    if ([openImageFilesDialog runModal] == NSOKButton) {
        NSArray *files = [openImageFilesDialog URLs];
        return files;
    }
    return [[[NSMutableArray alloc] init] autorelease];
}
@end