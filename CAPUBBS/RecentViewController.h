//
//  RecentViewController.h
//  CAPUBBS
//
//  Created by 范志康 on 15/7/6.
//  Copyright (c) 2015年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AnimatedImageView.h"

@interface RecentViewController : CustomTableViewController {
    AnimatedImageView *backgroundView;
}

@property NSArray *data;
@property NSData *iconData;
@property NSString *iconUrl;

@end
