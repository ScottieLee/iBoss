//
//  NetworkStream.m
//  iBoss
//
//  Created by ScottLee on 14-1-27.
//  Copyright (c) 2014年 ScottLee. All rights reserved.
//

#import "NetworkStream.h"
#import "CodeDef.h"
// Network related stuffs
#include <sys/socket.h>
#include <netinet/in.h>

@interface NetworkStream ()

- (id) initWithServerIP:(NSString*) serverIp andPort: (NSString*) port;
- (void) receiveEventsHandler: (NSMutableData*) receivedData; // Handler for all the receive events
- (void) closeStreams;

@end



@implementation NetworkStream

static NetworkStream* sharedNetworkStream = nil;


// Singleton Create
+ (NetworkStream *) sharedNetworkStreamWithServerIP:(NSString *)serverIp andPort:(NSString *)port
{
    
    @synchronized(self)
    {
        if (sharedNetworkStream == nil)
        {
            sharedNetworkStream = [[NetworkStream alloc] initWithServerIP:serverIp andPort:port];
            NSLog(@"Initializing!");
        }
    }
    return sharedNetworkStream;
}


- (id) initWithServerIP:(NSString *)serverIp andPort:(NSString *)port
{
    if (self = [super init]) {
        self.state = CLOSED;
        NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@:%@", serverIp, port]];
        [self loadDataFromServerWithURL:url];
        return self;
    } else
        return nil;
}

- (void)loadDataFromServerWithURL:(NSURL *)url
{
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;

    CFStreamCreatePairWithSocketToHost(NULL,(__bridge CFStringRef)[url host], [[url port] unsignedIntValue], &readStream, &writeStream);
    
    if(!CFWriteStreamOpen(writeStream)) {
		NSLog(@"Error, writeStream not open");
		
		return;
	}
    
    _inputStream = (__bridge_transfer NSInputStream *)readStream; // set data member
    _outputStream = (__bridge_transfer NSOutputStream*)writeStream; // set data member
    

    //NSStreamStatus status1 = [self.inputStream streamStatus];
    NSError* error = [self.inputStream streamError];
    assert(error == nil);
    
    [_inputStream setDelegate:self]; // set delegate
    [_outputStream setDelegate:self]; // set delegate
    
    [_inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
                            forMode:NSDefaultRunLoopMode];
    [_outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
                             forMode:NSDefaultRunLoopMode];
    
    [_inputStream open];
    [_outputStream open];
    NSLog(@"Streams are open");
}

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode {
    NSString* direction = (stream == self.inputStream)?@"PC2Phone": @"Phone2PC";
    
    switch(eventCode) {
            
        // Get data from server
        case NSStreamEventHasBytesAvailable:
        {
            NSLog(@"Has Bytes %@", direction);
            self.state = RECEIVE;
            if(!_receivedData) {
                _receivedData = [NSMutableData data];
            }
            uint8_t buf[1024];
            unsigned int len = 0;
            len = [(NSInputStream *)stream read:buf maxLength:1024];
            if(len) {
                [_receivedData appendBytes:(const void *)buf length:len];
                // Handler for all the receive events
                [self receiveEventsHandler:[self receivedData]];
            } else {
                NSLog(@"No buffer!");
            }
            break;
        }
        
        case NSStreamEventEndEncountered:// Connection is end
        {
            NSLog(@"EventEndEncountered %@", direction);
            self.state = CLOSED;
            [self closeStreams];
            break;
        }
        case NSStreamEventErrorOccurred:// Connection Error
        {
            NSLog(@"EventErrorOccurred %@", direction);
            self.state = ERROR;
            [self connectionError];
            [self closeStreams];
            break;
        }
        case NSStreamEventOpenCompleted:
        {
            NSLog(@"EventOpenCompleted %@", direction);
            self.state = OPEN;
            break;
        }
        case NSStreamEventHasSpaceAvailable:
        {
            NSLog(@"EventHasSpaceAvailable %@", direction);
            self.state = OPEN;
            break;
        }
        case NSStreamEventNone:
        {
            NSLog(@"NSStreamEventNone %@", direction);
            self.state = OPEN;
        }
        default:
            break;
            
    }
}

- (void) receiveEventsHandler: (NSMutableData*) receivedData
{
    // Get CODE
    NSRange codeRange;
    codeRange.location = 1;
    codeRange.length = 1;
    NSData* codeNSData = [receivedData subdataWithRange:codeRange];
    char code;
    [codeNSData getBytes:&code];
    
    switch (code) {
        case CONNECTION_ACCEPTED:
        {
            [self connectionAccepted];
            break;
        }
        case CONNECTION_REJECTED:
        {
            [self connectionRejected];
            break;
        }
        default:
            break;
    }
    
}

- (int) sendData:(NSMutableData *)data
{
    if (self.inputStream == nil || self.outputStream == nil) {
        return -1;
    } else
    {
        int bytesSent = 0;
        if ([self.outputStream hasSpaceAvailable]) {
            bytesSent = [self.outputStream write:[data bytes] maxLength:1024];
            return bytesSent;
        } else
            return -1;
    }
}

- (void) closeStreams
{
    [self.inputStream close];
    [self.outputStream close];
    [self.inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.inputStream setDelegate:nil];
    [self.outputStream setDelegate:nil];
}

@end
