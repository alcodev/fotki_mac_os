//
//  Created by aistomin on 1/16/12.
//
//


#import "DirectoryUtils.h"
#import "Consts.h"


@implementation DirectoryUtils {

}

+ (NSString *)getFotkiPath {
    NSString *fotkiPath = [NSHomeDirectory() stringByAppendingString:FOTKI_FOLDER];
    LOG(@"Fotki path: %@", fotkiPath);
    return fotkiPath;

}
@end