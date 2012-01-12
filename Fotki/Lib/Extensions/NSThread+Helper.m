//
//  Created by vavaka on 12/23/11.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "NSThread+Helper.h"
#import "Async2SyncLock.h"


@interface NSThread ()
+ (void)executeCallback:(Callback)callback;

@end

@implementation NSThread (Helper)

+ (void)executeCallback:(Callback)callback {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    {
        callback();
    }
    [pool release];

    [callback release];
}

+ (void)doInNewThread:(Callback)callback {
    [NSThread detachNewThreadSelector:@selector(executeCallback:) toTarget:[NSThread class] withObject:[callback copy]];
}

+ (void)doInMainThread:(Callback)callback waitUntilDone:(BOOL)waitUntilDone {
    [NSThread performSelectorOnMainThread:@selector(executeCallback:) withObject:[callback copy] waitUntilDone:waitUntilDone];
}

+ (void)runAsyncBlockSynchronously:(SyncCallback)apiCallback {
    Async2SyncLock *lock = [[Async2SyncLock alloc] init];
    @try {
        apiCallback(lock);
        [lock waitUtilAsyncFinished];
    } @finally {
        [lock release];
    }
}

@end