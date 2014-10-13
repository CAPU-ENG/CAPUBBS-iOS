//
//  IndexViewController.h
//  CAPUBBS
//
//  Created by 熊典 on 14-2-16.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ActionPerformer.h"

@interface IndexViewController : UITableViewController{
    NSArray *data;
    NSArray *numbers;
    ActionPerformer *performer;
}

@end
