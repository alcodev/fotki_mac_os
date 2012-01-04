//
//  Created by vavaka on 12/23/11.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>

@interface NSThread (Helper)

+ (void)doInNewThread:(Callback)callback;

+ (void)doInMainThread:(Callback)callback waitUntilDone:(BOOL)waitUntilDone;

@end