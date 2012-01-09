//
//  Created by aistomin on 1/9/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "FotkiServiceFacade.h"
#import "AFHTTPRequestOperation.h"
#import "AFHTTPClient.h"
#import "AFXMLRequestOperation.h"


@implementation FotkiServiceFacade {

}

- (void)authenticateWithLogin:(NSString *)login andPassword:(NSString *)password {

    NSURL *url = [NSURL URLWithString:@"http://api.fotki.com/"];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
            login, @"login",
            password, @"password",
            nil];
    AFHTTPClient *httpClient = [[[AFHTTPClient alloc] initWithBaseURL:url] autorelease];
    [httpClient setDefaultHeader:@"Accept" value:@"text/xml"];
    [httpClient getPath:@"/new_session" parameters:params success:^(__unused AFHTTPRequestOperation *operation, id response) {
        NSString *responseString = [[[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding] autorelease];
        NSError *error = nil;
        NSXMLDocument *document = [[[NSXMLDocument alloc] initWithXMLString:responseString options:NSXMLNodeOptionsNone error:&error] autorelease];

        NSArray *nodes = [document nodesForXPath:@"session/result" error:&error];
        NSXMLElement *element = [nodes objectAtIndex:0];
        NSString *resultValue = [element stringValue];
        LOG(@"result: %@", resultValue);

        nodes = [document nodesForXPath:@"session/session_id" error:&error];
        element = [nodes objectAtIndex:0];
        resultValue = [element stringValue];
        LOG(@"session_id: %@", resultValue);

    }           failure:^(__unused AFHTTPRequestOperation *operation, NSError *error) {
        LOG(@"error: %@", error);
    }];
}

@end