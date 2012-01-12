//
//  Created by aistomin on 1/12/12.
//
//


#import "ErrorResponseParser.h"
#import "Error.h"
#import "CXMLDocument.h"


@implementation ErrorResponseParser {

}

+ (Error *)extractErrorFromXmlDocument:(CXMLDocument *)document {
    NSArray *nodes = [document nodesForXPath:@"//result" error:nil];
    NSXMLElement *element = [nodes objectAtIndex:0];
    NSString *resultValue = [element stringValue];
    if (![@"error" isEqualToString:resultValue]) {
        [NSException raise:@"Response is not an error response" format:@"Response is not an error response"];
    }

    nodes = [document nodesForXPath:@"//id" error:nil];
    element = [nodes objectAtIndex:0];
    NSString *errorId = [element stringValue];

    nodes = [document nodesForXPath:@"//message" error:nil];
    element = [nodes objectAtIndex:0];
    NSString *errorMessage = [element stringValue];

    Error *error = [[[Error alloc] initWithId:errorId andMessage:errorMessage] autorelease];
    return (error);
}
@end