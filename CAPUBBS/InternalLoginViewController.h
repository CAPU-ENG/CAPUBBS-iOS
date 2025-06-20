//
//  InternalLoginViewController.h
//  CAPUBBS
//
//  Created by 熊典 on 14-2-20.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InternalLoginViewController : CustomViewController {
    MBProgressHUD *hud;
    BOOL shouldPop;
}

@property NSString *defaultUid;
@property NSString *defaultPass;
@property (weak, nonatomic) IBOutlet UITextField *textUid;
@property (weak, nonatomic) IBOutlet UITextField *textPass;
@property (weak, nonatomic) IBOutlet UIButton *buttonLogin;

@end
