//
//  ContentCell.h
//  CAPUBBS
//
//  Created by 熊典 on 14-2-17.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AnimatedImageView.h"
#import "CustomWebViewContainer.h"

@interface ContentCell : UITableViewCell <UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UILabel *labelDate;
@property (weak, nonatomic) IBOutlet UILabel *labelAuthor;
@property (weak, nonatomic) IBOutlet UILabel *labelInfo;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicatorLoading;
@property (weak, nonatomic) IBOutlet CustomWebViewContainer *webViewContainer;
@property (weak, nonatomic) IBOutlet UIButton *buttonAction;
@property (weak, nonatomic) IBOutlet UIButton *buttonLzl;
@property (weak, nonatomic) IBOutlet AnimatedImageView *icon;
@property (weak, nonatomic) IBOutlet UIButton *buttonIcon;
@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet UITableView *lzlTableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *webviewBottomSpacing;

@property (strong, nonatomic) NSTimer *webviewUpdateTimer;
@property (strong, nonatomic) NSArray *lzlDetail;

@end

@interface ContentLzlCell : UITableViewCell

@property (weak, nonatomic) IBOutlet AnimatedImageView *lzlIcon;
@property (weak, nonatomic) IBOutlet UILabel *lzlAuthor;
@property (weak, nonatomic) IBOutlet UILabel *lzlTime;
@property (weak, nonatomic) IBOutlet UILabel *lzlText;

@end
