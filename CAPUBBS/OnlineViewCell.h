//
//  OnlineViewCell.h
//  CAPUBBS
//
//  Created by 范志康 on 15/5/14.
//  Copyright (c) 2015年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OnlineViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *labelUser;
@property (weak, nonatomic) IBOutlet UILabel *labelTime;
@property (weak, nonatomic) IBOutlet UILabel *labelBoard;
@property (weak, nonatomic) IBOutlet UILabel *labelType;

@end
