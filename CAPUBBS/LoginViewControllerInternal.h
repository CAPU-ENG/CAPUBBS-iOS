//
//  LoginViewControllerInternal.h
//  CAPUBBS
//
//  Created by 熊典 on 14-2-20.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
#import "ActionPerformer.h"

@interface LoginViewControllerInternal : UIViewController{
    MBProgressHUD *hud;
    ActionPerformer *performer;
}
@property (weak, nonatomic) IBOutlet UITextField *textUid;
@property (weak, nonatomic) IBOutlet UITextField *textPass;
- (IBAction)didEndOnExit:(id)sender;
- (IBAction)login:(id)sender;
- (IBAction)cancel:(id)sender;

@end
