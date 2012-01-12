//
//  Created by vavaka on 12/23/11.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>

@class Async2SyncLock;

typedef void (^SyncCallback)(Async2SyncLock *lock);

@interface NSThread (Helper)

+ (void)doInNewThread:(Callback)callback;

+ (void)doInMainThread:(Callback)callback waitUntilDone:(BOOL)waitUntilDone;

+ (void)runAsyncBlockSynchronously:(SyncCallback)apiCallback;

@end