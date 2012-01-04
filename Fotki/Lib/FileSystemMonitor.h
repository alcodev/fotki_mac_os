//
//  Created by vavaka on 1/3/12.



#import <Foundation/Foundation.h>

typedef void (^FileSystemSyncCallback)(id sender);
typedef void (^FileSystemEventCallback)(NSString *path);

@interface FileSystemMonitor : NSObject {
    NSFileManager *_fm;
    NSTimeInterval _latency;
    NSMutableArray *_files;
    FSEventStreamRef _stream;

    NSArray *_paths;

    FileSystemSyncCallback _syncNeededCallback;
    FileSystemEventCallback _addCallback;
    FileSystemEventCallback _updateCallback;
    FileSystemEventCallback _deleteCallback;
}

@property(readonly) NSNumber *lastEventId;
@property(readonly) NSMutableDictionary *filesHashes;

- (id)initWithPaths:(NSArray *)paths lastEventId:(NSNumber *)lastEventId filesHashes:(NSMutableDictionary *)filesHash;

- (void)startAndDoOnSyncNeeded:(FileSystemSyncCallback)syncNeededCallback doOnFileAdded:(FileSystemEventCallback)addCallback doOnFileUpdated:(FileSystemEventCallback)updateCallback doOnFileDeleted:(FileSystemEventCallback)deleteCallback;

- (void)stop;

- (void)handleFileSystemEventWithId:(uint64_t)eventId path:(NSString *)path;
@end