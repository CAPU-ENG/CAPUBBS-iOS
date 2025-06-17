//
//  CollectionViewCell.h
//  CAPUBBS
//
//  Created by 范志康 on 15/11/11.
//  Copyright © 2015年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AnimatedImageView.h"

@interface CollectionViewCell : UITableViewCell {
}

@property (weak, nonatomic) IBOutlet AnimatedImageView *icon;
@property (weak, nonatomic) IBOutlet UILabel *labelTitle;
@property (weak, nonatomic) IBOutlet UILabel *labelSubtitle;
@property (weak, nonatomic) IBOutlet UILabel *labelInfo;

@end
