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
    
    largeCellSize = smallCellSize = 0;
    performer = [[ActionPerformer alloc] init];
    previewImageView = [[AsyncImageView alloc] init];
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
            if ([[iconNames objectAtIndex:i] isEqualToString:temp]) {
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
    }else {
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
        }else {
            largeCellSize = 80;
            smallCellSize = 50;
        }
    }
    if (indexPath.section == 0) {
        return CGSizeMake(largeCellSize, largeCellSize);
    }else {
        return CGSizeMake(smallCellSize, smallCellSize);
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    IconCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    [cell.icon.layer setCornerRadius:(cell.frame.size.width - 10) / 2];
    if (indexPath.section == 0) {
        if (HAS_CUSTOM_ICON && indexPath.row == 0) {
            [cell.icon setUrl:self.userIcon];
        }else {
            [cell.icon setUrl:[NSString stringWithFormat:@"/bbsimg/icons/%@", [iconNames objectAtIndex:(int)indexPath.row - HAS_CUSTOM_ICON]]];
        }
        [cell.imageCheck setHidden:(indexPath.row != newIconNum + HAS_CUSTOM_ICON)];
        [cell.icon.layer setBorderWidth:3 * (indexPath.row == newIconNum + HAS_CUSTOM_ICON)];
    }else {
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
    [NOTIFICATION postNotificationName:@"selectIcon" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:cell.icon.url, @"URL", nil]];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    IconCell *cell = (IconCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell setAlpha:0.5];
    
    CGRect frame = cell.frame;
    float scale = 1.5;
    if (frame.origin.y < (frame.size.height * scale + [self.view convertRect:self.collectionView.bounds toView:self.view].origin.y)) {
        frame.origin.y += frame.size.height;
    }else {
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
    [previewImageView.layer setCornerRadius:frame.size.height / 2];
    if (![cell.icon.image isEqual:PLACEHOLDER]) {
        [previewImageView setImage:cell.icon.image];
    }else {
        [previewImageView setUrl:cell.icon.url];
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
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"设置头像" message:@"请输入图片链接" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确认", nil];
        alert.alertViewStyle=UIAlertViewStylePlainTextInput;
        [alert textFieldAtIndex:0].keyboardType = UIKeyboardTypeURL;
        [alert textFieldAtIndex:0].placeholder = @"链接";
        [alert show];
    }]];
    [action addAction:[UIAlertAction actionWithTitle:@"照片图库" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        imagePicker.mediaTypes = @[(NSString *)kUTTypeImage];
        imagePicker.allowsEditing = YES;
        imagePicker.delegate = self;
        [self performSelector:@selector(presentImagePicker:) withObject:imagePicker afterDelay:0.5];
    }]];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [action addAction:[UIAlertAction actionWithTitle:@"拍照" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
            imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
            imagePicker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
            imagePicker.mediaTypes = @[(NSString *)kUTTypeImage];
            imagePicker.allowsEditing = YES;
            imagePicker.delegate = self;
            [self performSelector:@selector(presentImagePicker:) withObject:imagePicker afterDelay:0.5];
        }]];
    }
    [action addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    action.popoverPresentationController.barButtonItem = self.buttonUpload;
    [self presentViewController:action animated:YES completion:nil];
}

- (void)presentImagePicker:(UIImagePickerController*)imagePicker {
    [self presentViewController:imagePicker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    image = [info objectForKey:UIImagePickerControllerEditedImage];
    if (image.size.width / image.size.height > 4.0 / 3.0 || image.size.width / image.size.height < 3.0 / 4.0) {
        [[[UIAlertView alloc] initWithTitle:@"警告" message:@"所选图片偏离正方形\n建议裁剪处理后使用" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"继续上传", nil] show];
    }else {
        [self prepareUpload];
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)prepareUpload {
    if (!hud && self.navigationController) {
        hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
        [self.navigationController.view addSubview:hud];
    }
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = @"正在压缩";
    [hud show:YES];
    [self performSelectorInBackground:@selector(upload) withObject:nil];
}

- (void)upload {
    NSData * imageData = UIImageJPEGRepresentation(image, 1);
    float maxLength = 200; // 压缩超过200K的图片
    float ratio = 1.0;
    while (imageData.length / 1024 >= maxLength && ratio >= 0.05) {
        ratio *= 0.75;
        imageData = UIImageJPEGRepresentation(image, ratio);
    }
    NSLog(@"Icon Size:%dkB", (int)imageData.length / 1024);
    hud.labelText = @"正在上传";
    [performer performActionWithDictionary:[NSDictionary dictionaryWithObjectsAndKeys:[imageData base64EncodedStringWithOptions:0], @"image", nil] toURL:@"image" withBlock:^(NSArray *result, NSError *err) {
        if (err || result.count == 0) {
            hud.customView = [[UIImageView alloc] initWithImage:FAILMARK];
            hud.labelText = @"上传失败";
        }else {
            if ([[[result firstObject] objectForKey:@"code"] isEqualToString:@"-1"]) {
                hud.customView = [[UIImageView alloc] initWithImage:SUCCESSMARK];
                hud.labelText = @"上传完成";
                NSString *url = [[result firstObject] objectForKey:@"imgurl"];
                [NOTIFICATION postNotificationName:@"selectIcon" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:url, @"URL", nil]];
                [self.navigationController popViewControllerAnimated:YES];
            }else {
                hud.customView = [[UIImageView alloc] initWithImage:FAILMARK];
                hud.labelText = @"上传失败";
            }
        }
        hud.mode = MBProgressHUDModeCustomView;
        [hud hide:YES afterDelay:0.5];
    }];
}

- (UIImage *)reSizeImage:(UIImage *)oriImage toSize:(CGSize)reSize{
    UIGraphicsBeginImageContext(CGSizeMake(reSize.width, reSize.height));
    [oriImage drawInRect:CGRectMake(0, 0, reSize.width, reSize.height)];
    UIImage *reSizeImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return reSizeImage;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == alertView.cancelButtonIndex) {
        return;
    }
    if ([alertView.title isEqualToString:@"设置头像"]) {
        NSString *url = [alertView textFieldAtIndex:0].text;
        if (url.length > 0) {
            [NOTIFICATION postNotificationName:@"selectIcon" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"-1", @"num", url, @"URL", nil]];
            [self.navigationController popViewControllerAnimated:YES];
        }else {
            [[[UIAlertView alloc] initWithTitle:@"错误" message:@"链接不能为空" delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil] show];
        }
    }else if ([alertView.title isEqualToString:@"警告"]) {
        [self prepareUpload];
    }
}

@end
