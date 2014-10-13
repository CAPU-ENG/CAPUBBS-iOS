//
//  LzlViewController.h
//  CAPUBBS
//
//  Created by XiongDian on 14/9/21.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ActionPerformer.h"
#import "MBProgressHUD.h"

@interface LzlViewController : UITableViewController<UIAlertViewDelegate>{
    ActionPerformer *performer;
    NSArray *data;
    MBProgressHUD *hud;
}

@property NSString *fid;
@end
