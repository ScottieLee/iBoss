//
//  LoginTestViewController.m
//  LoginTest
//
//  Created by ScottLee on 14-1-27.
//  Copyright (c) 2014年 ScottLee. All rights reserved.
//

#import "LoginViewController.h"
#import "NetworkStream.h"
#import "CodeDef.h"


@interface LoginViewController ()
@property (weak, nonatomic) IBOutlet UIButton *conntectButton;
@property (weak, nonatomic) IBOutlet UITextField *keyTextField;
@property (nonatomic, strong) AsyncSocket* socket;
@property (nonatomic, strong) NetworkStream* stream;
@property (nonatomic, strong) UIActivityIndicatorView* activityView;
@property (weak, nonatomic) IBOutlet UILabel *appVersionLabel;
@end

@implementation LoginViewController

// --------------- IBActions ---------------------
- (IBAction)KeyEditEnd:(UITextField *)sender {
    // If key is input, enable the connectButton
    if ([self.keyTextField.text length] > 0) {
        [self.conntectButton setEnabled:YES];
    }
}


// When back ground of Login UI is touched, close the keyboard if it's open.
- (IBAction)BackGroundTouched:(id)sender {
    [self.keyTextField resignFirstResponder]; //This is a simple way to hide keyboard
}

- (IBAction)ConnectButtonPressed:(UIButton*)sender {
    //First try to connect with the server
    NSLog(@"Button Action");
    if (!self.socket) {
        self.stream = [NetworkStream sharedSocketWithServerIP:@SERVER_IP andPort:@PORT];
        self.socket = self.stream.sharedSocket; // Call the sharedSocket getter, this is a lazy initialization
        [self.stream setDelegate:self]; // self is the delegate of networkstream
    } else {
        [self connectionDone];
    }
    
    // Make a Busy indicate:
    self.activityView=[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.activityView.color = [UIColor blackColor];
    self.activityView.center= self.view.center;
    [self.activityView startAnimating];
    [self.view addSubview:self.activityView];
    
    // Disable connectButton
    [self.conntectButton setEnabled:NO];
    

}

//---------------             ----------------------
// Callback Function Implementation
- (void) connectionError
{
    // If connection error, Dismiss busy indicator and endable connect button
    [self.activityView removeFromSuperview];
    [self.conntectButton setEnabled:YES];
    
    NSLog(@"Running connection Error");
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connection Error"
                                                    message:@"Server not found."
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    self.socket = nil;
}

- (void) connectionDone
{
    // Connected to server, send KEY to authorize
    char code[DATA_OFFSET] = {CODENONE, AUTHORIZE_REQUEST, 0x00, 0x00};
    NSMutableData* data = [NSMutableData dataWithBytes:&code length:DATA_OFFSET];
    NSLog(@"Send key for authorizing");
    NSString* key = self.keyTextField.text;
    self.stream.loginKey = key;
    [data appendData:[key dataUsingEncoding:NSUTF8StringEncoding]];
    [self.socket writeData: data withTimeout:2 tag:1];
    [self.socket readDataWithTimeout:-1 tag:0];
}

- (void) KeyAccepted
{
    // Key accepted by server, Remove busy indicator and enter the main view
    NSLog(@"Key Accepted");
    [self.activityView removeFromSuperview];
    [self performSegueWithIdentifier:@"JumptoMainView" sender:self];
}

- (void) KeyRejected
{
    // Key rejected by server, Remove busy indicator and endable connect button
    [self.activityView removeFromSuperview];
    [self.conntectButton setEnabled:YES];
    NSLog(@"Key rejected.");
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Authorize Failed"
                                                    message:@"Key is rejected."
                                                   delegate: nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles: nil];
    [alert show];
}

// ------------------- Life Cycles ----------------------------

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Make RoundRectButton
    CALayer *btnLayer = [self.conntectButton layer];
    [btnLayer setMasksToBounds:YES];
    [btnLayer setCornerRadius:5.0f];
    // Make button disable cuz KeyTextfield is empty
    [self.conntectButton setEnabled:NO];
    
    // Set navigationbar color and its text color
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:(85/255.0) green:(139/255.0) blue:(234/255.0) alpha:1];
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}];
    
    // Set the version of APP
    [self.appVersionLabel setText:[NSString stringWithFormat:@"Version: %@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]]];
    
    
    [UIApplication sharedApplication].idleTimerDisabled = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
