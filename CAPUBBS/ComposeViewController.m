//
//  ComposeViewController.m
//  CAPUBBS
//
//  Created by 熊典 on 14-2-19.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import "ComposeViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <StoreKit/StoreKit.h>
#import "PreviewViewController.h"
#import "TextViewController.h"
#import "ContentViewController.h"
#import "UIImageEffects.h"

@interface ComposeViewController ()

@end

@implementation ComposeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = GRAY_PATTERN;
    [self.textBody.layer setCornerRadius:6.0];
    [self.textBody.layer setBorderColor:GREEN_LIGHT.CGColor];
    [self.textBody.layer setBorderWidth:0.5];
    [self.textBody setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.5]];
    UIView *targetView = self.navigationController ? self.navigationController.view : self.view;
    hud = [[MBProgressHUD alloc] initWithView:targetView];
    [targetView addSubview:hud];
    
    [self initiateToolBar];
    if (!self.bid || [self.bid isEqualToString:@"hot"]) {
        self.bid = @"";
    }
    if (!self.tid) {
        self.tid = @"";
    }
    if (self.defaultContent) {
        self.textBody.text = self.defaultContent;
    } else {
        self.textBody.text = @"";
    }
    if (self.defaultTitle) {
        self.textTitle.text = self.defaultTitle;
    }    
    [NOTIFICATION addObserver:self selector:@selector(keyboardChange:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [NOTIFICATION addObserver:self selector:@selector(keyboardChange:) name:UIKeyboardDidChangeFrameNotification object:nil];
    [NOTIFICATION addObserver:self selector:@selector(insertContent:) name:@"addContent" object:nil];
    [NOTIFICATION addObserver:self selector:@selector(done:) name:@"publishContent" object:nil];

    if (self.tid.length == 0) {
        self.title = @"发表新帖";
        if ([NUMBERS containsObject:self.bid]) {
            [self.textTitle becomeFirstResponder];
        }
    } else {
        if (self.isEdit) {
            self.title = @"编辑帖子";
        } else {
            self.title = @"发表回复";
        }
        [self.textBody becomeFirstResponder];
    }
    
    self.textTitle.delegate = self;
    self.textBody.delegate = self;
    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self updateDismissable];
//    if (![[DEFAULTS objectForKey:@"FeatureText2.1"] boolValue]) {
//        [self showAlertWithTitle:@"新功能！" message:@"新增插入带颜色、字号、样式字体的功能" cancelTitle:@"我知道了"];
//        [DEFAULTS setObject:@(YES) forKey:@"FeatureText2.1"];
//    }
    if (![[DEFAULTS objectForKey:@"FeaturePreview2.2"] boolValue]) {
        [self showAlertWithTitle:@"Tips" message:@"发帖前可以预览，所见即所得\n向左滑动或者点击右上方▶︎前往" cancelTitle:@"我知道了"];
        [DEFAULTS setObject:@(YES) forKey:@"FeaturePreview2.2"];
    }
    
    if (![ActionPerformer checkLogin:NO]) {
        [self showAlertWithTitle:@"您尚未登录" message:@"请先登录再发帖" cancelAction:^(UIAlertAction *action) {
            [self dismiss];
        }];
        return;
    } else if (![NUMBERS containsObject:self.bid]) {
        self.isEdit = NO;
        UIAlertController *action = [UIAlertController alertControllerWithTitle:@"请选择发帖的版块" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        for (int i = 0; i < 9; i++) {
            [action addAction:[UIAlertAction actionWithTitle:[ActionPerformer getBoardTitle:NUMBERS[i]] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                self.bid = NUMBERS[i];
                self.title = [NSString stringWithFormat:@"%@ @ %@", self.title, [ActionPerformer getBoardTitle:self.bid]];
                [self.textTitle becomeFirstResponder];
                [self updateActivity];
            }]];
        }
        [action addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [self dismiss];
        }]];
        action.popoverPresentationController.sourceView = self.navigationController.navigationBar;
        action.popoverPresentationController.sourceRect = self.navigationController.navigationBar.bounds;
        [self presentViewControllerSafe:action];
    }
    
    if (self.showEditOthersAlert) {
        [self showAlertWithTitle:@"您在编辑他人的帖子" message:@"如果成功发布，作者将被替换成您，签名档也将被替换。请确保您有权限操作！" cancelTitle:@"我知道了"];
        self.showEditOthersAlert = NO;
    }
    
    activity = [[NSUserActivity alloc] initWithActivityType:[BUNDLE_IDENTIFIER stringByAppendingString:@".compose"]];
    [self updateActivity];
    [activity becomeCurrent];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [activity invalidate];
}

- (void)updateActivity {
    if (self.bid.length > 0 && self.tid.length > 0) {
        activity.webpageURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/bbs/content/?tid=%@&bid=%@", CHEXIE, self.tid, self.bid]];
    } else if (self.bid.length > 0) {
        activity.webpageURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/bbs/main/?bid=%@", CHEXIE, self.bid]];
    } else {
        activity.webpageURL = nil;
    }
    activity.userInfo = self.isEdit ? @{
        @"type" : @"compose",
        @"title" : self.textTitle.text,
        @"content" : self.textBody.text,
        @"bid" : self.bid,
        @"tid" : self.tid,
        @"floor" : self.floor,
    } : @{
        @"type" : @"compose",
        @"title" : self.textTitle.text,
        @"content" : self.textBody.text,
        @"bid" : self.bid,
        @"tid" : self.tid,
    };
    activity.title = self.title;
}

- (void)updateDismissable {
    // 如果有输入文字，不允许点击外部关闭
    if (@available(iOS 13.0, *)) {
        [self setModalInPresentation:[self shouldShowDismissWarning]];
    }
}

- (void)textViewDidChange:(UITextView *)textView {
    [self updateActivity];
    [self updateDismissable];
}

- (void)keyboardChange:(NSNotification *)info {
    CGRect keyboardFrame = [info.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval animationDuration = [info.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions options = [info.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue] << 16;
    
    // 将键盘坐标从 window 坐标系转换为当前 view 的坐标系
    CGRect keyboardFrameInView = [self.view convertRect:keyboardFrame fromView:nil];
    
    CGFloat overlap = CGRectGetMaxY(self.view.bounds) - keyboardFrameInView.origin.y;
    if (overlap < 0) {
        overlap = 0;
    }
    
    CGFloat bottomSafeAreaInset = self.view.safeAreaInsets.bottom;
    CGFloat newConstant = overlap - bottomSafeAreaInset;
    if (newConstant < 0) {
        newConstant = 0;
    }
    
    [UIView animateWithDuration:animationDuration delay:0 options:options animations:^{
        self.constraintBottom.constant = newConstant + 15;
        [self.view layoutIfNeeded];
    } completion:nil];
}

- (void)initiateToolBar {
    toolbarEditor = [[DEFAULTS objectForKey:@"toolbarEditor"] intValue];
    toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 1000, 40)];
    UIBarButtonItem *saveD = [[UIBarButtonItem alloc] initWithTitle:@" 📥 " style:UIBarButtonItemStylePlain target:self action:@selector(saveDraft:)];
    UIBarButtonItem *restoreD = [[UIBarButtonItem alloc] initWithTitle:@" 📤 " style:UIBarButtonItemStylePlain target:self action:@selector(restoreDraft:)];
    UIBarButtonItem *blank = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *addAt = [[UIBarButtonItem alloc] initWithTitle:@" 🔔 " style:UIBarButtonItemStylePlain target:self action:@selector(addAt:)];
    UIBarButtonItem *addLink = [[UIBarButtonItem alloc] initWithTitle:@" 🔗 " style:UIBarButtonItemStylePlain target:self action:@selector(addLink:)];
    UIBarButtonItem *changeText = [[UIBarButtonItem alloc] initWithTitle:@" 🎨 " style:UIBarButtonItemStylePlain target:self action:@selector(changeText)];
    UIBarButtonItem *addFace = [[UIBarButtonItem alloc] initWithTitle:@" 😀 " style:UIBarButtonItemStylePlain target:self action:@selector(addFace)];
    UIBarButtonItem *addPic = [[UIBarButtonItem alloc] initWithTitle:@" 📷 " style:UIBarButtonItemStylePlain target:self action:@selector(addPic:)];
    toolbar.items = @[saveD, restoreD, blank, addAt, addLink, changeText, addFace, addPic];
    [self showToolbar];
}

- (void)showToolbar {
    if (toolbarEditor == 0) {
        self.textBody.inputAccessoryView = nil;
        [self.viewTools setHidden:NO];
        self.constraintTop.constant = 66;
    } else if (toolbarEditor == 1) {
        self.textBody.inputAccessoryView = toolbar;
        [self.viewTools setHidden:YES];
        self.constraintTop.constant = 8;
    } else if (toolbarEditor == 2) {
        self.textBody.inputAccessoryView = nil;
        [self.viewTools setHidden:YES];
        self.constraintTop.constant = 8;
    }
    [self.textBody reloadInputViews];
}

- (void)insertContent:(NSNotification *)notification {
    [self.textBody insertText:notification.userInfo[@"HTML"]];
    [self.textBody becomeFirstResponder];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (IBAction)done:(id)sender {
    if (self.textTitle.text.length==0) {
        [self showAlertWithTitle:@"错误" message:@"请输入标题！" cancelAction:^(UIAlertAction *action) {
            [self.textTitle becomeFirstResponder];
        }];
        return;
    }
    if (self.textBody.text.length==0) {
        [self showAlertWithTitle:@"错误" message:@"请输入帖子内容！" cancelAction:^(UIAlertAction *action) {
            [self.textBody becomeFirstResponder];
        }];
        return;
    }
    [self.textTitle resignFirstResponder];
    [self.textBody resignFirstResponder];
    if ([[DEFAULTS objectForKey:@"autoSave"] boolValue]) // 自动保存
    {
        [DEFAULTS setObject:self.textTitle.text forKey:@"savedTitle"];
        [DEFAULTS setObject:self.textBody.text forKey:@"savedBody"];
    }
    [hud showWithProgressMessage:@"发表中"];
    NSString *content = [ActionPerformer toCompatibleFormat:self.textBody.text];
    NSDictionary *dict = self.isEdit ? @{
        @"bid" : self.bid,
        @"tid" : self.tid,
        @"title" : self.textTitle.text,
        @"text" : content,
        @"sig" : [NSString stringWithFormat:@"%ld", (long)self.segmentedControl.selectedSegmentIndex],
        @"pid" : self.floor
    }: @{
        @"bid" : self.bid,
        @"tid" : self.tid,
        @"title" : self.textTitle.text,
        @"text" : content,
        @"sig" : [NSString stringWithFormat:@"%ld", (long)self.segmentedControl.selectedSegmentIndex]
    };
    [ActionPerformer callApiWithParams:dict toURL:@"post" callback:^(NSArray *result, NSError *err) {
        if (err || result.count == 0) {
            NSLog(@"%@", err);
            [hud hideWithFailureMessage:@"发表失败"];
            return;
        }
        NSInteger back = [result[0][@"code"] integerValue];
        if (back == 0) {
            [hud hideWithSuccessMessage:@"发表成功"];
            [SKStoreReviewController requestReview];
        } else {
            [hud hideWithFailureMessage:@"发表失败"];
        }
        switch (back) {
            case 0:{
                [NOTIFICATION postNotificationName:@"refreshContent" object:nil userInfo:@{
                    @"isEdit" : @(self.isEdit),
                    @"floor" : self.isEdit ? self.floor : @"",
                }];
                if (!self.isEdit) {
                    [NOTIFICATION postNotificationName:@"refreshList" object:nil userInfo:nil];
                }
                dispatch_main_after(0.5, ^{
                    [self dismiss];
                });
                break;
            }
            case 1:{
                [self showAlertWithTitle:@"错误" message:@"密码错误，请重新登录！"];
                break;
            }
            case 2:{
                [self showAlertWithTitle:@"错误" message:@"用户不存在，请重新登录！"];
                break;
            }
            case 3:{
                [self showAlertWithTitle:@"错误" message:@"您的账号被封禁，请联系管理员！"];
                break;
            }
            case 4:{
                [self showAlertWithTitle:@"错误" message:@"您的操作过频繁，请稍后再试！"];
                break;
            }
            case 5:{
                [self showAlertWithTitle:@"错误" message:@"文章被锁定，无法操作！"];
                break;
            }
            case 6:{
                [self showAlertWithTitle:@"错误" message:@"帖子不存在或服务器错误！"];
                break;
            }
            case 7:{
                [self showAlertWithTitle:@"错误" message:@"您的权限不够，无法操作！"];
                break;
            }
            case -25:{
                [self showAlertWithTitle:@"错误" message:@"您长时间未登录，请重新登录！"];
                break;
            }
            default:{
                [self showAlertWithTitle:@"错误" message:@"发生未知错误！"];
                break;
            }
        }
    }];
}

- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)shouldShowDismissWarning {
    NSString *title = self.textTitle.text;
    NSString *content = self.textBody.text;
    if (content.length > 0 && ![content isEqualToString:self.defaultContent] &&
        ![content isEqualToString:[DEFAULTS objectForKey:@"savedBody"]]) {
        return YES;
    }
    if (title.length > 0 && ![title isEqualToString:self.defaultTitle] &&
        ![title isEqualToString:[DEFAULTS objectForKey:@"savedTitle"]]) {
        return YES;
    }
    return NO;
}

- (IBAction)cancel:(id)sender {
    if ([self shouldShowDismissWarning]) {
        [self showAlertWithTitle:@"确定退出" message:@"您有尚未发表的内容，建议先保存草稿，确定继续退出？" confirmTitle:@"退出" confirmAction:^(UIAlertAction *action) {
            [self dismiss];
        } cancelTitle:@"返回"];
    } else {
        [self dismiss];
    }
}

- (IBAction)addPic:(id)sender {
    NSString *text = [self.textBody.text substringWithRange:self.textBody.selectedRange];
    if (text.length > 0) {
        NSRange range = self.textBody.selectedRange;
        self.textBody.text = [self.textBody.text stringByReplacingCharactersInRange:self.textBody.selectedRange withString:[NSString stringWithFormat:@"[img]%@[/img]", text]];
        range.length += 11;
        self.textBody.selectedRange = range;
        return;
    }
    UIAlertController *action = [UIAlertController alertControllerWithTitle:@"选择图片来源" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [action addAction:[UIAlertAction actionWithTitle:@"网址链接" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"插入照片"
                                                                       message:@"请输入图片链接"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = @"链接";
            textField.keyboardType = UIKeyboardTypeURL;
        }];
        [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                                  style:UIAlertActionStyleCancel
                                                handler:^(UIAlertAction * _Nonnull action) {
            [self.textBody becomeFirstResponder];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"插入"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * _Nonnull action) {
            NSString *url = alert.textFields[0].text;
            [self.textBody insertText:[NSString stringWithFormat:@"[img]%@[/img]", url]];
            [self.textBody becomeFirstResponder];
            
        }]];
        [self presentViewControllerSafe:alert];
    }]];
    [action addAction:[UIAlertAction actionWithTitle:@"照片图库" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (@available(iOS 14, *)) {
            PHPickerConfiguration *config = [[PHPickerConfiguration alloc] init];
            config.selectionLimit = 20; // 最多一次选20张
            config.filter = [PHPickerFilter imagesFilter];
            PHPickerViewController *picker = [[PHPickerViewController alloc] initWithConfiguration:config];
            picker.delegate = self;
            [self presentViewControllerSafe:picker];
        } else {
            UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
            imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            imagePicker.mediaTypes = @[(NSString *)kUTTypeImage];
            imagePicker.delegate = self;
            [self presentViewControllerSafe:imagePicker];
        }
    }]];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [action addAction:[UIAlertAction actionWithTitle:@"拍照" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
            imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
            imagePicker.mediaTypes = @[(NSString *)kUTTypeImage];
            imagePicker.delegate = self;
            [self presentViewControllerSafe:imagePicker];
        }]];
    }
    [action addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    if ([sender isKindOfClass:[UIBarButtonItem class]]) {
        action.popoverPresentationController.barButtonItem = sender;
    } else {
        UIButton *button = sender;
        action.popoverPresentationController.sourceView = button;
        action.popoverPresentationController.sourceRect = button.bounds;
    }
    [self presentViewControllerSafe:action];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    [self.textTitle resignFirstResponder];
    [self.textBody resignFirstResponder];
    [self uploadOneImage:image withCallback:^(NSString *url) {
        if (url) {
            [self.textBody insertText:[NSString stringWithFormat:@"\n[img]%@[/img]\n",url]];
        }
        [self.textBody becomeFirstResponder];
    }];
}

- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results API_AVAILABLE(ios(14)) {
    [picker dismissViewControllerAnimated:YES completion:nil];
    NSMutableArray<UIImage *> *selectedImages = [NSMutableArray array];
    dispatch_group_t group = dispatch_group_create();
    
    for (PHPickerResult *result in results) {
        if ([result.itemProvider canLoadObjectOfClass:[UIImage class]]) {
            dispatch_group_enter(group);
            [result.itemProvider loadObjectOfClass:[UIImage class] completionHandler:^(UIImage *image, NSError *error) {
                if (image) {
                    @synchronized (selectedImages) {
                        [selectedImages addObject:image];
                    }
                }
                dispatch_group_leave(group);
            }];
        }
    }
    
    // 所有图片加载完后开始上传
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        [self.textTitle resignFirstResponder];
        [self.textBody resignFirstResponder];
        [self uploadImages:selectedImages index:0];
    });
}

- (void)uploadImages:(NSArray<UIImage *> *)images index:(NSInteger)index {
    if (index >= images.count) {
        [self.textBody becomeFirstResponder];
        return;
    }
    [self uploadOneImage:images[index] withCallback:^(NSString *url) {
        if (url) {
            [self.textBody insertText:[NSString stringWithFormat:@"[img]%@[/img]",url]];
        }
        [self uploadImages:images index:index + 1];
    }];
}

- (void)uploadOneImage:(UIImage *)image withCallback:(void (^)(NSString *url))callback {
    if (!image || image.size.width <= 0 || image.size.height <= 0) {
        [self showAlertWithTitle:@"警告" message:@"图片不合法，无法获取长度 / 宽度！" confirmTitle:@"好" confirmAction:^(UIAlertAction *action) {
            callback(nil);
        }];
        return;
    }
    if (image.size.width <= 1000 && image.size.height <= 1000) {
        [self compressAndUploadImage:image withCallback:callback];
    } else {
        [self askForResizeImage:image withCallback:callback];
    }
}

CGSize scaledSizeForImage(UIImage *image, CGFloat maxLength) {
    if (!image) {
        return CGSizeZero;
    }

    CGFloat width = image.size.width;
    CGFloat height = image.size.height;
    CGFloat scale = (width > height) ? maxLength / width : maxLength / height;

    if (scale >= 1.0) {
        return CGSizeZero; // 原图太小，无需缩放
    }

    return CGSizeMake(width * scale, height * scale);
}


- (void)askForResizeImage:(UIImage *)image withCallback:(void (^)(NSString *url))callback {
    UIAlertController *action = [UIAlertController alertControllerWithTitle:@"选择图片大小" message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    // 添加预览图
    // 1. 获取压缩后的图片
    UIImage *thumbnailImage = image;
    CGSize thumbnailSize = scaledSizeForImage(image, 500);
    if (!CGSizeEqualToSize(thumbnailSize, CGSizeZero)) {
        thumbnailImage = [self reSizeImage:image toSize:thumbnailSize];
    }
    // 2. 创建图片附件 (Text Attachment)
    NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
    CGFloat targetHeight = 150.0;
    CGFloat targetCornerRadius = 8.0;
    CGFloat scaleFactor = thumbnailImage.size.height / targetHeight;
    attachment.image = [thumbnailImage imageByApplyingCornerRadius:targetCornerRadius * scaleFactor];
    attachment.bounds = CGRectMake(0, 0, targetHeight * attachment.image.size.width / attachment.image.size.height, targetHeight); // 保持图片宽高比
    // 3. 将附件转为富文本
    NSAttributedString *imageAttributedString = [NSAttributedString attributedStringWithAttachment:attachment];
    // 4. 创建完整的富文本消息
    NSMutableAttributedString *finalMessage = [[NSMutableAttributedString alloc] initWithString:@"\n"];
    [finalMessage appendAttributedString:imageAttributedString];
    // 5. 使用 KVC 设置 attributedMessage
    [action setValue:finalMessage forKey:@"attributedMessage"];

    // 多种缩图尺寸（最长边限制）
    NSArray<NSNumber *> *sizes = @[@800, @1600, @2400];
    for (NSNumber *size in sizes) {
        CGSize newSize = scaledSizeForImage(image, size.floatValue);
        if (CGSizeEqualToSize(newSize, CGSizeZero)) {
            continue; // 跳过，无需缩放
        }
        NSString *title = [NSString stringWithFormat:@"压缩图 (%d×%d)", (int)newSize.width, (int)newSize.height];
        [action addAction:[UIAlertAction actionWithTitle:title
                                                   style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction * _Nonnull action) {
            UIImage *resizedImage = [self reSizeImage:image toSize:newSize];
            [self compressAndUploadImage:resizedImage withCallback:callback];
        }]];
    }
    [action addAction:[UIAlertAction actionWithTitle:
        [NSString stringWithFormat:@"原图 (%d×%d)", (int)image.size.width, (int)image.size.height]
                                                 style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction * _Nonnull action) {
        [self compressAndUploadImage:image withCallback:callback];
    }]];
    [action addAction:[UIAlertAction actionWithTitle:@"取消上传" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        callback(nil);
    }]];
    [self presentViewControllerSafe:action];
}

- (void)compressAndUploadImage:(UIImage *)image withCallback:(void (^)(NSString *url))callback {
    [hud showWithProgressMessage:@"正在压缩"];
    dispatch_global_default_async(^{
        NSData * imageData = UIImageJPEGRepresentation(image, 1);
        float maxLength = IS_SUPER_USER ? 500 : 300; // 压缩超过300K / 500K的图片
        float ratio = 1.0;
        while (imageData.length / 1024 >= maxLength && ratio >= 0.05) {
            ratio *= 0.75;
            imageData = UIImageJPEGRepresentation(image, ratio);
        }
        NSLog(@"Image Size:%dkB", (int)imageData.length / 1024);
        [hud showWithProgressMessage:@"正在上传"];
        [ActionPerformer callApiWithParams:@{ @"image" : [imageData base64EncodedStringWithOptions:0] } toURL:@"image" callback:^(NSArray *result, NSError *err) {
            if (err || result.count == 0) {
                [hud hideWithFailureMessage:@"上传失败"];
                callback(nil);
            } else {
                if ([result[0][@"code"] isEqualToString:@"-1"]) {
                    [hud hideWithSuccessMessage:@"上传完成"];
                    callback([result firstObject][@"imgurl"]);
                } else {
                    [hud hideWithFailureMessage:@"上传失败"];
                    callback(nil);
                }
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

- (IBAction)enterPressed:(id)sender {
    [self.textBody becomeFirstResponder];
}

- (IBAction)saveDraft:(id)sender {
    [self showAlertWithTitle:@"确认保存" message:@"保存草稿会覆盖之前的存档\n确定要继续吗？" confirmTitle:@"保存" confirmAction:^(UIAlertAction *action) {
        [self save];
        [hud showAndHideWithSuccessMessage:@"保存成功"];
    }];
}

- (IBAction)restoreDraft:(id)sender {
    if ([[DEFAULTS objectForKey:@"savedTitle"] length] == 0 && [[DEFAULTS objectForKey:@"savedBody"] length] == 0) {
        [self showAlertWithTitle:@"错误" message:@"您还没有保存草稿"];
    } else {
        [self showAlertWithTitle:@"警告" message:@"恢复草稿会失去当前编辑的内容\n确定要继续吗？" confirmTitle:@"恢复" confirmAction:^(UIAlertAction *action) {
            if (self.textTitle.text.length > 0 && ![[DEFAULTS objectForKey:@"savedTitle"] isEqualToString:self.textTitle.text]) {
                [self showAlertWithTitle:@"检测到冲突！" message:[NSString stringWithFormat:@"草稿标题为：%@\n与当前标题不一致！\n请选择操作：", [DEFAULTS objectForKey:@"savedTitle"]] confirmTitle:@"继续恢复" confirmAction:^(UIAlertAction *action) {
                    [self restore];
                } cancelTitle:@"放弃恢复"];
            } else {
                [self restore];
            }
        }];
    }
}

- (void)save {
    [DEFAULTS setObject:self.textTitle.text forKey:@"savedTitle"];
    [DEFAULTS setObject:self.textBody.text forKey:@"savedBody"];
    self.restoreDraft.enabled = YES;
    [self updateDismissable];
    if ([[DEFAULTS objectForKey:@"savedTitle"] length] == 0 && [[DEFAULTS objectForKey:@"savedBody"] length] == 0) {
        self.restoreDraft.enabled = NO;
    }
}

- (void)restore {
    self.textTitle.text = [DEFAULTS objectForKey:@"savedTitle"];
    self.textBody.text = [DEFAULTS objectForKey:@"savedBody"];
    [self.textBody becomeFirstResponder];
    [self updateDismissable];
    [hud showAndHideWithSuccessMessage:@"恢复成功"];
}

- (IBAction)addAt:(id)sender {
    NSString *text = [self.textBody.text substringWithRange:self.textBody.selectedRange];
    if (text.length > 0) {
        [self.textBody insertText:[NSString stringWithFormat:@"[at]%@[/at]", text]];
        return;
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"插入@/引用"
                                                                   message:@"请输入用户和正文\n正文若为空将使用@形式"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"用户";
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"正文";
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction * _Nonnull action) {
        [self.textBody becomeFirstResponder];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"插入"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
        NSString *user = alert.textFields[0].text;
        NSString *body = alert.textFields[1].text;
        if (body.length == 0) {
            [self.textBody insertText:[NSString stringWithFormat:@"[at]%@[/at]", user]];
        } else {
            [self.textBody insertText:[NSString stringWithFormat:@"[quote=%@]%@[/quote]\n", user, body]];
        }
        [self.textBody becomeFirstResponder];
        
    }]];
    [self presentViewControllerSafe:alert];
}

- (IBAction)addLink:(id)sender {
    NSString *text = [self.textBody.text substringWithRange:self.textBody.selectedRange];
    if (text.length > 0) {
        [self.textBody insertText:[NSString stringWithFormat:@"[url=%@]%@[/url]", text, text]];
        return;
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"插入链接"
                                                                   message:@"请输入链接的标题和地址"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"标题";
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"地址";
        textField.keyboardType = UIKeyboardTypeURL;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction * _Nonnull action) {
        [self.textBody becomeFirstResponder];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"插入"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
        NSString *title = alert.textFields[0].text;
        NSString *url = alert.textFields[1].text;
        if (title.length == 0) {
            title = url;
        }
        if (!([url hasPrefix:@"http://"] || [url hasPrefix:@"https://"] || [url hasPrefix:@"ftp://"])) {
            url = [@"https://" stringByAppendingString:url];
        }
        [self.textBody insertText:[NSString stringWithFormat:@"[url=%@]%@[/url]", url, title]];
        [self.textBody becomeFirstResponder];
        
    }]];
    [self presentViewControllerSafe:alert];
}

- (void)changeText {
    [self performSegueWithIdentifier:@"addText" sender:nil];
}

- (void)addFace {
    [self performSegueWithIdentifier:@"addFace" sender:nil];
}

-(void)clearWithFunction:(NSString *(^)(NSString *text))function {
    [self save];
    if (self.textBody.selectedRange.length > 0) {
        [self.textBody replaceRange:self.textBody.selectedTextRange withText:function([self.textBody.text substringWithRange:self.textBody.selectedRange])];
    } else {
        self.textBody.text = function(self.textBody.text);
    }
    [hud showAndHideWithSuccessMessage:@"清除成功"];
}

- (IBAction)clearFormat:(id)sender {
    NSString *hint = self.textBody.selectedRange.length > 0 ? @"选定范围" : @"所有";
    [self.textTitle resignFirstResponder];
    [self.textBody resignFirstResponder];
    
    UIAlertController *action = [UIAlertController alertControllerWithTitle:@"请选择操作" message:@"清除前会自动保存草稿\n发帖前建议预览以确保格式正确" preferredStyle:UIAlertControllerStyleActionSheet];
    [action addAction:[UIAlertAction actionWithTitle:@"清除HTML标签"
                                               style:UIAlertActionStyleDefault
                                             handler:^(UIAlertAction * _Nonnull action) {
        [self showAlertWithTitle:@"提示" message:[NSString stringWithFormat:@"确认要清除%@的HTML标签吗？\n图片、链接、字体、颜色等会被尽量保留", hint] confirmTitle:@"清除" confirmAction:^(UIAlertAction *action) {
            [self clearWithFunction:^NSString *(NSString *text) {
                return [ActionPerformer removeHTML:[ActionPerformer restoreFormat:text]];
            }];
        }];
    }]];
    [action addAction:[UIAlertAction actionWithTitle:@"清除文字字体"
                                               style:UIAlertActionStyleDefault
                                             handler:^(UIAlertAction * _Nonnull action) {
        [self showAlertWithTitle:@"提示" message:[NSString stringWithFormat:@"确认要清除%@的字体 [font] 标记吗", hint] confirmTitle:@"清除" confirmAction:^(UIAlertAction *action) {
            [self clearWithFunction:^NSString *(NSString *text) {
                return [text stringByReplacingOccurrencesOfString:@"\\[/?font(?:=[^\\]]+)?\\]"
                                                                    withString:@""
                                                                       options:NSRegularExpressionSearch
                                                                         range:NSMakeRange(0, text.length)];
            }];
        }];
    }]];
    [action addAction:[UIAlertAction actionWithTitle:@"清除文字大小"
                                               style:UIAlertActionStyleDefault
                                             handler:^(UIAlertAction * _Nonnull action) {
        [self showAlertWithTitle:@"提示" message:[NSString stringWithFormat:@"确认要清除%@的大小 [size] 标记吗", hint] confirmTitle:@"清除" confirmAction:^(UIAlertAction *action) {
            [self clearWithFunction:^NSString *(NSString *text) {
                return [text stringByReplacingOccurrencesOfString:@"\\[/?size(?:=[^\\]]+)?\\]"
                                                                    withString:@""
                                                                       options:NSRegularExpressionSearch
                                                                         range:NSMakeRange(0, text.length)];
            }];
        }];
    }]];
    [action addAction:[UIAlertAction actionWithTitle:@"清除文字颜色"
                                               style:UIAlertActionStyleDefault
                                             handler:^(UIAlertAction * _Nonnull action) {
        [self showAlertWithTitle:@"提示" message:[NSString stringWithFormat:@"确认要清除%@的颜色 [color] 标记吗", hint] confirmTitle:@"清除" confirmAction:^(UIAlertAction *action) {
            [self clearWithFunction:^NSString *(NSString *text) {
                return [text stringByReplacingOccurrencesOfString:@"\\[/?color(?:=[^\\]]+)?\\]"
                                                                    withString:@""
                                                                       options:NSRegularExpressionSearch
                                                                         range:NSMakeRange(0, text.length)];
            }];
        }];
    }]];
    [action addAction:[UIAlertAction actionWithTitle:@"清除文字粗体"
                                               style:UIAlertActionStyleDefault
                                             handler:^(UIAlertAction * _Nonnull action) {
        [self showAlertWithTitle:@"提示" message:[NSString stringWithFormat:@"确认要清除%@的粗体 [b] 标记吗", hint] confirmTitle:@"清除" confirmAction:^(UIAlertAction *action) {
            [self clearWithFunction:^NSString *(NSString *text) {
                return [text stringByReplacingOccurrencesOfString:@"\\[/?b\\]"
                                                                    withString:@""
                                                                       options:NSRegularExpressionSearch
                                                                         range:NSMakeRange(0, text.length)];
            }];
        }];
    }]];
    [action addAction:[UIAlertAction actionWithTitle:@"清除文字斜体"
                                               style:UIAlertActionStyleDefault
                                             handler:^(UIAlertAction * _Nonnull action) {
        [self showAlertWithTitle:@"提示" message:[NSString stringWithFormat:@"确认要清除%@的斜体 [i] 标记吗", hint] confirmTitle:@"清除" confirmAction:^(UIAlertAction *action) {
            [self clearWithFunction:^NSString *(NSString *text) {
                return [text stringByReplacingOccurrencesOfString:@"\\[/?i\\]"
                                                                    withString:@""
                                                                       options:NSRegularExpressionSearch
                                                                         range:NSMakeRange(0, text.length)];
            }];
        }];
    }]];
    [action addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    UIButton *button = sender;
    action.popoverPresentationController.sourceView = button;
    action.popoverPresentationController.sourceRect = button.bounds;
    [self presentViewControllerSafe:action];
}

- (IBAction)setToolbar:(id)sender {
    toolbarEditor = (toolbarEditor + 1) % 3;
    [self showToolbar];
}

- (IBAction)swipeLeft:(UISwipeGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        [self performSegueWithIdentifier:@"preview" sender:nil];
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"preview"]) {
        PreviewViewController *dest = [segue destinationViewController];
        dest.textTitle = self.textTitle.text;
        dest.textBody = self.textBody.text;
        dest.sig = (int)self.segmentedControl.selectedSegmentIndex;
    }
    if ([segue.identifier isEqualToString:@"addText"]) {
        TextViewController *dest = [segue destinationViewController];
        dest.defaultText = [self.textBody.text substringWithRange:self.textBody.selectedRange];
    }
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

@end
