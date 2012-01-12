//
//  Created by vavaka on 1/5/12.



#import "Async2SyncLock.h"

enum {
    ASYNC_NOT_FINISHED,
    ASYNC_FINISHED
};


@implementation Async2SyncLock

- (id)init {
    self = [super init];
    if (self) {
        _lock = [[NSConditionLock alloc] initWithCondition:ASYNC_NOT_FINISHED];
    }

    return self;
}

- (void)dealloc {
    [_lock release];
    [super dealloc];
}


- (void)asyncFinished {
    [_lock lock];
    [_lock unlockWithCondition:ASYNC_FINISHED];
}

- (void)waitUtilAsyncFinished {
    [_lock lockWhenCondition:ASYNC_FINISHED];
    [_lock unlock];
}

@end