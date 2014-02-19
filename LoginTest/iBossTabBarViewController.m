//
//  iBossTabBarViewController.m
//  iBoss
//
//  Created by ScottLee on 14-1-29.
//  Copyright (c) 2014年 ScottLee. All rights reserved.
//

#import "iBossTabBarViewController.h"

@interface iBossTabBarViewController ()

@end

@implementation iBossTabBarViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // Hide back button
    [self.navigationItem setHidesBackButton:YES];
    
}
@end
