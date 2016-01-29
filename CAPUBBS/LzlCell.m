//
//  LzlCell.m
//  CAPUBBS
//
//  Created by XiongDian on 14/9/21.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import "LzlCell.h"

@implementation LzlCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    [self.imageBottom setAlpha:0.8];
    [self.icon.layer setMasksToBounds:YES];
    [self.textPost.layer setCornerRadius:10.0];
    [self.textPost setScrollsToTop:NO];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
