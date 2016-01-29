//
//  LzlCell.h
//  CAPUBBS
//
//  Created by XiongDian on 14/9/21.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AsyncImageView.h"

@interface LzlCell : UITableViewCell
@property (weak, nonatomic) IBOutlet AsyncImageView *icon;
@property (weak, nonatomic) IBOutlet UIButton *buttonIcon;
@property (weak, nonatomic) IBOutlet UIImageView *imageBottom;
@property (weak, nonatomic) IBOutlet UILabel *textAuthor;
@property (weak, nonatomic) IBOutlet UILabel *textTime;
@property (weak, nonatomic) IBOutlet UILabel *textMain;
@property (weak, nonatomic) IBOutlet UITextView *textPost;
@property (weak, nonatomic) IBOutlet UILabel *labelByte;

@end
