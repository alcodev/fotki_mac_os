//
//  Created by aistomin on 1/11/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>


@interface Photo : NSObject {
    NSString *_id;
    NSString *_title;
    NSString *_originalUrl;
    NSString *_albumId;
}
@property(nonatomic, retain) NSString *id;
@property(nonatomic, retain) NSString *title;
@property(nonatomic, retain) NSString *originalUrl;
@property(nonatomic, retain) NSString *albumId;

- (Photo *)initWithId:(NSString *)id title:(NSString *)title originalUrl:(NSString *)url albumId:(NSString *)albumId;
@end