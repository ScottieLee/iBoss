//
//  CodeDef.h
//  iBoss
//
//  Created by ScottLee on 14-1-27.
//  Copyright (c) 2014年 ScottLee. All rights reserved.
//

#ifndef iBoss_CodeDef_h
#define iBoss_CodeDef_h

/* -------------------- Frame format between iPhone and ServerPC---------------------
 
 
 -------------------------------------------------
 PC2Phone | Phone2PC | Identity | Data ....
 -------------------------------------------------
 1Byte     1Byte     2 Bytes
 
 max length of Frame is 1024 Bytes
 
 
 Authorize Procedure:
 
 Server                    iPhone
 AUT
 <------------------
 
 ACC  /  REJ
 ------------------>
 ACC contains Identity
 
 Request Music List
 
 Server                     iPhone
 MLR
 <------------------  Request for root music list
 
 MLR_ACK
 ------------------>  Send the music list to iPhone
 
 MLF
 <------------------  Request for music list recursively
 
 MLB
 <------------------  Request for Back track
 ML_ACK
 ------------------>  Send the music list to iPhone
 
 
 
 MLR Frame Format:   | CODENONE| MUSICLIST_REQUEST | None |
 
 MLR_ACK             | MUSICLIST_ACK | CODENONE | numberOfFolder | Folder1Name | Folder2Name | ... | numberOfMusic | Song1Name | Song2Name | ...|
 4 Bytes         32 Bytes      32 Bytes             4 Bytes       32 Bytes    32 Bytes
 
 MLF Frame Format:   | CODENONE | MUSICLIST_FORWARD | IdentityCode | IndexOfFolder |
 
 MLB Frame Format:   | CODENONE | MUSICLIST_BACK | None |
 
 
 Request Playing music
 
 MP Frame Format:   | CODENONE | MUSIC_PLAY | IdentityCode | IndexOfFolder |
 
 */

#define DATA_OFFSET 4
#define CODENONE 0xff

// PC to iPhone CODES
#define AUTHORIZE_ACCEPTED 0x01
#define AUTHORIZE_REJECTED 0x02
#define MUSICLIST_ACK      0x04 // Send the music list to iPhone

// iPhone to PC CODES
#define AUTHORIZE_REQUEST 0x01
#define MUSICLIST_REQUEST 0x02 // Request for root MusicList
#define MUSICLIST_FORWARD 0x04
#define MUSICLIST_BACK    0x08 // Request for Back track
#define MUSIC_PLAY		  0x10 // Request for playing music with index
#define MUSIC_PAUSE		  0x12 // Request for pause the music
#define MUSIC_RESUME	  0x14
#define MUSIC_VOLUME	  0x16 // Request for setting the volume with integer

#define SHUTDOWN_NOW	  0x32 // Request for shut down the computer now

#endif

