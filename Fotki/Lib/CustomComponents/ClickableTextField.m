//
//  Created by dimakononov on 23.02.12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "ClickableTextField.h"


@implementation ClickableTextField
@synthesize onMouseClicked = _onMouseClicked;


-(void)mouseDown:(NSEvent *)event {
    self.onMouseClicked(event);
}

- (void)dealloc {
    [_onMouseClicked release];
    [super dealloc];
}
@end