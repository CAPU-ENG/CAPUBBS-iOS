//
//  CollectionViewCell.m
//  CAPUBBS
//
//  Created by 范志康 on 15/11/11.
//  Copyright © 2015年 熊典. All rights reserved.
//

#import "CollectionViewCell.h"

@implementation CollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    [self.icon.layer setMasksToBounds:YES];
    self.layer.shouldRasterize = YES; // 光栅化 提高流畅度
    self.layer.rasterizationScale = [UIScreen mainScreen].scale;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
