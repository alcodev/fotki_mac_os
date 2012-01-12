//
//  Created by vavaka on 1/5/12.



#import <Foundation/Foundation.h>


@interface Async2SyncLock : NSObject {
    NSConditionLock *_lock;
}

- (void)asyncFinished;

- (void)waitUtilAsyncFinished;

@end