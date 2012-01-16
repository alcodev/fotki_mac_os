//
//  Created by vavaka on 1/3/12.



#import "FileSystemMonitor.h"
#import "FileMD5Hash.h"

static void fsevents_callback(ConstFSEventStreamRef streamRef, void *userData, size_t numEvents, void *eventPaths, const FSEventStreamEventFlags eventFlags[], const FSEventStreamEventId eventIds[]) {
    LOG(@"Events received");

    FileSystemMonitor *fileSystemMonitor = (FileSystemMonitor *) userData;
    size_t i;
    for (i = 0; i < numEvents; i++) {
        if ([fileSystemMonitor.lastEventId integerValue] > 0 && eventIds[i] <= [fileSystemMonitor.lastEventId unsignedLongLongValue]) {
            continue;
        }
        FSEventStreamEventFlags flag = eventFlags[i];
        LOG(@"Flags for %d", i);
        if (flag & kFSEventStreamEventFlagNone) {
            LOG(@"kFSEventStreamEventFlagNone");
        }
        if (flag & kFSEventStreamEventFlagMustScanSubDirs) {
            LOG(@"kFSEventStreamEventFlagMustScanSubDirs");
        }
        if (flag & kFSEventStreamEventFlagUserDropped) {
            LOG(@"kFSEventStreamEventFlagUserDropped");
        }
        if (flag & kFSEventStreamEventFlagKernelDropped) {
            LOG(@"kFSEventStreamEventFlagKernelDropped");
        }
        if (flag & kFSEventStreamEventFlagEventIdsWrapped) {
            LOG(@"kFSEventStreamEventFlagEventIdsWrapped");
        }
        if (flag & kFSEventStreamEventFlagHistoryDone) {
            LOG(@"kFSEventStreamEventFlagHistoryDone");
        }
        if (flag & kFSEventStreamEventFlagRootChanged) {
            LOG(@"kFSEventStreamEventFlagRootChanged");
        }
        if (flag & kFSEventStreamEventFlagMount) {
            LOG(@"kFSEventStreamEventFlagMount");
        }
        if (flag & kFSEventStreamEventFlagUnmount) {
            LOG(@"kFSEventStreamEventFlagUnmount");
        }
        if (flag & kFSEventStreamEventFlagItemCreated) {
            LOG(@"kFSEventStreamEventFlagItemCreated");
        }
        if (flag & kFSEventStreamEventFlagItemRemoved) {
            LOG(@"kFSEventStreamEventFlagItemRemoved");
        }
        if (flag & kFSEventStreamEventFlagItemInodeMetaMod) {
            LOG(@"kFSEventStreamEventFlagItemInodeMetaMod");
        }
        if (flag & kFSEventStreamEventFlagItemRenamed) {
            LOG(@"kFSEventStreamEventFlagItemRenamed");
        }
        if (flag & kFSEventStreamEventFlagItemModified) {
            LOG(@"kFSEventStreamEventFlagItemModified");
        }
        if (flag & kFSEventStreamEventFlagItemFinderInfoMod) {
            LOG(@"kFSEventStreamEventFlagItemFinderInfoMod");
        }
        if (flag & kFSEventStreamEventFlagItemChangeOwner) {
            LOG(@"kFSEventStreamEventFlagItemChangeOwner");
        }
        if (flag & kFSEventStreamEventFlagItemXattrMod) {
            LOG(@"kFSEventStreamEventFlagItemXattrMod");
        }
        if (flag & kFSEventStreamEventFlagItemIsFile) {
            LOG(@"kFSEventStreamEventFlagItemIsFile");
        }
        if (flag & kFSEventStreamEventFlagItemIsDir) {
            LOG(@"kFSEventStreamEventFlagItemIsDir");
        }
        if (flag & kFSEventStreamEventFlagItemIsSymlink) {
            LOG(@"kFSEventStreamEventFlagItemIsSymlink");
        }
        LOG(@"Handling fs event %lu", eventIds[i]);
        if (eventPaths) {
            [fileSystemMonitor handleFileSystemEventWithId:eventIds[i] path:[(NSArray *) eventPaths objectAtIndex:i]];
        }
    }
}

@implementation FileSystemMonitor

@synthesize lastEventId = _lastEventId;
@synthesize filesHashes = _filesHashes;

- (id)initWithPaths:(NSArray *)paths lastEventId:(NSNumber *)lastEventId filesHashes:(NSMutableDictionary *)filesHash {
    self = [super init];
    if (self != nil) {
        _fm = [NSFileManager defaultManager];
        _files = [NSMutableArray new];
        _latency = 3.0;

        _paths = [paths retain];
        _lastEventId = [lastEventId retain];
        _filesHashes = [filesHash retain];
    }

    return self;
}

- (void)dealloc {
    [_files release];

    [_paths release];
    [_filesHashes release];
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
            kFSEventStreamEventIdSinceNow,
            (CFAbsoluteTime) _latency,
            kFSEventStreamCreateFlagIgnoreSelf | kFSEventStreamCreateFlagUseCFTypes
    );

    FSEventStreamScheduleWithRunLoop(_stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    FSEventStreamStart(_stream);
}

- (void)start {
    if (_stream) {
        FSEventStreamScheduleWithRunLoop(_stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        FSEventStreamStart(_stream);
        FSEventStreamFlushSync(_stream);
    }
}

- (void)stop {
    FSEventStreamStop(_stream);
}

- (void)shutDown {
    FSEventStreamStop(_stream);
    FSEventStreamInvalidate(_stream);
    FSEventStreamRelease(_stream);
}

- (void)callSyncNeededCallback {
    if (_syncNeededCallback) {
        _syncNeededCallback(self);
    }
}

- (void)callAddCallback:(NSString *)path {
    if (_addCallback) {
        _addCallback(path);
    }
}

- (void)callUpdateCallback:(NSString *)path {
    if (_updateCallback) {
        _updateCallback(path);
    }
}

- (void)callDeleteCallback:(NSString *)path {
    if (_deleteCallback) {
        _deleteCallback(path);
    }
}

- (NSString *)hashForFileAtPath:(NSString *)path {
    NSString *result = nil;
    CFStringRef hash = FileMD5HashCreateWithPath((CFStringRef) path, FileHashDefaultChunkSizeForReadingData);
    if (hash) {
        result = [NSString stringWithString:(NSString *) hash];
        CFRelease(result);
    }

    return result;

}

- (void)handleFileSystemEventWithId:(uint64_t)eventId path:(NSString *)path {
    _lastEventId = [NSNumber numberWithUnsignedLongLong:eventId];

    for (NSString *node in [_fm directoryContentsAtPath:path]) {
        NSString *fullPath = [path stringByAppendingPathComponent:node];
        NSString *hash = [self hashForFileAtPath:fullPath];
        if (!hash) {
            LOG(@"Can't get hash of %@ file", fullPath);
            continue;
        }

        if (![_filesHashes objectForKey:fullPath]) {
            LOG(@"File %@ added, hash: %@", fullPath, hash);
            [self callAddCallback:fullPath];

            [_filesHashes setObject:hash forKey:fullPath];
            [self callSyncNeededCallback];
        } else if (![hash isEqualToString:[_filesHashes objectForKey:fullPath]]) {
            LOG(@"File %@ updated, hash_old: %@, hash_new: %@", fullPath, [_filesHashes objectForKey:fullPath], hash);
            [self callUpdateCallback:fullPath];

            [_filesHashes setObject:hash forKey:fullPath];
            [self callSyncNeededCallback];
        }
    }

    NSMutableArray *discardedItems = [NSMutableArray array];
    for (NSString *fullPath in [_filesHashes keyEnumerator]) {
        if (![_fm fileExistsAtPath:fullPath]) {
            [discardedItems addObject:fullPath];
        }
    }
    for (NSString *fullPath in discardedItems) {
        LOG(@"File %@ deleted", fullPath);
        [self callDeleteCallback:fullPath];

        [_filesHashes removeObjectForKey:fullPath];
        [self callSyncNeededCallback];
    }
}

@end