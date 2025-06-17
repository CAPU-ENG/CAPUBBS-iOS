//
//  FacesViewController.m
//  CAPUBBS
//
//  Created by 范志康 on 15/3/9.
//  Copyright (c) 2015年 熊典. All rights reserved.
//

#import "FacesViewController.h"

@interface FacesViewController ()

@end

@implementation FacesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = GRAY_PATTERN;
    
    previewImageView = [[AnimatedImageView alloc] init];
    self.numberOfFaces = 0;
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Register cell classes
    
    // Do any additional setup after loading the view.
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 2;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (section == 0) {
        return 33;
    } else {
        return 132;
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return CGSizeMake(30, 30);
    } else {
        return CGSizeMake(40, 40);
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    FacesViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"faces" forIndexPath:indexPath];
    if (indexPath.section == 0) {
        [cell.face setGif:[NSString stringWithFormat:@"%d_0.gif", (int)(indexPath.row + 1)]];
    } else {
        [cell.face setGif:[NSString stringWithFormat:@"%d.gif", (int)(indexPath.row + 1)]];
    }
    // Configure the cell
    
    return cell;
}

#pragma mark <UICollectionViewDelegate>

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
        [NOTIFICATION postNotificationName:@"addContent" object:nil userInfo:@{
            @"HTML" : [NSString stringWithFormat:@"[img]/bbsimg/expr/%ld.gif[/img]", (long)(indexPath.row + 1)]
        }];
    } else {
        [NOTIFICATION postNotificationName:@"addContent" object:nil userInfo:@{
            @"HTML" : [NSString stringWithFormat:@"[img]/bbsimg/%ld.gif[/img]", (long)(indexPath.row + 1)]
        }];
    }
    self.numberOfFaces++;
    self.title = [NSString stringWithFormat:@"已插入%d个表情", self.numberOfFaces];
}

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    FacesViewCell *cell = (FacesViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell setAlpha:0.5];
    
    CGRect frame = cell.frame;
    float scale = 1.2;
    if (frame.origin.y < (frame.size.height * scale + 8 + [self.view convertRect:self.collectionView.bounds toView:self.view].origin.y)) {
        frame.origin.y += (frame.size.height + 8);
    } else {
        frame.origin.y -= (frame.size.height + 8);
    }
    frame.origin.x -= ((scale - 1) / 2) * frame.size.width;
    frame.origin.y -= ((scale - 1) / 2) * frame.size.height;
    frame.size.width *= scale;
    frame.size.height *= scale;
    
    [previewImageView setFrame:frame];
    [previewImageView setImage:cell.face.image];
    [self.collectionView addSubview:previewImageView];
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        [cell setAlpha:1.0];
        [previewImageView setAlpha:0.0];
    }completion:^(BOOL finished) {
        [previewImageView removeFromSuperview];
        [previewImageView setAlpha:1.0];
    }];
}

@end
