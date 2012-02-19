//
//  SettingsWindowController.h
//  Fotki
//
//  Created by Vladimir Kuznetsov on 2/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef void (^NeedLoginCallback)(NSString *username, NSString *password);

@class AccountInfo;

@interface SettingsWindowController : NSWindowController

@property(nonatomic, retain) IBOutlet NSTextField *textLogin;
@property(nonatomic, retain) IBOutlet NSSecureTextField *textPassword;
@property(nonatomic, retain) IBOutlet NSTextField *labelInfo;
@property(nonatomic, retain) IBOutlet NSButton *buttonApply;
@property(nonatomic, retain) IBOutlet NSButton *buttonClose;

+ (id)controllerWithOnNeedLogIn:(NeedLoginCallback)onNeedLogin onNeedLogoutCallback:(Callback)onNeedLogout;

- (void)setStateAsLoggedInWithAccountInfo:(AccountInfo *)accountInfo;

- (void)setStateAsLoggingInWithUsername:(NSString *)username passowrd:(NSString *)password;

- (void)setStateAsNotLoggedInWithStatus:(NSString *)status;

- (void)setStateAsErrorWithUsername:(NSString *)username passowrd:(NSString *)password status:(NSString *)status;


@end
