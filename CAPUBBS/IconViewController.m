//
//  IconViewController.m
//  CAPUBBS
//
//  Created by 范志康 on 15/3/17.
//  Copyright (c) 2015年 熊典. All rights reserved.
//

#import "IconViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>

#define HAS_CUSTOM_ICON (newIconNum + oldIconNum == -2)
#define OLD_ICON_TOTAL 212

@interface IconViewController ()

@end

@implementation IconViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = GRAY_PATTERN;
    UIView *targetView = self.navigationController ? self.navigationController.view : self.view;
    hud = [[MBProgressHUD alloc] initWithView:targetView];
    [targetView addSubview:hud];
    
    largeCellSize = smallCellSize = 0;
    previewImageView = [[AnimatedImageView alloc] init];
    [previewImageView setBackgroundColor:self.view.backgroundColor];
    [previewImageView setContentMode:UIViewContentModeScaleAspectFill];
    [previewImageView.layer setBorderColor:GREEN_LIGHT.CGColor];
    [previewImageView.layer setBorderWidth:2.0];
    [previewImageView.layer setMasksToBounds:YES];
    
    iconNames = ICON_NAMES;
    newIconNum = oldIconNum = -1;
    // 新头像位置 /bbsimg/icons/xxx.jpeg 老头像位置 /bbsimg/i/num.gif num ∈ [0, OLD_ICON_TOTAL - 1]
    NSString *temp = self.userIcon;
    NSRange range;
    range = [temp rangeOfString:@"/bbsimg/icons/"];
    if (range.length > 0) {
        temp = [temp substringFromIndex:range.location + range.length];
        for (int i = 0; i < iconNames.count; i++) {
            if ([iconNames[i] isEqualToString:temp]) {
                newIconNum = i;
                break;
            }
        }
    }
    range = [temp rangeOfString:@"/bbsimg/i/"];
    if (range.length > 0) {
        temp = [temp substringFromIndex:range.location + range.length];
        temp = [temp stringByReplacingOccurrencesOfString:@".gif" withString:@""];
    }
    if ([self isPureInt:temp]) {
        int num = [temp intValue];
        if (num >= 0 && num < OLD_ICON_TOTAL) {
            oldIconNum = num;
        }
    }
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Register cell classes
    // Do any additional setup after loading the view.
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    largeCellSize = smallCellSize = 0;
    [self.collectionView reloadData];
}

- (BOOL)isPureInt:(NSString *)string {
    NSScanner *scan = [NSScanner scannerWithString:string];
    int val;
    return [scan scanInt:&val] && [scan isAtEnd];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 2;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (section == 0) {
        return iconNames.count + HAS_CUSTOM_ICON;
    } else {
        return OLD_ICON_TOTAL;
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (largeCellSize == 0 || smallCellSize == 0) {
        // iPhone 5s及之前:320 iPhone 6:375 iPhone 6 Plus:414 iPad:768 iPad Pro:1024
        float width = collectionView.frame.size.width;
        // NSLog(@"%f", width);
        if (width <= 450) {
            largeCellSize = (width - 25) / 4;
            smallCellSize = ((width - 35) / 6);
        } else {
            largeCellSize = 80;
            smallCellSize = 50;
        }
    }
    if (indexPath.section == 0) {
        return CGSizeMake(largeCellSize, largeCellSize);
    } else {
        return CGSizeMake(smallCellSize, smallCellSize);
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    IconCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    if (indexPath.section == 0) {
        if (HAS_CUSTOM_ICON && indexPath.row == 0) {
            [cell.icon setUrl:self.userIcon];
        } else {
            [cell.icon setUrl:[NSString stringWithFormat:@"/bbsimg/icons/%@", iconNames[indexPath.row - HAS_CUSTOM_ICON]]];
        }
        [cell.imageCheck setHidden:(indexPath.row != newIconNum + HAS_CUSTOM_ICON)];
        [cell.icon.layer setBorderWidth:3 * (indexPath.row == newIconNum + HAS_CUSTOM_ICON)];
    } else {
        [cell.icon setUrl:[NSString stringWithFormat:@"/bbsimg/i/%d.gif", (int)indexPath.row]];
        [cell.imageCheck setHidden:(indexPath.row != oldIconNum)];
        [cell.icon.layer setBorderWidth:2 * (indexPath.row == oldIconNum)];
    }
    
    return cell;
}

#pragma mark <UICollectionViewDelegate>

// Uncomment this method to specify if the specified item should be selected
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    IconCell *cell = (IconCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [NOTIFICATION postNotificationName:@"selectIcon" object:nil userInfo:@{
        @"URL" : [cell.icon getUrl]
    }];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    IconCell *cell = (IconCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell setAlpha:0.5];
    
    CGRect frame = cell.frame;
    float scale = 1.5;
    if (frame.origin.y < (frame.size.height * scale + [self.view convertRect:self.collectionView.bounds toView:self.view].origin.y)) {
        frame.origin.y += frame.size.height;
    } else {
        frame.origin.y -= frame.size.height;
    }
    frame.origin.x -= ((scale - 1) / 2) * frame.size.width;
    frame.origin.y -= ((scale - 1) / 2) * frame.size.height;
    frame.size.width *= scale;
    frame.size.height *= scale;
    if (frame.origin.x < 8.0) {
        frame.origin.x = 8.0;
    }
    if (frame.origin.x + frame.size.width > collectionView.frame.size.width - 8.0){
        frame.origin.x = collectionView.frame.size.width- 8.0 - frame.size.width;
    }
    
    [previewImageView setFrame:frame];
    [previewImageView setRounded:YES];
    if (![cell.icon.image isEqual:PLACEHOLDER]) {
        [previewImageView setImage:cell.icon.image];
    } else {
        [previewImageView setUrl:[cell.icon getUrl]];
    }
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

- (IBAction)upload:(id)sender {
    UIAlertController *action = [UIAlertController alertControllerWithTitle:@"选择图片来源" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [action addAction:[UIAlertAction actionWithTitle:@"网址链接" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"设置头像"
                                                                       message:@"请输入图片链接"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.keyboardType = UIKeyboardTypeURL;
            textField.placeholder = @"链接";
        }];
        [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"确认"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * _Nonnull action) {
            NSString *url = alert.textFields.firstObject.text;
            if (url.length > 0) {
                [NOTIFICATION postNotificationName:@"selectIcon" object:nil userInfo:@{
                    @"num" : @"-1",
                    @"URL" : url
                }];
                [self.navigationController popViewControllerAnimated:YES];
            } else {
                [self showAlertWithTitle:@"错误" message:@"链接不能为空"];
            }
        }]];
        [self presentViewControllerSafe:alert];
    }]];
    [action addAction:[UIAlertAction actionWithTitle:@"照片图库" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        imagePicker.mediaTypes = @[(NSString *)kUTTypeImage];
        imagePicker.allowsEditing = YES;
        imagePicker.delegate = self;
        [self presentViewControllerSafe:imagePicker];
    }]];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [action addAction:[UIAlertAction actionWithTitle:@"拍照" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
            imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
            imagePicker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
            imagePicker.mediaTypes = @[(NSString *)kUTTypeImage];
            imagePicker.allowsEditing = YES;
            imagePicker.delegate = self;
            [self presentViewControllerSafe:imagePicker];
        }]];
    }
    [action addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    action.popoverPresentationController.barButtonItem = self.buttonUpload;
    [self presentViewControllerSafe:action];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    UIImage *image = info[UIImagePickerControllerEditedImage];
    if (!image || image.size.width <= 0 || image.size.height <= 0) {
        [self showAlertWithTitle:@"警告" message:@"图片不合法，无法获取长度 / 宽度！"];
    } else if (image.size.width / image.size.height > 4.0 / 3.0 || image.size.width / image.size.height < 3.0 / 4.0) {
        [self showAlertWithTitle:@"警告" message:@"所选图片偏离正方形\n建议裁剪处理后使用" confirmTitle:@"继续上传" confirmAction:^(UIAlertAction *action) {
            [self compressAndUploadImage:image];
        } cancelTitle:@"取消上传"];
    } else {
        [self compressAndUploadImage:image];
    }
}

- (void)compressAndUploadImage:(UIImage *)image {
    [hud showWithProgressMessage:@"正在压缩"];
    dispatch_global_default_async(^{
        NSData * imageData = UIImageJPEGRepresentation(image, 1);
        float maxLength = 200; // 压缩超过200K的图片
        float ratio = 1.0;
        while (imageData.length / 1024 >= maxLength && ratio >= 0.05) {
            ratio *= 0.75;
            imageData = UIImageJPEGRepresentation(image, ratio);
        }
        NSLog(@"Icon Size:%dkB", (int)imageData.length / 1024);
        [hud showWithProgressMessage:@"正在上传"];
        [ActionPerformer callApiWithParams:@{ @"image" : [imageData base64EncodedStringWithOptions:0] } toURL:@"image" callback:^(NSArray *result, NSError *err) {
            if (err || result.count == 0) {
                [hud hideWithFailureMessage:@"上传失败"];
                return;
            }
            if ([result[0][@"code"] isEqualToString:@"-1"]) {
                [hud hideWithSuccessMessage:@"上传成功"];
                NSString *url = result[0][@"imgurl"];
                [NOTIFICATION postNotificationName:@"selectIcon" object:nil userInfo:@{ @"URL" : url }];
                [self.navigationController popViewControllerAnimated:YES];
            } else {
                [hud hideWithFailureMessage:@"上传失败"];
            }
        }];
    });
}

- (UIImage *)reSizeImage:(UIImage *)oriImage toSize:(CGSize)reSize{
    UIGraphicsBeginImageContext(CGSizeMake(reSize.width, reSize.height));
    [oriImage drawInRect:CGRectMake(0, 0, reSize.width, reSize.height)];
    UIImage *reSizeImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return reSizeImage;
}

@end
