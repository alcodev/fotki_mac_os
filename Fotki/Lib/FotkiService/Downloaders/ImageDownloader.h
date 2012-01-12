//
//  Created by aistomin on 1/11/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>


@interface ImageDownloader : NSObject
+ (void)downloadImageFromUrl:(NSString *)imageUrl toFile:(NSString *)file;
@end