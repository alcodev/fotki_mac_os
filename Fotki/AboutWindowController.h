//
//  Created by dimakononov on 22.02.12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>


@interface AboutWindowController : NSWindowController

@property(nonatomic, retain) IBOutlet NSTextField *companyUrlLabel;

+ (AboutWindowController *)controller;

@end