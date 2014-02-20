//
//  MusicViewController.m
//  iBoss
//
//  Created by ScottLee on 14-1-29.
//  Copyright (c) 2014年 ScottLee. All rights reserved.
//

#import "MusicViewController.h"
#import "AsyncSocket.h"
#import "NetworkStream.h"
#import "CodeDef.h"
#import "MusicPlayerState.h"


@interface MusicViewController ()
@property (nonatomic, strong) UIActivityIndicatorView* activityView;
@property (nonatomic, strong) AsyncSocket* socket;
@property (nonatomic, strong) NetworkStream* networkStream;

@property (weak, nonatomic) IBOutlet UIView *playView;

@property (weak, nonatomic) IBOutlet UITableView *musicTableView;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UISlider *volumeSlider;
@property (nonatomic) MusicPlayerState* playerState; // Model of Music Player, point to a shared instance
@property (weak, nonatomic) IBOutlet UILabel *songNameLabel;

@property (strong, nonatomic) NSArray* musicList;
- (NSArray*) parseMusicListData: (NSData*) data;
- (void)applicationDidBecomeActive:(NSNotificationCenter*) notification;
@end

@implementation MusicViewController

- (IBAction)volumeChanged:(UISlider *)sender {
    // send volume code to server
    char MV[DATA_OFFSET + sizeof(int32_t)] = {CODENONE, MUSIC_VOLUME, 0x00, 0x00};
    short identy = self.networkStream.receivedIdentityCode;
    memcpy(MV + 2, &identy, sizeof(short));
    int volume = sender.value;
    memcpy(MV + 4, &volume, sizeof(int32_t));
    [self.socket writeData:[NSData dataWithBytes:MV length:DATA_OFFSET + sizeof(int32_t)] withTimeout:2 tag:1];
    
    // Change the model of musicplayer
    self.playerState.volume = volume;
}


- (IBAction)playButtonPressed:(UIButton *)sender {
    if (!sender.selected) { // Let it play
        
        // send play code to server
        char MR[DATA_OFFSET] = {CODENONE, MUSIC_RESUME, 0x00, 0x00};
        short identy = self.networkStream.receivedIdentityCode;
        memcpy(MR + 2, &identy, sizeof(short));
        [self.socket writeData:[NSData dataWithBytes:MR length:DATA_OFFSET] withTimeout:2 tag:1];
        
        // Make the button selected
        [sender setSelected:YES];
        self.playerState.playState= PLAY;
        NSLog(@"Make playing");
    } else { // Let it pause
        
        // send pause code to server
        char MPA[DATA_OFFSET] = {CODENONE, MUSIC_PAUSE, 0x00, 0x00};
        short identy = self.networkStream.receivedIdentityCode;
        memcpy(MPA + 2, &identy, sizeof(short));
        [self.socket writeData:[NSData dataWithBytes:MPA length:DATA_OFFSET] withTimeout:2 tag:1];
        
        // Make the button not selected
        [sender setSelected:NO];
        self.playerState.playState = PAUSE;
        NSLog(@"Make pause");
    }
}


//- (id)initWithStyle:(UITableViewStyle)style
//{
//    self = [super initWithStyle:style];
//    if (self) {
//        // Custom initialization
//    }
//    return self;
//}


// This method is called when screen is locked or app goes background
- (void) applicationDidEnterBackground: (NSNotificationCenter*) notification
{
    NSLog(@"Become background");
    self.socket = nil;
    [self.socket readDataWithTimeout:-1 tag:0];
}

// This method is called when screen is unlocked or app goes foreground
- (void)applicationDidBecomeActive:(NSNotificationCenter*) notification
{
    //[self.socket readDataWithTimeout:-1 tag:0];
    NSLog(@"BecomeActive");
    self.socket = self.networkStream.sharedSocket; // Call the sharedSocket getter, this is a lazy initialization
    
    // Kind of a trick. Send a dummy data ,if disconnected, let app know its not connected and invoke connection error. Connection error will reconnect. else if its still connected, the server receives the CODENONE and just does nothing.
    char dummyBytes[4] = { CODENONE, CODENONE, CODENONE, CODENONE};
    NSData* dummyData = [NSData dataWithBytes:&dummyBytes length:4];
    [self.socket writeData:dummyData withTimeout:-1 tag:0];

}

- (void) connectionError; // Failed to connect to socket server, reconnect
{
    self.socket = self.networkStream.sharedSocket; // Call the sharedSocket getter, this is a lazy initialization
}

// Delegation method for the networkstream
- (void) connectionDone
{
    // Connected to server, send KEY to authorize
    char code[DATA_OFFSET] = {CODENONE, AUTHORIZE_REQUEST, 0x00, 0x00};
    NSMutableData* data = [NSMutableData dataWithBytes:&code length:DATA_OFFSET];
    NSLog(@"Send key for authorizing");
    NSString* key = self.networkStream.loginKey;
    [data appendData:[key dataUsingEncoding:NSUTF8StringEncoding]];
    [self.socket writeData: data withTimeout:2 tag:1];
    [self.socket readDataWithTimeout:-1 tag:0];
}
- (void) KeyAccepted
{
    NSLog(@"Key Accepted");
}


// LifeCycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // First set delegate
    // What does delegate here mean? uitableview class has a delegate and datasource delegate, and the two delegates will call callback functions, so we pass the delegate instance here. Since the MusicTableViewController follows the tableview protocol, we can rewrite the callback functions
    self.musicTableView.delegate = self;
    self.musicTableView.dataSource = self;
    
    // Then reload data everytime ?
    [self.musicTableView reloadData];
    
    // Get musicPlayerState Instance
    self.playerState = [MusicPlayerState sharedMusicPlayerState];
    
    // This is handling the issue of network disconnect when locking the screen
    // Regist to the NotificationCenter with name UIApplicationDidBecomeActiveNotification and the handling method
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    [center addObserver:self
               selector:@selector(applicationDidBecomeActive:)
                   name:UIApplicationDidBecomeActiveNotification
                 object:nil];
    [center addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
}


- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // Handling music playing state before view appear
    if (self.playerState.playState == PLAY){
        NSLog(@"Playing");
        [self.playButton setEnabled:YES];
        [self.playButton setSelected:YES];
    } else if (self.playerState.playState == PAUSE){
        [self.playButton setEnabled:YES];
    }
    // Change the volume view according to the model
    self.volumeSlider.value = self.playerState.volume;
    // Display the song name:
    self.songNameLabel.text = self.playerState.songName;
}

- (void) viewDidAppear:(BOOL)animated
{
    
    // Make a busy indicator
    self.activityView=[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.activityView.color = [UIColor blackColor];
    self.activityView.center= self.view.center;
    [self.activityView startAnimating];
    [self.view addSubview:self.activityView];
    
    // Get shared socket
    self.networkStream = [NetworkStream sharedSocketWithServerIP:@SERVER_IP andPort:@PORT];
    self.socket = self.networkStream.sharedSocket;
    
    // Change the delegate of networkStream to this instance!!!
    [self.networkStream setDelegate:self];
    
    //Send music list Request
    char MLR[DATA_OFFSET] = {CODENONE, MUSICLIST_REQUEST, 0x00, 0x00};
    short identy = self.networkStream.receivedIdentityCode;
    memcpy(MLR + 2, &identy, sizeof(short));
    [self.socket writeData:[NSData dataWithBytes:MLR length:DATA_OFFSET] withTimeout:2 tag:1];
    
    // Enable receive
    [self.socket readDataWithTimeout:5 tag:0]; //FIXME
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


// Delegation for networkstream implementation
- (void)getMusicList:(NSData *)receivedData
{
    NSRange dataRange = {DATA_OFFSET, [receivedData length] - DATA_OFFSET};
    self.musicList = [self parseMusicListData:[receivedData subdataWithRange:dataRange]];
    //NSLog(@"Get music list!");
    
    [self.activityView removeFromSuperview];
    
    // This is important cuz callbacks of tableview could run before here, so reload data to call callbacks again.
    [self.musicTableView reloadData];
}


- (void)didMoveToParentViewController:(UIViewController *)parent
{
    //If back button pressed
    if (![parent isEqual:self.parentViewController]) {
        NSLog(@"Back pressed");
        // back button pressed, should back track the music list
        char MLB[DATA_OFFSET] = {CODENONE, MUSICLIST_BACK, 0x00, 0x00};
        short identy = self.networkStream.receivedIdentityCode;
        memcpy(MLB + 2, &identy, sizeof(short));
        [self.socket writeData:[NSData dataWithBytes:MLB length:DATA_OFFSET] withTimeout:2 tag:1];
        
    }
}



// Utils

/*  parseMusicListData
        pass in pure data of music list, parse it and return an array:
 
        |  NSArray of Strings of folders | NSArray of Strings of songs |
 */
- (NSArray*) parseMusicListData:(NSData *)data
{
    NSRange numberOfFoldersRange = {0, 4};
    int* numberOfFoldersPtr = (int*)[[data subdataWithRange:numberOfFoldersRange] bytes];
    //NSLog(@"The number of folder is %d", *numberOfFoldersPtr);
    NSMutableArray* musicFolderArray = [[NSMutableArray alloc] init];
    NSRange folderCStringRange = {4, 32};
    for(int i = 0; i < *numberOfFoldersPtr; i++){
        char* folderCString = (char*)[[data subdataWithRange:folderCStringRange] bytes];
        NSString* musicFolder = [NSString stringWithUTF8String:folderCString];
        //NSLog(@"The folder name is %@", musicFolder);
        if (musicFolder == nil) {
            [musicFolderArray addObject:@"[Not Recognized!]"];
        } else {
            [musicFolderArray addObject:musicFolder];
        }
        folderCStringRange.location += 32;
    }
    NSRange numberOfSongsRange = {4 + 32 * (*numberOfFoldersPtr), 4};
    int* numberOfSongsPtr = (int*)[[data subdataWithRange:numberOfSongsRange] bytes];
    NSMutableArray* songArray = [[NSMutableArray alloc] init];
    NSRange songCStringRange = {8 + 32* (*numberOfFoldersPtr), 32};
    //NSLog(@"The number of song is %d", *numberOfSongsPtr);
    for (int i = 0; i < *numberOfSongsPtr; i++) {
        char* songCString = (char*)[[data subdataWithRange:songCStringRange] bytes];
        NSString* song = [NSString stringWithUTF8String:songCString];
        //NSLog(@"The music name is %@", song);
        if (song == nil) {
            [songArray addObject:@"[Not Recognized!]"];
        } else {
            [songArray addObject:song];
        }
        songCStringRange.location += 32;
    }
    
    NSArray* result = @[musicFolderArray, songArray];
    return result;
}

#pragma mark - Table view data source


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    switch (section) {
        case 0:
            return @"Music Folders";
        case 1:
            return @"Songs";
        default:
            return nil;
    }
}

// set Table Header UI
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    UILabel *myLabel = [[UILabel alloc] init];
    myLabel.frame = CGRectMake(0, 0, 320, 40);
    myLabel.backgroundColor = [UIColor colorWithRed:(100/255.0)
                                              green:(149/255.0)
                                               blue:(237/255.0)
                                              alpha:0.8];
    myLabel.font = [UIFont boldSystemFontOfSize:18];
    myLabel.textColor = [UIColor whiteColor];
    myLabel.text = [self tableView:tableView titleForHeaderInSection:section];
    
    UIView *headerView = [[UIView alloc] init];
    [headerView addSubview:myLabel];
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 40;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return [self.musicList[0] count];
        case 1:
            return [self.musicList[1] count];
        default:
            break;
    }
    return 0;
}


- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0:
        {
            //music list forward recursively
            char MLF[DATA_OFFSET + sizeof(int32_t)] = {CODENONE, MUSICLIST_FORWARD, 0x00, 0x00};
            short identy = self.networkStream.receivedIdentityCode;
            memcpy(MLF + 2, &identy, sizeof(short));
            int32_t row = (int32_t)indexPath.row;
            
            memcpy(MLF + 4, &row, sizeof(int32_t));
            [self.socket writeData:[NSData dataWithBytes:MLF length:DATA_OFFSET + sizeof(int32_t)] withTimeout:2 tag:1];
            [self performSegueWithIdentifier:@"MusicFolderDetail" sender:self];
            break;
        }
        case 1:
        {
            //music play
            char MP[DATA_OFFSET + sizeof(int32_t)] = {CODENONE, MUSIC_PLAY, 0x00, 0x00};
            short identy = self.networkStream.receivedIdentityCode;
            memcpy(MP + 2, &identy, sizeof(short));
            
            int32_t index = (int32_t)indexPath.row;
            memcpy(MP + 4, &index, sizeof(int32_t));
            [self.socket writeData:[NSData dataWithBytes:MP length:DATA_OFFSET + sizeof(int32_t)] withTimeout:2 tag:1];
            NSLog(@"Write data");
            // set the playbutton to enabled and selected
            [self.playButton setEnabled:YES];
            [self.playButton setSelected:YES];
            // change the music play model:
            self.playerState.playState = PLAY;
            self.playerState.songName = self.musicList[1][index];
            // display the song name on the label now
            self.songNameLabel.text = self.playerState.songName;
            break;
        }

        default:
            break;
    }
}



-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    // This is important!!!
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle: UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
    cell.textLabel.text = [self.musicList[indexPath.section] objectAtIndex:indexPath.row];
    cell.textLabel.textColor = [UIColor colorWithRed:(72/255.0) green:(61/255.0) blue:(139/255.0) alpha:1];

    //cell.detailTextLabel.text = @"Detail";
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation


 */

@end
