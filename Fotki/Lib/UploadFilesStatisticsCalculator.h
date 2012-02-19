//
//  Created by vavaka on 2/19/12.



#import <Foundation/Foundation.h>


@interface UploadFilesStatisticsCalculator : NSObject

@property(nonatomic, retain) NSDate *dateStart;

@property(nonatomic, retain) NSArray *arrayPathsFilesAll;
@property(nonatomic, retain) NSMutableArray *arrayPathsFilesUploaded;
@property(nonatomic, retain) NSMutableArray *arrayPathsFilesFailed;

@property(nonatomic, assign) NSUInteger bytesTotalWritten;
@property(nonatomic, assign) NSUInteger bytesTotalExpectedToWrite;
@property(nonatomic, assign) NSUInteger bytesTotalFailed;

@property(nonatomic, retain) NSDate *dateCurrentStatisticsLastCalled;
@property(nonatomic, assign) NSUInteger bytesCurrentLastWritten;
@property(nonatomic, assign) NSUInteger bytesCurrentTotalWritten;
@property(nonatomic, assign) NSUInteger bytesCurrentTotalExpectedToWrite;

@property(readonly) float speed;
@property(readonly) NSUInteger bytesCurrentLeft;
@property(readonly) NSUInteger bytesTotalLeft;
@property(readonly) float secondsCurrentLeft;
@property(readonly) float secondsTotalLeft;

+ (id)calculatorWithPathsFiles:(NSArray *)arrayPathsFiles;

- (void)setCurrentStatisticsWithBytesLastWritten:(NSUInteger)bytesLastWritten bytesTotalWritten:(NSUInteger)bytesTotalWritten bytesTotalExpectedToWrite:(NSUInteger)bytesTotalExpectedToWrite;

- (void)setUploadSuccessForPath:(NSString *)path;

- (void)setUploadFailedForPath:(NSString *)path;


@end