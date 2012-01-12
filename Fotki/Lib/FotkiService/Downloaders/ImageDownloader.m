//
//  Created by aistomin on 1/11/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "ImageDownloader.h"


@implementation ImageDownloader {

}

+ (void)downloadImageFromUrl:(NSString *)imageUrl toFile:(NSString *)file {
    NSURL *url = [NSURL URLWithString:imageUrl];
    NSData *data = [[[NSData alloc] initWithContentsOfURL:url] autorelease];
    [data writeToFile:file atomically:NO];
}
@end