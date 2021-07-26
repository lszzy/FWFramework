//
//  TestSocketViewController.m
//  Example
//
//  Created by wuyong on 2019/6/10.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

#import "TestSocketViewController.h"

#define USE_SECURE_CONNECTION 1
#define ENABLE_BACKGROUNDING  0

#if USE_SECURE_CONNECTION
    #define HOST @"www.paypal.com"
    #define PORT 443
#else
    #define HOST @"google.com"
    #define PORT 80
#endif

@interface TestSocketViewController () <FWAsyncSocketDelegate>

@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UILabel *label2;

@end

@implementation TestSocketViewController {
    FWAsyncSocket *asyncSocket;
}

- (void)renderView
{
    self.label = [[UILabel alloc] init];
    self.label.numberOfLines = 0;
    self.label.textAlignment = NSTextAlignmentCenter;
    [self.fwView addSubview:self.label];
    [self.label fwAlignCenterToSuperviewWithOffset:CGPointMake(0, -50)];
    [self.label fwPinEdgesToSuperviewHorizontal];
    
    self.label2 = [[UILabel alloc] init];
    self.label2.numberOfLines = 0;
    self.label2.textAlignment = NSTextAlignmentCenter;
    [self.fwView addSubview:self.label2];
    [self.label2 fwAlignCenterToSuperviewWithOffset:CGPointMake(0, 50)];
    [self.label2 fwPinEdgesToSuperviewHorizontal];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self testOAuth2];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    
    asyncSocket = [[FWAsyncSocket alloc] initWithDelegate:self delegateQueue:mainQueue];
    
#if USE_SECURE_CONNECTION
    {
    NSString *host = HOST;
    uint16_t port = PORT;
    
    FWLogInfo(@"Connecting to \"%@\" on port %hu...", host, port);
    self.label.text = @"Connecting...";
    
    NSError *error = nil;
    if (![asyncSocket connectToHost:host onPort:port error:&error])
        {
        FWLogError(@"Error connecting: %@", error);
        self.label.text = @"Oops";
        }
    }
#else
    {
    NSString *host = HOST;
    uint16_t port = PORT;
    
    FWLogInfo(@"Connecting to \"%@\" on port %hu...", host, port);
    self.label.text = @"Connecting...";
    
    NSError *error = nil;
    if (![asyncSocket connectToHost:host onPort:port error:&error])
        {
        FWLogError(@"Error connecting: %@", error);
        self.label.text = @"Oops";
        }
    
    // You can also specify an optional connect timeout.
    
    //    NSError *error = nil;
    //    if (![asyncSocket connectToHost:host onPort:80 withTimeout:5.0 error:&error])
    //    {
    //        FWLogError(@"Error connecting: %@", error);
    //    }
    
    }
#endif
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    FWLogInfo(@"socket:%p disconnect", asyncSocket);
    [asyncSocket disconnect];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Socket Delegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)socket:(FWAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    FWLogInfo(@"socket:%p didConnectToHost:%@ port:%hu", sock, host, port);
    self.label.text = @"Connected";
    
    //    FWLogInfo(@"localHost :%@ port:%hu", [sock localHost], [sock localPort]);
    
#if USE_SECURE_CONNECTION
    {
    // Connected to secure server (HTTPS)
    
#if ENABLE_BACKGROUNDING && !TARGET_IPHONE_SIMULATOR
    {
        // Backgrounding doesn't seem to be supported on the simulator yet
    
        [sock performBlock:^{
            if ([sock enableBackgroundingOnSocket])
                FWLogInfo(@"Enabled backgrounding on socket");
            else
                FWLogWarn(@"Enabling backgrounding failed!");
        }];
    }
#endif
    
    // Configure SSL/TLS settings
    NSMutableDictionary *settings = [NSMutableDictionary dictionaryWithCapacity:3];
    
    // If you simply want to ensure that the remote host's certificate is valid,
    // then you can use an empty dictionary.
    
    // If you know the name of the remote host, then you should specify the name here.
    //
    // NOTE:
    // You should understand the security implications if you do not specify the peer name.
    // Please see the documentation for the startTLS method in FWAsyncSocket.h for a full discussion.
    
    [settings setObject:@"www.paypal.com"
                 forKey:(NSString *)kCFStreamSSLPeerName];
    
    // To connect to a test server, with a self-signed certificate, use settings similar to this:
    
    //    // Allow expired certificates
    //    [settings setObject:[NSNumber numberWithBool:YES]
    //                 forKey:(NSString *)kCFStreamSSLAllowsExpiredCertificates];
    //
    //    // Allow self-signed certificates
    //    [settings setObject:[NSNumber numberWithBool:YES]
    //                 forKey:(NSString *)kCFStreamSSLAllowsAnyRoot];
    //
    //    // In fact, don't even validate the certificate chain
    //    [settings setObject:[NSNumber numberWithBool:NO]
    //                 forKey:(NSString *)kCFStreamSSLValidatesCertificateChain];
    
    FWLogInfo(@"Starting TLS with settings:\n%@", settings);
    
    [sock startTLS:settings];
    
    // You can also pass nil to the startTLS method, which is the same as passing an empty dictionary.
    // Again, you should understand the security implications of doing so.
    // Please see the documentation for the startTLS method in FWAsyncSocket.h for a full discussion.
    
    }
#else
    {
    // Connected to normal server (HTTP)
    
#if ENABLE_BACKGROUNDING && !TARGET_IPHONE_SIMULATOR
        {
        // Backgrounding doesn't seem to be supported on the simulator yet
        
        [sock performBlock:^{
            if ([sock enableBackgroundingOnSocket])
                FWLogInfo(@"Enabled backgrounding on socket");
            else
                FWLogWarn(@"Enabling backgrounding failed!");
        }];
        }
#endif
    }
#endif
}

- (void)socketDidSecure:(FWAsyncSocket *)sock
{
    FWLogInfo(@"socketDidSecure:%p", sock);
    self.label.text = @"Connected + Secure";
    
    NSString *requestStr = [NSString stringWithFormat:@"GET / HTTP/1.1\r\nHost: %@\r\n\r\n", HOST];
    NSData *requestData = [requestStr dataUsingEncoding:NSUTF8StringEncoding];
    
    [sock writeData:requestData withTimeout:-1 tag:0];
    [sock readDataToData:[FWAsyncSocket CRLFData] withTimeout:-1 tag:0];
}

- (void)socket:(FWAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    FWLogInfo(@"socket:%p didWriteDataWithTag:%ld", sock, tag);
}

- (void)socket:(FWAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    FWLogInfo(@"socket:%p didReadData:withTag:%ld", sock, tag);
    
    NSString *httpResponse = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    FWLogInfo(@"HTTP Response:\n%@", httpResponse);
    
}

- (void)socketDidDisconnect:(FWAsyncSocket *)sock withError:(NSError *)err
{
    FWLogInfo(@"socketDidDisconnect:%p withError: %@", sock, err);
    self.label.text = @"Disconnected";
}

#pragma mark - OAuth2

- (void)testOAuth2
{
    self.label2.text = @"Sending...";
    NSURL *baseURL = [NSURL URLWithString:@"http://brentertainment.com/oauth2/"];
    FWOAuth2Manager *manager = [[FWOAuth2Manager alloc] initWithBaseURL:baseURL clientID:@"demoapp" secret:@"demopass"];
    manager.useHTTPBasicAuthentication = NO;
    FWWeakifySelf();
    [manager authenticateUsingOAuthWithURLString:@"lockdin/token" username:@"demouser" password:@"testpass" scope:nil success:^(FWOAuthCredential * _Nonnull credential) {
        FWStrongifySelf();
        self.label2.text = [credential description];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self testCredential];
        });
    } failure:^(NSError * _Nonnull error) {
        FWStrongifySelf();
        self.label2.text = error.localizedDescription;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self testCredential];
        });
    }];
}

- (void)testCredential
{
    NSString *identifier = @"FWOAuth2Credential";
    FWOAuthCredential *credential = [FWOAuthCredential retrieveCredentialWithIdentifier:identifier];
    NSString *credentialText = FWOAuthCredential.storeCredentialInKeychain ? @"Keychain Credential " : @"NSUserDefaults Credential ";
    if (credential) {
        self.label2.text = [credential description];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (![credential isExpired]) {
                self.label2.text = [credentialText stringByAppendingString:@"valid"];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    self.label2.text = [credential description];
                });
            } else {
                self.label2.text = [credentialText stringByAppendingString:@"expired"];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [FWOAuthCredential deleteCredentialWithIdentifier:identifier];
                    self.label2.text = [credentialText stringByAppendingString:@"deleted"];
                });
            }
        });
    } else {
        self.label2.text = [credentialText stringByAppendingString:@"empty"];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            FWOAuthCredential *credential = [[FWOAuthCredential alloc] initWithOAuthToken:@"oauth_token" tokenType:@"token_type"];
            [credential setRefreshToken:@"refresh_token" expiration:[NSDate dateWithTimeIntervalSince1970:NSDate.fwCurrentTime + 60]];
            [FWOAuthCredential storeCredential:credential withIdentifier:identifier];
            self.label2.text = [credentialText stringByAppendingString:@"stored"];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                FWOAuthCredential *credential = [FWOAuthCredential retrieveCredentialWithIdentifier:identifier];
                self.label2.text = [credential description];
            });
        });
    }
}

@end
