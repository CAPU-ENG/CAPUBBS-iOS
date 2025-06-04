//
//  IndexViewController.m
//  CAPUBBS
//
//  Created by 熊典 on 14-2-16.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "IndexViewController.h"
#import "ListViewController.h"
#import "ContentViewController.h"
#import "SettingViewController.h"

@interface IndexViewController ()

@end

@implementation IndexViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = GREEN_BACK;
    
    cellWidth = cellHeight = 0;
    [NOTIFICATION addObserver:self selector:@selector(setVibrate) name:@"userChanged" object:nil];
    [NOTIFICATION addObserver:self selector:@selector(changeNoti) name:@"infoRefreshed" object:nil];
    [self setVibrate];
    [self changeNoti];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
//    if (![[DEFAULTS objectForKey:@"FeatureHot2.0"] boolValue]) {
//        [self showAlertWithTitle:@"新功能！" message:@"增加了大家期待的论坛热点\n点击按钮或向左滑动前往" cancelTitle:@"我知道了"];
//        [DEFAULTS setObject:[NSNumber numberWithBool:YES] forKey:@"FeatureHot2.0"];
//    }
//    if (![[DEFAULTS objectForKey:@"FeaturePersonalCenter3.0"] boolValue]) {
//        [self showAlertWithTitle:@"新功能！" message:@"消息中心上线\n可以查看系统消息和私信消息\n点击右上方小人前往" cancelTitle:@"我知道了"];
//        [DEFAULTS setObject:[NSNumber numberWithBool:YES] forKey:@"FeaturePersonalCenter3.0"];
//    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    cellWidth = cellHeight = 0;
    [self.collectionView reloadData];
}

- (void)setVibrate {
    shouldVibrate = YES;
}

- (void)changeNoti {
    dispatch_main_async_safe(^{
        NSDictionary *infoDict = USERINFO;
        if ([ActionPerformer checkLogin:NO] && ![infoDict isEqual:@""] && [[infoDict objectForKey:@"newmsg"] integerValue] > 0) {
            [self.buttonUser setImage:[UIImage imageNamed:@"user-noti"]];
            if (shouldVibrate && [[DEFAULTS objectForKey:@"vibrate"] boolValue] == YES) {
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
                NSLog(@"Vibreate");
            }
            shouldVibrate = NO;
        } else {
            [self.buttonUser setImage:[UIImage imageNamed:@"user"]];
        }
    });
}

// In a storyboard-based application, you will often want to do a little preparation before navigation

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return NUMBERS.count + 1;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    IndexViewCell * cell;
    if (indexPath.row < NUMBERS.count) {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"indexcell" forIndexPath:indexPath];
        cell.image.image = [UIImage imageNamed:[@"b" stringByAppendingString:[NUMBERS objectAtIndex:indexPath.row]]];
        cell.text.text = [ActionPerformer getBoardTitle:[NUMBERS objectAtIndex:indexPath.row]];
    } else {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"collectioncell" forIndexPath:indexPath];
    }
    cell.text.font = [UIFont systemFontOfSize:fontSize];
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (cellWidth == 0 || cellHeight == 0) {
        // iPhone 5s及之前:320 iPhone 6:375 iPhone 6 Plus:414 iPad:768 iPad Pro:1024
        float width = collectionView.frame.size.width;
        int num = width / 450 + 2;
        fontSize = 15 + num;
        cellSpace = (0.1 + 0.025 * num) * (width / num);
        cellWidth = (width - cellSpace * (num + 1)) / num;
        cellHeight = cellWidth * (11.0 / 15.0) + 2 * fontSize;
    }
    return CGSizeMake(cellWidth, cellHeight);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(20, cellSpace, 20, cellSpace); // top, left, bottom, right
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return cellSpace;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionReusableView *reusableview = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"header" forIndexPath:indexPath];
    return reusableview;
}

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    [cell setAlpha:0.5];
    [cell setTransform:CGAffineTransformMakeScale(1.05, 1.05)];
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        [cell setAlpha:1.0];
        [cell setTransform:CGAffineTransformMakeScale(1, 1)];
    }completion:nil];
}

- (IBAction)swipeLeft:(UISwipeGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        [self performSegueWithIdentifier:@"hotlist" sender:nil];
    }
}

- (IBAction)swipeRight:(UISwipeGestureRecognizer *)sender {
        if (sender.state == UIGestureRecognizerStateEnded) {
            [self back:nil];
        }
}

- (IBAction)smart:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"快速访问" message:[NSString stringWithFormat: @"输入带有帖子链接的文本进行快速访问\n\n高级功能\n输入要连接的论坛地址\n目前地址：%@\n链接会被自动判别", CHEXIE] delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert textFieldAtIndex:0].keyboardType = UIKeyboardTypeURL;
    [alert textFieldAtIndex:0].text = @"https://www.chexie.net";
    [alert textFieldAtIndex:0].placeholder = @"地址链接";
    [alert show];
}

- (IBAction)back:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == alertView.cancelButtonIndex) {
        return;
    }
    if ([alertView.title isEqualToString:@"快速访问"]) {
        NSString *oriURL = CHEXIE;
        NSString *text = [alertView textFieldAtIndex:0].text;
        
        if ([text containsString:@"filesize"]) {
            NSString *result = [self folderInfo:NSHomeDirectory() showAll:[text containsString:@"all"]];
            [self showAlertWithTitle:@"空间用量\n内容已复制到剪贴板" message:result];
            [[UIPasteboard generalPasteboard] setString:result];
            return;
        }
        
        NSDictionary *dict = [ContentViewController getLink:text];
        if (dict.count > 0 && ![dict[@"tid"] isEqualToString:@""]) {
            ContentViewController *next = [self.storyboard instantiateViewControllerWithIdentifier:@"content"];
            next.bid = dict[@"bid"];
            next.tid = dict[@"tid"];
            next.floor = [NSString stringWithFormat:@"%d", [dict[@"p"] intValue] * 12];
            next.title=@"帖子跳转中";
            [self.navigationController pushViewController:next animated:YES];
            return;
        }
        
        if (!hud && self.navigationController) {
            hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
            [self.navigationController.view addSubview:hud];
        }
        [hud showAnimated:YES];
        hud.mode = MBProgressHUDModeCustomView;
        if (
            (([text containsString:@"15"] && [text containsString:@"骑行团"]) || [text containsString:@"I2"] || [text containsString:@"维茨C"] || [text containsString:@"好男人"] || [text containsString:@"老蒋"] || [text containsString:@"猿"] || [text containsString:@"小猴子"] || [text containsString:@"熊典"] || [text containsString:@"陈章"] || [text containsString:@"范志康"] || [text containsString:@"蒋雨蒙"] || [text containsString:@"扈煊"] || [text containsString:@"侯书漪"])
            && ([text containsString:@"赞"] || [text containsString:@"棒"] || [text containsString:@"给力"] || [text containsString:@"威武"] || [text containsString:@"牛"] || [text containsString:@"厉害"] || [text containsString:@"帅"] || [text containsString:@"爱"] || [text containsString:@"V5"] || [text containsString:@"么么哒"] || [text containsString:@"漂亮"])
            && ![text containsString:@"不"]
            ) {
            hud.label.text = @"~\(≧▽≦)/~"; // (>^ω^<)
            hud.customView = [[UIImageView alloc] initWithImage:SUCCESSMARK];
            [hud hideAnimated:YES afterDelay:1];
            [DEFAULTS setObject:[NSNumber numberWithInt:MAX_ID_NUM] forKey:@"IDNum"];
            [DEFAULTS setObject:[NSNumber numberWithInt:MAX_HOT_NUM] forKey:@"hotNum"];
        } else {
            [DEFAULTS removeObjectForKey:@"IDNum"];
            [DEFAULTS removeObjectForKey:@"hotNum"];
            if (!([text containsString:@"chexie"] || [text containsString:@"capu"] || [text containsString:@"local"] || [text containsString:@"test"] || [text containsString:@"/"] || [text rangeOfString:@"[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}" options:NSRegularExpressionSearch].location != NSNotFound)) {
                [self showAlertWithTitle:@"错误" message:@"不是有效的链接"];
                hud.label.text = @"设置失败";
                hud.customView = [[UIImageView alloc] initWithImage:FAILMARK];
            } else {
                hud.label.text = @"设置成功";
                hud.customView = [[UIImageView alloc] initWithImage:SUCCESSMARK];
                [GROUP_DEFAULTS setObject:text forKey:@"URL"];
                if (![text isEqualToString:oriURL]) {
                    [GROUP_DEFAULTS removeObjectForKey:@"token"];
                    dispatch_main_async_safe(^{
                        [NOTIFICATION postNotificationName:@"userChanged" object:nil userInfo:nil];
                    });
                }
            }
            [hud hideAnimated:YES afterDelay:0.5];
        }
    }
}

- (NSString *)folderInfo:(NSString *)rootFolder showAll:(BOOL)all {
    NSString *result = @"";
    NSArray *childPaths = [MANAGER subpathsAtPath:rootFolder];
    for (NSString *path in childPaths) {
        NSString *childPath = [NSString stringWithFormat:@"%@/%@", rootFolder, path];
        NSArray *testPaths = [MANAGER subpathsAtPath:childPath];
        if (!(testPaths.count == 0 && all == NO)) {
            result = [NSString stringWithFormat:@"%@%@:%.2fKB\n", result, path, (float)[SettingViewController folderSizeAtPath:childPath] / (1024)];
        }
    }
    return result;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    ListViewController *dest = [segue destinationViewController];
    if ([segue.identifier isEqualToString:@"hotlist"]) {
        dest.bid = @"hot";
    }
    if ([segue.identifier isEqualToString:@"postlist"]) {
        int number = (int)[self.collectionView indexPathForCell:(UICollectionViewCell *)sender].row;
        dest.bid = [NUMBERS objectAtIndex:number];
    }
}

@end
