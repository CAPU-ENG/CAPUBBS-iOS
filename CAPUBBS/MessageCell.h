//
//  MessageCell.h
//  CAPUBBS
//
//  Created by 范志康 on 15/4/17.
//  Copyright (c) 2015年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AnimatedImageView.h"

@interface MessageCell : UITableViewCell
@property (weak, nonatomic) IBOutlet AnimatedImageView *imageIcon;
@property (weak, nonatomic) IBOutlet UIButton *buttonIcon;
@property (weak, nonatomic) IBOutlet UILabel *labelUser;
@property (weak, nonatomic) IBOutlet UILabel *labelMsgNum;
@property (weak, nonatomic) IBOutlet UILabel *labelText;
@property (weak, nonatomic) IBOutlet UILabel *labelTime;
@property (weak, nonatomic) IBOutlet UILabel *labelNum;

@end
