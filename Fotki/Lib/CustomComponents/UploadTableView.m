//
//  Created by dimakononov on 24.02.12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "UploadTableView.h"


@implementation UploadTableView

@synthesize successUploadRows = _successUploadRows;
@synthesize errorUploadRows = _errorUploadRows;
@synthesize existFilesRows = _existFilesRows;


- (void)dealloc {
    [_successUploadRows release];
    [_errorUploadRows release];
    [_existFilesRows release];
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
    if ([self.successUploadRows containsObject:[NSNumber numberWithInteger:row]]) {
        [self drawColorRow:row clipRect:clipRect color:[[NSColor greenColor] colorWithAlphaComponent:0.2]];
    }
    else if ([self.existFilesRows containsObject:[NSNumber numberWithInteger:row]]) {
        [self drawColorRow:row clipRect:clipRect color:[[NSColor greenColor] colorWithAlphaComponent:0.1]];
    }
    else if ([self.errorUploadRows containsObject:[NSNumber numberWithInteger:row]]) {
        [self drawColorRow:row clipRect:clipRect color:[[NSColor redColor] colorWithAlphaComponent:0.2]];
    }
    else{
        [self drawColorRow:row clipRect:clipRect color:[NSColor whiteColor]];
    }
}

@end