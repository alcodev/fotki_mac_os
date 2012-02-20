//
//  SettingsWindowController.m
//  Fotki
//
//  Created by Vladimir Kuznetsov on 2/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SettingsWindowController.h"
#import "Account.h"

@interface SettingsWindowController()

@property(assign) BOOL isLoggedIn;

@property(nonatomic, copy) NeedLoginCallback onNeedLogin;
@property(nonatomic, copy) Callback onNeedLogout;

- (id)initWithOnNeedLogIn:(NeedLoginCallback)onNeedLogin onNeedLogoutCallback:(Callback)onNeedLogout;

- (void)onApplyButtonClicked:(id)sender;

- (void)onCloseButtonClicked:(id)sender;


@end

@implementation SettingsWindowController

@synthesize textLogin = _textLogin;
@synthesize textPassword = _textPassword;
@synthesize labelInfo = _labelInfo;
@synthesize buttonApply = _buttonApply;
@synthesize buttonClose = _buttonClose;
@synthesize progressIndicatorLogin = _progressIndicatorLogin;

@synthesize isLoggedIn = _isLoggedIn;

@synthesize onNeedLogin = _onNeedLogin;
@synthesize onNeedLogout = _onNeedLogout;


- (id)initWithOnNeedLogIn:(NeedLoginCallback)onNeedLogin onNeedLogoutCallback:(Callback)onNeedLogout {
    self = [super initWithWindowNibName:@"SettingsWindow"];
    if (self) {
        //HACK: http://borkware.com/quickies/single?id=276
        //The window controller nib doesn't get loaded until the window is manipulated.
        //This can cause confusion if you do any kind of setup before the window is shown.
        //If you call the window method, that will force the nib file to be loaded
        (void) [self window];

        self.onNeedLogin = onNeedLogin;
        self.onNeedLogout = onNeedLogout;

        [self.buttonApply setAction:@selector(onApplyButtonClicked:)];
        [self.buttonClose setAction:@selector(onCloseButtonClicked:)];

        //NSImage *image = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kAlertNoteIcon)];
    }

    return self;
}

+ (id)controllerWithOnNeedLogIn:(NeedLoginCallback)onNeedLogin onNeedLogoutCallback:(Callback)onNeedLogout {
    return [[[SettingsWindowController alloc] initWithOnNeedLogIn:onNeedLogin onNeedLogoutCallback:onNeedLogout] autorelease];
}

- (void)dealloc {
    [_textLogin release];
    [_textPassword release];
    [_labelInfo release];
    [_buttonApply release];
    [_buttonClose release];
    [_progressIndicatorLogin release];

    [_onNeedLogin release];
    [_onNeedLogout release];

    [super dealloc];
}

- (IBAction)showWindow:(id)sender {
    [super showWindow:sender];

    [self.window makeKeyAndOrderFront:self];
    [self.window center];
    [NSApp activateIgnoringOtherApps:YES];
}

- (void)onApplyButtonClicked:(id)sender {
    if(!self.isLoggedIn) {
        if(self.onNeedLogin) {
            self.onNeedLogin([self.textLogin stringValue], [self.textPassword stringValue]);
        }
    } else {
        if (self.onNeedLogout) {
            self.onNeedLogout();
        }
    }
}

- (void)onCloseButtonClicked:(id)sender {
    [self.window close];
}

- (void)setStateAsLoggedInWithAccount:(Account *)account {
    [self.labelInfo setStringValue:[NSString stringWithFormat:@"Logged in as %@", account.name]];

    self.buttonApply.title = @"Logout";
    [self.buttonApply setEnabled:YES];

    [self.textLogin setStringValue:account.username];
    [self.textLogin setEnabled:NO];

    [self.textPassword setStringValue:account.password];
    [self.textPassword setEnabled:NO];

    [self.progressIndicatorLogin stopAnimation:self];

    self.isLoggedIn = YES;
}

- (void)setStateAsLoggingInWithUsername:(NSString *)username passowrd:(NSString *)password {
    [self.labelInfo setStringValue:@"Logging in ..."];
    self.buttonApply.title = @"Login";

    [self.textLogin setEnabled:NO];
    [self.textLogin setStringValue:username];

    [self.textPassword setEnabled:NO];
    [self.textPassword setStringValue:password];

    [self.progressIndicatorLogin stopAnimation:self];

    [self.buttonApply setEnabled:NO];

    self.isLoggedIn = NO;
}

- (void)setStateAsNotLoggedInWithStatus:(NSString *)status {
    [self.labelInfo setStringValue:status];

    self.buttonApply.title = @"Login";
    [self.buttonApply setEnabled:YES];

    [self.textLogin setEnabled:YES];
    [self.textPassword setEnabled:YES];

    [self.progressIndicatorLogin startAnimation:self];

    self.isLoggedIn = NO;
}

- (void)setStateAsErrorWithUsername:(NSString *)username passowrd:(NSString *)password status:(NSString *)status {
    [self.labelInfo setStringValue:status];

    self.buttonApply.title = @"Login";
    [self.buttonApply setEnabled:YES];

    [self.textLogin setStringValue:username];
    [self.textLogin setEnabled:YES];

    [self.textPassword setStringValue:password];
    [self.textPassword setEnabled:YES];

    [self.progressIndicatorLogin stopAnimation:self];

    self.isLoggedIn = NO;
}

@end
