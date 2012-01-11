//
//  Created by aistomin on 1/11/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>


@interface Folder : NSObject {
    NSString *_id;
    NSString *_name;
    NSMutableArray *_childFolders;
    NSMutableArray *_childAlbums;
}
@property(nonatomic, retain) NSString *id;
@property(nonatomic, retain) NSString *name;
@property(nonatomic, retain) NSMutableArray *childFolders;
@property(nonatomic, retain) NSMutableArray *childAlbums;

- (Folder *)initWithId:(NSString *)id andName:(NSString *)name;
@end