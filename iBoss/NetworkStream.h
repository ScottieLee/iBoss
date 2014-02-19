//
//  NetworkStream.h
//  iBoss
//
//  Created by ScottLee on 14-1-27.
//  Copyright (c) 2014年 ScottLee. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AsyncSocket.h"

#define SERVER_IP "192.168.1.2"
#define PORT "2048"

@interface NetworkStream : NSObject <NSStreamDelegate>
{
    id _delegate; // The upper layer instance
}

@property (nonatomic, strong) NSMutableData* receivedData;
@property (nonatomic, strong) AsyncSocket* sharedSocket;
@property (nonatomic, strong) NSString* serverIP;
@property (nonatomic) short receivedIdentityCode;
@property (nonatomic) UInt16 serverPort;
@property (strong, nonatomic) NSString* loginKey;

+ (NetworkStream *) sharedSocketWithServerIP:(NSString*) serverIp andPort: (NSString*) port;
//- (int) sendData:(NSMutableData*) data;

- (void)setDelegate:(id)delegate;
@end

// This is an simple delegation using NSObject and category

@interface NSObject (NetworkStreamDelegation)

// Callback functions for NetworkStream
//Implement these in upper layer like view controller
- (void) KeyAccepted; // Authorized
- (void) KeyRejected; // Failed to authorize
- (void) connectionError; // Failed to connect to socket server
- (void) connectionDone;  // Connected to socket server
- (void) getMusicList:(NSData*) receivedData; // Get music list from server

@end

