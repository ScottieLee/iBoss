//
//  NetworkStream.h
//  iBoss
//
//  Created by ScottLee on 14-1-27.
//  Copyright (c) 2014年 ScottLee. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AsyncSocket.h"

enum netState {
    ERROR = 0,
    RECEIVE = 1,
    CLOSED = 2,
    OPEN = 3
};

@interface NetworkStream : NSObject <NSStreamDelegate>

@property (nonatomic, strong) NSInputStream *inputStream;

@property (nonatomic, strong) NSOutputStream *outputStream;

@property (nonatomic, strong) NSMutableData* receivedData;

@property (nonatomic) enum netState state;


+ (NetworkStream *) sharedNetworkStreamWithServerIP:(NSString*) serverIp andPort: (NSString*) port;- (int) sendData:(NSMutableData*) data;

@end

@interface NSObject (NetworkStreamDelegation)

// Callback functions for NetworkStream
//Implement these in upper layer like view controller
- (void) connectionAccepted;
- (void) connectionRejected;
- (void) connectionError;

@end

