//
//  ContentCell.h
//  CAPUBBS
//
//  Created by 熊典 on 14-2-17.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AsyncImageView.h"

@interface ContentCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *labelDate;
@property (weak, nonatomic) IBOutlet UILabel *labelAuthor;
@property (weak, nonatomic) IBOutlet UILabel *labelInfo;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicatorLoading;
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIButton *buttonAction;
@property (weak, nonatomic) IBOutlet UIButton *buttonLzl;
@property (weak, nonatomic) IBOutlet AsyncImageView *icon;
@property (weak, nonatomic) IBOutlet UIButton *buttonIcon;
@property (weak, nonatomic) IBOutlet UIView *topView;

@end
