//
//  Created by vavaka on 2/19/12.



#import "UploadFilesStatisticsCalculator.h"
#import "FileSystemHelper.h"
#import "DateUtils.h"

@interface UploadFilesStatisticsCalculator ()

- (id)initWithPathsFiles:(NSArray *)arrayPathsFiles;

- (void)clearCurrentStatistics;

@end

@implementation UploadFilesStatisticsCalculator

@synthesize dateStart = _dateStart;

@synthesize arrayPathsFilesAll = _arrayPathsFilesAll;
@synthesize bytesTotalExpectedToWrite = _bytesTotalExpectedToWrite;
@synthesize arrayPathsFilesUploaded = _arrayPathsFilesUploaded;
@synthesize bytesTotalWritten = _bytesTotalWritten;
@synthesize arrayPathsFilesFailed = _arrayPathsFilesFailed;
@synthesize bytesTotalFailed = _bytesTotalFailed;

@synthesize dateCurrentStatisticsLastCalled = _dateCurrentStatisticsLastCalled;
@synthesize bytesCurrentLastWritten = _bytesCurrentLastWritten;
@synthesize bytesCurrentTotalWritten = _bytesCurrentTotalWritten;
@synthesize bytesCurrentTotalExpectedToWrite = _bytesCurrentTotalExpectedToWrite;


- (id)initWithPathsFiles:(NSArray *)arrayPathsFiles {
    self = [super init];
    if (self) {
        self.dateStart = [NSDate date];

        self.arrayPathsFilesAll = arrayPathsFiles;
        self.bytesTotalExpectedToWrite = (NSUInteger) [FileSystemHelper sizeForFilesAtPaths:self.arrayPathsFilesAll];
        self.arrayPathsFilesUploaded = [NSMutableArray array];
        self.bytesTotalWritten = 0;
        self.arrayPathsFilesFailed = [NSMutableArray array];
        self.bytesTotalFailed = 0;

        [self clearCurrentStatistics];
    }

    return self;
}

+ (id)calculatorWithPathsFiles:(NSArray *)arrayPathsFiles {
    return [[[UploadFilesStatisticsCalculator alloc] initWithPathsFiles:arrayPathsFiles] autorelease];
}

- (void)dealloc {
    [_dateStart release];

    [_arrayPathsFilesAll release];
    [_arrayPathsFilesUploaded release];
    [_arrayPathsFilesFailed release];

    [_dateCurrentStatisticsLastCalled release];

    [super dealloc];
}

- (void)clearCurrentStatistics {
    self.bytesCurrentLastWritten = 0;
    self.bytesCurrentTotalWritten = 0;
    self.bytesCurrentTotalExpectedToWrite = 0;
}

- (void)setCurrentStatisticsWithBytesLastWritten:(NSUInteger)bytesLastWritten bytesTotalWritten:(NSUInteger)bytesTotalWritten bytesTotalExpectedToWrite:(NSUInteger)bytesTotalExpectedToWrite {
    self.dateCurrentStatisticsLastCalled = [NSDate date];

    self.bytesCurrentLastWritten = bytesLastWritten;
    self.bytesCurrentTotalWritten = bytesTotalWritten;
    self.bytesCurrentTotalExpectedToWrite = bytesTotalExpectedToWrite;

    self.bytesTotalWritten += bytesLastWritten;
}

- (void)setUploadSuccessForPath:(NSString *)path {
    [self.arrayPathsFilesUploaded addObject:path];
    [self clearCurrentStatistics];
}

- (void)setUploadFailedForPath:(NSString *)path {
    self.bytesTotalFailed += [FileSystemHelper sizeForFileAtPath:path];
    [self.arrayPathsFilesFailed addObject:path];
    [self clearCurrentStatistics];
}

- (float)speed {
    if (!self.dateCurrentStatisticsLastCalled){
        return 0.0f;
    } else {
        NSDate *now = [NSDate date];

        //NSInteger secondsFromLastWrite = [DateUtils dateDiffInSecondsBetweenDate1:self.dateCurrentStatisticsLastCalled andDate2:now];
        //return secondsFromLastWrite > 0 ? ((float) self.bytesCurrentLastWritten / (float) secondsFromLastWrite) : self.bytesCurrentLastWritten;

        NSInteger secondsFromStart = [DateUtils dateDiffInSecondsBetweenDate1:self.dateStart andDate2:now];
        return secondsFromStart > 0 ? ((float) self.bytesTotalWritten / (float) secondsFromStart) : 0.0f;
    }
}

- (NSUInteger)bytesCurrentLeft {
    if (!self.dateCurrentStatisticsLastCalled) {
        return 0;
    } else {
        return self.bytesCurrentTotalExpectedToWrite - self.bytesCurrentTotalWritten;
    }
}

- (NSUInteger)bytesTotalLeft {
    NSUInteger bytesTotalLeft = self.bytesTotalExpectedToWrite - self.bytesTotalWritten - self.bytesTotalFailed;
    return bytesTotalLeft;
}

- (float)secondsCurrentLeft {
    return self.speed > 0.0f ? self.bytesCurrentLeft / self.speed : 0.0f;
}

- (float)secondsTotalLeft {
    return self.speed > 0.0f ? self.bytesTotalLeft / self.speed : 0.0f;
}

@end