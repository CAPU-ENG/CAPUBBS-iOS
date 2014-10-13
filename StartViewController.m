//
//  StartViewController.m
//  PKU Helper
//
//  Created by 熊典 on 14-2-11.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import "StartViewController.h"
#define is3_5inch ([[UIScreen mainScreen] bounds].size.height==480)
#define is4inch ([[UIScreen mainScreen] bounds].size.height==568)
#define isIpadLandscape ([[UIScreen mainScreen] bounds].size.height==1024&&UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation))
#define isIpadPortrait ([[UIScreen mainScreen] bounds].size.height==1024&&UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation))
@interface StartViewController ()

@end

@implementation StartViewController

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
    if (is3_5inch) {
        self.imageView.image=[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"LaunchImage-700@2x" ofType:@"png"]];
    }else if (is4inch){
        self.imageView.image=[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"LaunchImage-700-568h@2x" ofType:@"png"]];
    }else if (isIpadLandscape){
        self.imageView.image=[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"LaunchImage-700-Landscape@2x~ipad" ofType:@"png"]];
    }else if (isIpadPortrait) {
        self.imageView.image=[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"LaunchImage-700-Portrait@2x~ipad" ofType:@"png"]];
    }
    [self performSelector:@selector(showLogin) withObject:nil afterDelay:0.001];
//    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"uid"]){
//        [self performSelector:@selector(showMain) withObject:nil afterDelay:0.001];
//    }else{
//        [self performSelector:@selector(showLogin) withObject:nil afterDelay:0.001];
//    }
    // Do any additional setup after loading the view.
}
-(void)showMain{
    [self performSegueWithIdentifier:@"main" sender:nil];
}
-(void)showLogin{
    [self performSegueWithIdentifier:@"login" sender:nil];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
