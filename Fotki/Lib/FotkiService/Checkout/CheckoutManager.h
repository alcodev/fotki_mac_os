//
//  Created by aistomin on 1/12/12.
//
//


#import <Foundation/Foundation.h>
#import "FotkiServiceFacade.h"

@class FotkiServiceFacade;


@interface CheckoutManager : NSObject
+ (void)createFoldersHierarchyOnHardDisk:(NSMutableArray *)folders inDirectory:(NSString *)directory withFileManager:(NSFileManager *)fileManager  serviceFacade:(FotkiServiceFacade *)serviceFacade onFinish:(ServiceFacadeCallback)onFinish;

+ (void)clearDirectory:(NSString *)path withFileManager:(NSFileManager *)fileManager;
@end