//
//  Created by dimakononov on 14.02.12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>


@interface Account : NSObject

@property(nonatomic, retain) NSString *username;
@property(nonatomic, retain) NSString *password;
@property(nonatomic, retain) NSString *fullName;
@property(nonatomic, retain) NSString *spaceUsed;
@property(nonatomic, retain) NSString *spaceLimit;
@property(nonatomic, retain) NSArray *albums;

- (Account *)initWithFullName:(NSString *)fullName spaceLimit:(NSString *)spaceLimit spaceUsed:(NSString *)spaceUsed;

@end
