//
//  Created by vavaka on 1/3/12.



#import "FileSystemMonitor.h"

static void fsevents_callback(ConstFSEventStreamRef streamRef, void *userData, size_t numEvents, void *eventPaths, const FSEventStreamEventFlags eventFlags[], const FSEventStreamEventId eventIds[]) {
    FileSystemMonitor *fileSystemMonitor = (FileSystemMonitor *) userData;
    size_t i;
    for (i = 0; i < numEvents; i++) {
        if (eventIds[i] <= [fileSystemMonitor.lastEventId unsignedLongLongValue]) {
            continue;
        }

        LOG(@"Handling fs event %lu", eventIds[i]);
        [fileSystemMonitor handleFileSystemEventWithId:eventIds[i] path:[(NSArray *) eventPaths objectAtIndex:i]];
    }
}

@implementation FileSystemMonitor

@synthesize lastEventId = _lastEventId;
@synthesize pathModificationDates = _pathModificationDates;

- (id)initWithPaths:(NSArray *)paths lastEventId:(NSNumber *)lastEventId pathModificationDate:(NSMutableDictionary *)pathModificationDates {
    self = [super init];
    if (self != nil) {
        _fm = [NSFileManager defaultManager];
        _files = [NSMutableArray new];
        _latency = 3.0;

        _paths = [paths retain];
        _lastEventId = [lastEventId retain];
        _pathModificationDates = [pathModificationDates retain];
    }

    return self;
}

- (void)dealloc {
    [_files release];

    [_paths release];
    [_pathModificationDates release];
    [_lastEventId release];

    Block_release(_syncNeededCallback);
    Block_release(_addCallback);
    Block_release(_updateCallback);
    Block_release(_deleteCallback);

    [super dealloc];
}

- (void)startAndDoOnSyncNeeded:(FileSystemSyncCallback)syncNeededCallback
                 doOnFileAdded:(FileSystemEventCallback)addCallback
                 doOnFileUpdated:(FileSystemEventCallback)updateCallback
                 doOnFileDeleted:(FileSystemEventCallback)deleteCallback {

    LOG(@"Subscribing to events from %d", [_lastEventId unsignedLongLongValue]);

    _syncNeededCallback = Block_copy(syncNeededCallback);
    _addCallback = Block_copy(addCallback);
    _updateCallback = Block_copy(updateCallback);
    _deleteCallback = Block_copy(deleteCallback);

    FSEventStreamContext context = {0, (void *) self, NULL, NULL, NULL};
    _stream = FSEventStreamCreate(NULL,
        &fsevents_callback,
        &context,
        (CFArrayRef) _paths,
        [_lastEventId unsignedLongLongValue],
        (CFAbsoluteTime) _latency,
        kFSEventStreamCreateFlagUseCFTypes
    );

    FSEventStreamScheduleWithRunLoop(_stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    FSEventStreamStart(_stream);
}

- (void)stop {
    FSEventStreamStop(_stream);
    FSEventStreamInvalidate(_stream);
}

- (void)callSyncNeededCallback {
    if (_syncNeededCallback){
        _syncNeededCallback(self);
    }
}

- (void)callAddCallback:(NSString *)path {
    if (_addCallback){
        _addCallback(path);
    }
}

- (void)callUpdateCallback:(NSString *)path {
    if (_updateCallback){
        _updateCallback(path);
    }
}

- (void)callDeleteCallback:(NSString *)path {
    if (_deleteCallback){
        _deleteCallback(path);
    }
}

- (void)handleFileSystemEventWithId:(uint64_t)eventId path:(NSString *)path {
    _lastEventId = [NSNumber numberWithUnsignedLongLong:eventId];

    for (NSString *node in [_fm directoryContentsAtPath:path]) {
        NSString *fullPath = [path stringByAppendingPathComponent:node];
        if ([_fm fileExistsAtPath:fullPath]) {
            NSDictionary *fileAttributes = [_fm attributesOfItemAtPath:fullPath error:NULL];
            NSDate *fileModDate = [fileAttributes objectForKey:NSFileModificationDate];
            NSDate *modDateForFullPath = [_pathModificationDates objectForKey:fullPath];
            if ([fileModDate compare:modDateForFullPath] != NSOrderedSame) {
                LOG(@"File %@ updated", fullPath);
                [self callUpdateCallback:fullPath];

                [_pathModificationDates setObject:fileModDate forKey:fullPath];
                [self callSyncNeededCallback];
            }
        }
    }

    for (NSString *node in [_fm directoryContentsAtPath:path]) {
        NSString *fullPath = [path stringByAppendingPathComponent:node];
        if ([_pathModificationDates objectForKey:fullPath] == nil) {
            LOG(@"File %@ added", fullPath);
            [self callAddCallback:fullPath];

            NSDictionary *fileAttributes = [_fm attributesOfItemAtPath:fullPath error:NULL];
            NSDate *fileModDate = [fileAttributes objectForKey:NSFileModificationDate];
            [_pathModificationDates setObject:fileModDate forKey:fullPath];
            [self callSyncNeededCallback];
        }
    }

    NSMutableArray *discardedItems = [NSMutableArray array];
    for (NSString *fullPath in [_pathModificationDates keyEnumerator]) {
        if (![_fm fileExistsAtPath:fullPath]) {
            [discardedItems addObject:fullPath];
        }
    }
    [_pathModificationDates removeObjectsForKeys:discardedItems];
    for (NSString *fullPath in discardedItems) {
        LOG(@"File %@ deleted", fullPath);
        [self callDeleteCallback:fullPath];

        [_pathModificationDates removeObjectForKey:fullPath];
        [self callSyncNeededCallback];
    }
}

@end