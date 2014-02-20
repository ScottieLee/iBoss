//
//  NetworkStream.m
//  iBoss
//
//  Created by ScottLee on 14-1-27.
//  Copyright (c) 2014年 ScottLee. All rights reserved.
//

#import "NetworkStream.h"
#import "CodeDef.h"

@interface NetworkStream ()

- (void) dataRouter: (NSData*) receivedData; // Handler for all the receive events
//- (void) closeStreams;

@end

@implementation NetworkStream

static NetworkStream* netWorkStreamInstance = nil;


// Singleton // Return nil if connection failed.
+ (NetworkStream *) sharedSocketWithServerIP:(NSString *)serverIp andPort:(NSString *)port
{
    
    @synchronized(self)
    {
        if (netWorkStreamInstance == nil)
        {
            netWorkStreamInstance = [[NetworkStream alloc] initWithServerIP:serverIp andPort: port];
        }
    }
    return netWorkStreamInstance;
}

- (id) initWithServerIP:(NSString *)serverIp andPort:(NSString *)port
{
    if (self = [super init]) {
        self.serverIP = serverIp;
        self.serverPort = (UInt16)[port intValue];
    }
    return self;
}

- (AsyncSocket*) sharedSocket
{
    if (_sharedSocket == nil) {
        _sharedSocket = [[AsyncSocket alloc] initWithDelegate:self];
        NSError* err = nil;
        NSLog(@"Server IP is %@, port is %d", self.serverIP, self.serverPort);
        if (![_sharedSocket connectToHost:self.serverIP onPort:self.serverPort withTimeout:2 error:&err]) {
            NSLog(@"NetworkStream::sharedSocket::Error!: %@", err);
        }
        
    }
    return _sharedSocket;
}

// Utils
- (void) dataRouter:(NSData *)receivedData
{
    NSRange codeRange = {0, 1};
    char* code = (char*)[[receivedData subdataWithRange:codeRange] bytes];
    switch (code[0]) {
        case AUTHORIZE_ACCEPTED:
        {
            // Get Indentity Code
            NSRange identityCodeRange = {2, 2};
            self.receivedIdentityCode = *((short*) [[receivedData subdataWithRange:identityCodeRange] bytes]);
            NSLog(@"identity code is %d", self.receivedIdentityCode);
            [_delegate KeyAccepted];
            break;
        }
        case AUTHORIZE_REJECTED:
        {
            [_delegate KeyRejected];
            break;
        }
        case MUSICLIST_ACK:
        {
            [_delegate getMusicList:receivedData];
            break;
        }
        default:
            break;
    }
    
}


// AsyncSocket Delegate Methods Implemetation

- (void) setDelegate:(id)delegate
{
    _delegate = delegate;
}
- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err {
    NSLog(@"Disconnecting. Error: %@", [err localizedDescription]);
    [_sharedSocket setDelegate:nil];
    _sharedSocket = nil;
    [_delegate connectionError];
}

- (void)onSocketDidDisconnect:(AsyncSocket *)sock {
    NSLog(@"Disconnected.");
    
    [_sharedSocket setDelegate:nil];
    _sharedSocket = nil;
}

- (BOOL)onSocketWillConnect:(AsyncSocket *)sock {
    NSLog(@"onSocketWillConnect");
    return YES;
}

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port {
    NSLog(@"Connected To %@:%i.", host, port);
    [_delegate connectionDone];
}

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    [self dataRouter:data];
    NSLog(@"Received Data with len %d", [data length]);
}

- (void)onSocket:(AsyncSocket *)sock didReadPartialDataOfLength:(CFIndex)partialLength tag:(long)tag {
    NSLog(@"onSocket:didReadPartialDataOfLength:%li tag:%li", partialLength, tag);
}

- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag {
    NSLog(@"onSocket:didWriteDataWithTag:%li", tag);
}



@end