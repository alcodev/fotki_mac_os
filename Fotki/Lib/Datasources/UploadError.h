//
//  Created by dimakononov on 22.02.12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>


@interface UploadError : NSObject

@property(nonatomic, retain)NSString *event;
@property(nonatomic, retain)NSString *errorDescription;

- (UploadError *)initWithEvent:(NSString *)event andErrorDescription:(NSString *)errorDescription;


@end