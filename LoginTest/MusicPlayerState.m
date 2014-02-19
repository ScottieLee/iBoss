//
//  MusicPlayerState.m
//  iBoss
//
//  Created by ScottLee on 14-2-19.
//  Copyright (c) 2014年 ScottLee. All rights reserved.
//

#import "MusicPlayerState.h"

@implementation MusicPlayerState

//Singleton

static MusicPlayerState* musicPlayerStateInstance = nil;
- (id) init
{
    if (self = [super init]){
        _playState = STOP;
        _songName = @"";
        _volume = 25;
    }
    return self;
}

+ (MusicPlayerState*) sharedMusicPlayerState
{
    @synchronized(self){
        if (!musicPlayerStateInstance) {
            musicPlayerStateInstance = [[MusicPlayerState alloc] init];
        }
    }
    return musicPlayerStateInstance;
}

@end
