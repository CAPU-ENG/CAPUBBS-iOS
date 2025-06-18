//
//  IconViewController.h
//  CAPUBBS
//
//  Created by 范志康 on 15/3/17.
//  Copyright (c) 2015年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IconCell.h"

#define ICON_NAMES @[@"dahlia.jpeg",@"whiterose.jpeg",@"red%20rose.jpeg",@"bowling.jpeg",@"yellow%20daisy.jpeg",@"snowflake.jpeg",@"zebra.jpeg",@"football.jpeg",@"smack.jpeg",@"target.jpeg",@"gingerbread%20man.jpeg",@"leaf.jpeg",@"soccer.jpeg",@"poppy.jpeg",@"earth.jpeg",@"turntable.jpeg",@"nest.jpeg",@"piano.jpeg",@"penguin.jpeg",@"dandelion.jpeg",@"lotus.jpeg",@"drum.jpeg",@"basketball.jpeg",@"ying%20yang.jpeg",@"sandollar.jpeg",@"flower.jpeg",@"owl.jpeg",@"zen.jpeg",@"medal.jpeg",@"sunflower.jpeg",@"fortune%20cookie.jpeg",@"cactus.jpeg",@"parrot.jpeg",@"hockey.jpeg",@"guitar.jpeg",@"violin.jpeg",@"baseball.jpeg",@"lightning.jpeg",@"chalk.jpeg",@"8ball.jpeg",@"eagle.jpeg",@"tennis.jpeg",@"golf.jpeg"]

@interface IconViewController : CustomCollectionViewController<UINavigationControllerDelegate, UIImagePickerControllerDelegate> {
    NSArray *iconNames;
    MBProgressHUD *hud;
    AnimatedImageView *previewImageView;
    int newIconNum;
    int oldIconNum;
    int largeCellSize;
    int smallCellSize;
}

@property NSString *userIcon;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *buttonUpload;

@end
