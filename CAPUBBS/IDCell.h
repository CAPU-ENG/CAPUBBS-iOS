//
//  IDCell.h
//  CAPUBBS
//
//  Created by 范志康 on 15/11/20.
//  Copyright © 2015年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AsyncImageView.h"

@interface IDCell : UITableViewCell

@property (weak, nonatomic) IBOutlet AsyncImageView *icon;
@property (weak, nonatomic) IBOutlet UILabel *labelText;


@end
