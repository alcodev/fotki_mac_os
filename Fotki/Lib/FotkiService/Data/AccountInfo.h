//
//  Created by dimakononov on 14.02.12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>


@interface AccountInfo : NSObject

@property(nonatomic, retain) NSString *username;
@property(nonatomic, retain) NSString *password;
@property(nonatomic, retain) NSString *name;
@property(nonatomic, retain) NSString *spaceUsed;
@property(nonatomic, retain) NSString *spaceLimit;

- (AccountInfo *)initWithName:(NSString *)name spaceLimit:(NSString *)spaceLimit spaceUsed:(NSString *)spaceUsed;

@end
