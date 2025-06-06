//
//  IDViewController.h
//  CAPUBBS
//
//  Created by 范志康 on 15/3/11.
//  Copyright (c) 2015年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "InternalLoginViewController.h"

@interface IDViewController : CustomTableViewController {
    ActionPerformer *performer;
    NSMutableArray *data;
    BOOL isDelete;
}

@property (strong, nonatomic) IBOutlet UIBarButtonItem *buttonLogin;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *buttonLogout;

@end
