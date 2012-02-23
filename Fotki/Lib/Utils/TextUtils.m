//
//  Created by dimakononov on 15.02.12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "TextUtils.h"


@implementation TextUtils

+(id)hyperlinkFromString:(NSString*)inString withURL:(NSURL*)aURL
{
    NSMutableAttributedString* attrString = [[NSMutableAttributedString alloc] initWithString: inString];
    NSRange range = NSMakeRange(0, [attrString length]);

    [attrString beginEditing];
    [attrString addAttribute:NSLinkAttributeName value:[aURL absoluteString] range:range];

    // make the text appear in blue
    [attrString addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:range];

    // next make the text appear with an underline
    [attrString addAttribute:
            NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSSingleUnderlineStyle] range:range];

    [attrString endEditing];

    return [attrString autorelease];
}

+ (NSString *)formatFileSize:(float)sizeInByte {
    double kilobytes = sizeInByte / 1024;
    double megabytes = kilobytes / 1024;
    double gigabytes = megabytes / 1024;

    if ((int)gigabytes > 0){
        return [NSString stringWithFormat:@"%d Gb", (int)gigabytes];
    }

    if ((int)megabytes > 0){
        return [NSString stringWithFormat:@"%d Mb", (int)megabytes];
    }

    if ((int)kilobytes > 0){
        return [NSString stringWithFormat:@"%d Kb", (int)kilobytes];
    }

    return [NSString stringWithFormat:@"%d b", (int)sizeInByte];
}

+ (NSString *)formatSpeed:(float)speedInByteSec {
    double speedInKBSec = speedInByteSec / 1024;
    double speedInMBSec = speedInKBSec / 1024;
    double speedInGBSec = speedInMBSec / 1024;

    if ((int)speedInGBSec > 0){
        return [NSString stringWithFormat:@"%d Gb/sec", (int)speedInGBSec];
    }

    if ((int)speedInMBSec > 0){
        return [NSString stringWithFormat:@"%d Mb/sec", (int)speedInMBSec];
    }

    if ((int)speedInKBSec > 0){
        return [NSString stringWithFormat:@"%d Kb/sec", (int)speedInKBSec];
    }

    return [NSString stringWithFormat:@"%d b/sec", (int)speedInByteSec];
}
@end