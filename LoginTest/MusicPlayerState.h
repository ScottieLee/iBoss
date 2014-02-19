//
//  MusicPlayerState.h
//  iBoss
//
//  Created by ScottLee on 14-2-19.
//  Copyright (c) 2014年 ScottLee. All rights reserved.

//  This is the model of MusicPlayer

#import <Foundation/Foundation.h>

typedef enum musicState{
    STOP,
    PAUSE,
    PLAY,
} musicState;
@interface MusicPlayerState : NSObject
@property (nonatomic) musicState playState;
@property (strong, nonatomic) NSString* songName;
@property (nonatomic) int32_t volume;

+ (MusicPlayerState*) sharedMusicPlayerState;
@end
