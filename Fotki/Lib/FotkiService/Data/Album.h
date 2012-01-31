//
//  Created by aistomin on 1/10/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>


@interface Album : NSObject {
    NSString *_id;
    NSString *_name;
    NSString *_path;
}
@property(nonatomic, retain) NSString *id;
@property(nonatomic, retain) NSString *name;
@property(nonatomic, retain) NSString *path;

- (Album *)initWithId:(NSString *)id andName:(NSString *)name;
@end