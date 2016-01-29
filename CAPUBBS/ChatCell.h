//
//  ChatCell.h
//  CAPUBBS
//
//  Created by 范志康 on 15/4/17.
//  Copyright (c) 2015年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AsyncImageView.h"

@interface ChatCell : UITableViewCell
@property (weak, nonatomic) IBOutlet AsyncImageView *imageIcon;
@property (weak, nonatomic) IBOutlet UIButton *buttonIcon;
@property (weak, nonatomic) IBOutlet UIImageView *imageChat;
@property (weak, nonatomic) IBOutlet UITextView *textMessage;
@property (weak, nonatomic) IBOutlet UILabel *labelTime;
@property (weak, nonatomic) IBOutlet UITextView *textSend;

@end
