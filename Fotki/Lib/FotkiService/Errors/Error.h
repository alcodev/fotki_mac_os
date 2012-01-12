//
//  Created by aistomin on 1/12/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>


@interface Error : NSObject {
    NSString *_id;
    NSString *_message;
}
@property(nonatomic, retain) NSString *id;
@property(nonatomic, retain) NSString *message;

- (Error *)initWithId:(NSString *)id andMessage:(NSString *)message;
@end