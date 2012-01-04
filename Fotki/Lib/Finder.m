//
//  Created by vavaka on 1/4/12.



#import "Finder.h"


@implementation Finder

+ (void)addPathToFavourites:(NSString *)path {
    CFURLRef url = (CFURLRef) [NSURL fileURLWithPath:path];

    // Create a reference to the shared file list.
    LSSharedFileListRef favoriteItems = LSSharedFileListCreate(NULL, kLSSharedFileListFavoriteItems, NULL);
    if (favoriteItems) {
        //Insert an item to the list.
        LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(favoriteItems, kLSSharedFileListItemLast, NULL, NULL, url, NULL, NULL);
        if (item) {
            CFRelease(item);
        }
    }

    CFRelease(favoriteItems);
}

@end