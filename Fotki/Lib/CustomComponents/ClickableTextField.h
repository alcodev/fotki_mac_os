//
//  Created by dimakononov on 23.02.12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>

typedef void (^OnMouseClickedCallback) (NSEvent *event);

@interface ClickableTextField : NSTextField

@property(nonatomic, copy)OnMouseClickedCallback onMouseClicked;
@end