//
//  IndexViewController.m
//  CAPUBBS
//
//  Created by 熊典 on 14-2-16.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import "IndexViewController.h"
#import "IndexViewCell.h"
#import "ListViewController.h"
#import "ContentViewController.h"

@interface IndexViewController ()

@end

@implementation IndexViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = GREEN_BACK;
    self.buttonBackgroundView.backgroundColor = [GREEN_BACK colorWithAlphaComponent:0.85];
    UIView *targetView = self.navigationController ? self.navigationController.view : self.view;
    hud = [[MBProgressHUD alloc] initWithView:targetView];
    [targetView addSubview:hud];
    
    if ([self.collectionView.collectionViewLayout isKindOfClass:[UICollectionViewFlowLayout class]]) {
        ((UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout).sectionInsetReference = UICollectionViewFlowLayoutSectionInsetFromSafeArea;
    }
    cellWidth = cellHeight = 0;
    
    [NOTIFICATION addObserver:self selector:@selector(changeNoti) name:@"userChanged" object:nil];
    [NOTIFICATION addObserver:self selector:@selector(changeNoti) name:@"infoRefreshed" object:nil];
    
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
//        [DEFAULTS setObject:@(YES) forKey:@"FeatureHot2.0"];
//    }
//    if (![[DEFAULTS objectForKey:@"FeaturePersonalCenter3.0"] boolValue]) {
//        [self showAlertWithTitle:@"新功能！" message:@"消息中心上线\n可以查看系统消息和私信消息\n点击右上方小人前往" cancelTitle:@"我知道了"];
//        [DEFAULTS setObject:@(YES) forKey:@"FeaturePersonalCenter3.0"];
//    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    cellWidth = cellHeight = 0;
    [self.collectionView reloadData];
}

- (void)changeNoti {
    NSDictionary *infoDict = USERINFO;
    BOOL loggedIn = [Helper checkLogin:NO];
    BOOL hasNoti = loggedIn && infoDict && ![infoDict isEqual:@""] && [infoDict[@"newmsg"] integerValue] > 0;
    dispatch_main_async_safe(^{
        self.buttonUser.image = [UIImage systemImageNamed:hasNoti ? @"bell.badge" : @"bell"];
        self.buttonUser.enabled = loggedIn;
    });
}

// In a storyboard-based application, you will often want to do a little preparation before navigation

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return BOARDS.count + 1;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    IndexViewCell * cell;
    if (indexPath.row < BOARDS.count) {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"indexcell" forIndexPath:indexPath];
        NSString *board = BOARDS[indexPath.row];
        cell.image.image = [UIImage imageNamed:[@"b" stringByAppendingString:board]];
        cell.text.text = [Helper getBoardTitle:board];
    } else {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"collectioncell" forIndexPath:indexPath];
    }
    cell.text.font = [UIFont systemFontOfSize:fontSize];
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (cellWidth == 0 || cellHeight == 0) {
        UIEdgeInsets safeArea = collectionView.safeAreaInsets;
        CGFloat safeAreaWidth = (safeArea.left + safeArea.right) / 2;
        CGFloat width = collectionView.bounds.size.width;
        int num = width / 450 + 2;
        cellSpace = (0.1 + 0.025 * num) * (width / num);
        cellMargin = MAX(0, cellSpace - safeAreaWidth);
        cellWidth = (width - cellSpace * (num - 1) - (cellMargin + safeAreaWidth) * 2) / num;
        fontSize = MIN(10 + cellWidth / 25, 20);
        cellHeight = cellWidth * (11.0 / 15.0) + 2 * fontSize;
    }
    return CGSizeMake(cellWidth, cellHeight);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(20, cellMargin, 20, cellMargin); // top, left, bottom, right
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return cellSpace - 0.1;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionReusableView *reusableview = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"header" forIndexPath:indexPath];
    return reusableview;
}

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    [UIView animateWithDuration:0.1 delay:0.0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        [cell setAlpha:0.75];
        [cell setTransform:CGAffineTransformMakeScale(1.05, 1.05)];
    } completion:nil];
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        [cell setAlpha:1.0];
        [cell setTransform:CGAffineTransformMakeScale(1, 1)];
    } completion:nil];
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
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"快速访问" message:[NSString stringWithFormat: @"输入带有帖子链接的文本进行快速访问\n\n高级功能：输入要连接的论坛地址\n目前地址：%@\n\n链接会被自动判别", CHEXIE] preferredStyle:UIAlertControllerStyleAlert];
    __weak typeof(alertController) weakAlertController = alertController; // 避免循环引用
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.keyboardType = UIKeyboardTypeURL;
        textField.text = DEFAULT_SERVER_URL;
        textField.placeholder = @"地址链接";
    }];
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"确认"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
        __strong typeof(weakAlertController) strongAlertController = weakAlertController;
        if (!strongAlertController) {
            return;
        }
        [self multiAction:strongAlertController.textFields[0].text];
    }]];
    [self presentViewControllerSafe:alertController];
}

- (IBAction)back:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)multiAction:(NSString *)text {
    NSString *oriURL = CHEXIE;
    if ([text hasPrefix:@"filesize"]) {
        [hud showWithProgressMessage:@"计算中"];
        dispatch_global_default_async(^{
            NSString *result = [self folderInfo:NSHomeDirectory() showAll:[text hasSuffix:@"all"]];
            [hud hideWithSuccessMessage:@"计算完成"];
            [self showAlertWithTitle:@"空间用量" message:[@"完整内容已复制到剪贴板\n\n" stringByAppendingString:result]];
            [[UIPasteboard generalPasteboard] setString:result];
        });
        return;
    }
    
    NSDictionary *linkInfo = [Helper getLink:text];
    if ([linkInfo[@"bid"] length] > 0) {
        [AppDelegate openLink:linkInfo postTitle:nil];
        return;
    }
    
    if (([text containsString:@"15骑行团"] || [text containsString:@"I2"] || [text containsString:@"维茨C"] || [text containsString:@"好男人"] || [text containsString:@"老蒋"] || [text containsString:@"猿"] || [text containsString:@"小猴子"] || [text containsString:@"熊典"] || [text containsString:@"陈章"] || [text containsString:@"范志康"] || [text containsString:@"蒋雨蒙"] || [text containsString:@"扈煊"] || [text containsString:@"侯书漪"])
        && ([text containsString:@"赞"] || [text containsString:@"棒"] || [text containsString:@"给力"] || [text containsString:@"威武"] || [text containsString:@"牛"] || [text containsString:@"厉害"] || [text containsString:@"帅"] || [text containsString:@"爱"] || [text containsString:@"V5"] || [text containsString:@"么么哒"] || [text containsString:@"漂亮"])
        && ![text containsString:@"不"] && ![text containsString:@"才怪"]
        ) {
        [hud showAndHideWithSuccessMessage:@"~\(≧▽≦)/~"]; // (>^ω^<)
        [DEFAULTS setObject:@(YES) forKey:@"superUser"];
    } else if (([text containsString:@"chexie"] || [text containsString:@"capu"] || [text containsString:@"local"] || [text containsString:@"test"] || [text rangeOfString:@"(?i)(?<![\\w:])((\\d{1,3}\\.){3}\\d{1,3}|([a-f0-9]{0,4}:){2,7}[a-f0-9]{0,4})(?![\\w:])" options:NSRegularExpressionSearch].location != NSNotFound) && ([text hasPrefix:@"http://"] || [text hasPrefix:@"https://"]) && ![text hasSuffix:@"/"] && ![text containsString:@"?"] && ![text containsString:@"#"]) {
        [hud showAndHideWithSuccessMessage:@"设置成功"];
        [GROUP_DEFAULTS setObject:text forKey:@"URL"];
        if (![text isEqualToString:oriURL]) {
            [GROUP_DEFAULTS removeObjectForKey:@"token"];
            [NOTIFICATION postNotificationName:@"userChanged" object:nil userInfo:nil];
        }
    } else {
        [DEFAULTS removeObjectForKey:@"superUser"];
        [self showAlertWithTitle:@"错误" message:@"不是有效的链接"];
    }
}

- (NSString *)folderInfo:(NSString *)rootFolder showAll:(BOOL)all {
    NSMutableString *result = [NSMutableString string];
    NSDirectoryEnumerator *enumerator = [MANAGER enumeratorAtPath:rootFolder];
    NSString *fileName;
        
    while ((fileName = [enumerator nextObject])) {
        NSString *filePath = [rootFolder stringByAppendingPathComponent:fileName];
        NSDictionary<NSFileAttributeKey, id> *attributes = [MANAGER attributesOfItemAtPath:filePath error:nil];
        if (!attributes) {
            continue;
        }
        NSString *fileType = attributes[NSFileType];
        if ([fileType isEqualToString:NSFileTypeDirectory]) {
            [result appendString:[NSString stringWithFormat:@"%@: %@\n", fileName, [Helper fileSizeStr:[Helper folderSizeAtPath:filePath]]]];
        } else if (all && [fileType isEqualToString:NSFileTypeRegular]) {
            [result appendString:[NSString stringWithFormat:@"%@: %@\n", fileName, [Helper fileSizeStr:[Helper fileSizeAtPath:filePath]]]];
        }
    }
    return [result copy];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"hotlist"]) {
        ListViewController *dest = [segue destinationViewController];
        dest.bid = @"hot";
    }
    if ([segue.identifier isEqualToString:@"postlist"]) {
        ListViewController *dest = [segue destinationViewController];
        int number = (int)[self.collectionView indexPathForCell:(UICollectionViewCell *)sender].row;
        dest.bid = BOARDS[number];
    }
    if ([segue.identifier isEqualToString:@"setting"]) {
        UIViewController *dest = [[[segue destinationViewController] viewControllers] firstObject];
        [AppDelegate setAdaptiveSheetFor:dest popoverSource:sender halfScreen:NO];
    }
}

@end
