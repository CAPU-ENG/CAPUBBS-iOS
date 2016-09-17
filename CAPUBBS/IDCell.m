//
//  IDCell.m
//  CAPUBBS
//
//  Created by 范志康 on 15/11/20.
//  Copyright © 2015年 熊典. All rights reserved.
//

#import "IDCell.h"

@implementation IDCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    [self.icon setRounded:YES];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
