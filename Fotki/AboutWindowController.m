//
//  Created by dimakononov on 22.02.12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "AboutWindowController.h"
#import "TextUtils.h"


@implementation AboutWindowController
@synthesize companyUrlLabel = _companyUrlLabel;

-(AboutWindowController *)init {
    self = [super initWithWindowNibName:@"AboutWindow"];
    if (self){

    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    [self.companyUrlLabel setAllowsEditingTextAttributes:YES];
    [self.companyUrlLabel setSelectable:YES];
    NSURL *url = [NSURL URLWithString:@"http://www.fotki.com"];
    NSMutableAttributedString *attributedString = [[[NSMutableAttributedString alloc] init] autorelease];
    [attributedString appendAttributedString:[TextUtils hyperlinkFromString:@"http://www.fotki.com" withURL:url]];

    NSMutableParagraphStyle *mutParaStyle=[[NSMutableParagraphStyle alloc] init];
    [mutParaStyle setAlignment:NSCenterTextAlignment];
    [attributedString addAttributes:[NSDictionary dictionaryWithObject:mutParaStyle forKey:NSParagraphStyleAttributeName] range:NSMakeRange(0,[attributedString length])];
    [mutParaStyle release];

    [self.companyUrlLabel setAttributedStringValue:attributedString];
}

+(AboutWindowController *)controller{
    return [[[AboutWindowController alloc] init] autorelease];
}

- (IBAction)showWindow:(id)sender {
    [super showWindow:sender];
    [self.window makeKeyAndOrderFront:self];
    [self.window center];
    [NSApp activateIgnoringOtherApps:YES];
}

- (void)dealloc {
    [_companyUrlLabel release];
    [super dealloc];
}
@end