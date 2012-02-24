//
//  Created by dimakononov on 24.02.12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "UploadTableView.h"


@implementation UploadTableView

@synthesize greenRows = _greenRows;
@synthesize redRows = _redRows;
@synthesize yellowRows = _yellowRows;


- (void)dealloc {
    [_greenRows release];
    [_redRows release];
    [_yellowRows release];
    [super dealloc];
}

- (void)drawColorRow:(int)row clipRect:(NSRect)clipRect color:(NSColor *)color {
    NSRect rect = [self rectOfRow:row];
    [color set];
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path setLineWidth:rect.size.height];
    float x = rect.origin.x;
    float y = rect.origin.y + (rect.size.height / 2.0);
    [path moveToPoint:NSMakePoint(x,y)];
    [path lineToPoint:NSMakePoint(x + rect.size.width, y)];
    [path stroke];
    [super drawRow:row clipRect:clipRect];
}

- (void)drawRow:(int)row clipRect:(NSRect)clipRect {
    if ([self.greenRows containsObject:[NSNumber numberWithInteger:row]]) {
        [self drawColorRow:row clipRect:clipRect color:[[NSColor greenColor] colorWithAlphaComponent:0.2]];
    }
    else if ([self.yellowRows containsObject:[NSNumber numberWithInteger:row]]) {
        [self drawColorRow:row clipRect:clipRect color:[[NSColor yellowColor] colorWithAlphaComponent:0.2]];
    }
    else if ([self.redRows containsObject:[NSNumber numberWithInteger:row]]) {
        [self drawColorRow:row clipRect:clipRect color:[[NSColor redColor] colorWithAlphaComponent:0.2]];
    }
    else{
        [self drawColorRow:row clipRect:clipRect color:[NSColor whiteColor]];
    }
}

@end