//
//  ComposeViewController.m
//  CAPUBBS
//
//  Created by 熊典 on 14-2-19.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import "ComposeViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "PreviewViewController.h"
#import "TextViewController.h"
#import "ContentViewController.h"

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
    performer = [[ActionPerformer alloc] init];
    
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
//    if (![[DEFAULTS objectForKey:@"FeatureText2.1"] boolValue]) {
//        [self showAlertWithTitle:@"新功能！" message:@"新增插入带颜色、字号、样式字体的功能" cancelTitle:@"我知道了"];
//        [DEFAULTS setObject:[NSNumber numberWithBool:YES] forKey:@"FeatureText2.1"];
//    }
    if (![[DEFAULTS objectForKey:@"FeaturePreview2.2"] boolValue]) {
        [self showAlertWithTitle:@"Tips" message:@"发帖前可以预览，所见即所得\n向左滑动或者点击右上方▶︎前往" cancelTitle:@"我知道了"];
        [DEFAULTS setObject:[NSNumber numberWithBool:YES] forKey:@"FeaturePreview2.2"];
    }
    
    if (![NUMBERS containsObject:self.bid]) {
        self.isEdit = NO;
        UIAlertController *action = [UIAlertController alertControllerWithTitle:@"请选择发帖的版块" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        for (int i = 0; i < 9; i++) {
            [action addAction:[UIAlertAction actionWithTitle:[ActionPerformer getBoardTitle:[NUMBERS objectAtIndex:i]] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                self.bid = [NUMBERS objectAtIndex:i];
                self.title = [NSString stringWithFormat:@"%@ @ %@", self.title, [ActionPerformer getBoardTitle:self.bid]];
                [self.textTitle becomeFirstResponder];
                [self updateActivity];
            }]];
        }
        [action addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [self dismissViewControllerAnimated:YES completion:nil];
        }]];
        action.popoverPresentationController.sourceView = self.buttonTools;
        action.popoverPresentationController.sourceRect = self.buttonTools.bounds;
        [self presentViewControllerSafe:action];
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
        activity.webpageURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/bbs/content/?tid=%@&bid=%@&p=%ld", CHEXIE, self.tid, self.bid, (long)self.floor]];
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

- (void)textViewDidChange:(UITextView *)textView {
    [self updateActivity];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self updateActivity];
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
    [self.textBody insertText:[notification.userInfo objectForKey:@"HTML"]];
    [self.textBody becomeFirstResponder];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (IBAction)done:(id)sender {
    if (self.textTitle.text.length==0) {
        [self showAlertWithTitle:@"错误" message:@"请输入标题！"];
        [self.textTitle becomeFirstResponder];
        return;
    }
    if (self.textBody.text.length==0) {
        [self showAlertWithTitle:@"错误" message:@"请输入帖子内容！"];
        [self.textBody becomeFirstResponder];
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
    NSString *changedText = [self transFormat:self.textBody.text];
    NSDictionary *dict = self.isEdit ? @{
        @"bid" : self.bid,
        @"tid" : self.tid,
        @"title" : self.textTitle.text,
        @"text" : changedText,
        @"sig" : [NSString stringWithFormat:@"%ld", (long)self.segmentedControl.selectedSegmentIndex],
        @"pid" : self.floor
    }: @{
        @"bid" : self.bid,
        @"tid" : self.tid,
        @"title" : self.textTitle.text,
        @"text" : changedText,
        @"sig" : [NSString stringWithFormat:@"%ld", (long)self.segmentedControl.selectedSegmentIndex]
    };
    [performer performActionWithDictionary:dict toURL:@"post" withBlock:^(NSArray *result, NSError *err) {
        if (err || result.count == 0) {
            NSLog(@"%@", err);
            [hud hideWithFailureMessage:@"发表失败"];
            return;
        }
        NSInteger back = [[[result firstObject] objectForKey:@"code"] integerValue];
        if (back == 0) {
            [hud hideWithSuccessMessage:@"发表成功"];
        } else {
            [hud hideWithFailureMessage:@"发表失败"];
        }
        switch (back) {
            case 0:{
                [NOTIFICATION postNotificationName:@"refreshContent" object:nil userInfo:@{
                    @"isEdit" : @(self.isEdit)
                }];
                [NOTIFICATION postNotificationName:@"refreshList" object:nil userInfo:nil];
                [self performSelector:@selector(dismiss) withObject:nil afterDelay:0.5];
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

- (NSString *)transFormat:(NSString *)text {
    text = [text stringByReplacingOccurrencesOfString:@"\n" withString:@"<br />"];
    int index = 0;
    while (index < text.length) {
        if ([[text substringWithRange:NSMakeRange(index, 1)] isEqualToString:@"<"]) {
            index++;
            while (index < text.length) {
                if ([[text substringWithRange:NSMakeRange(index, 1)] isEqualToString:@">"]) {
                    break;
                }
                index++;
            }
        }
        if (index < text.length && [[text substringWithRange:NSMakeRange(index, 1)] isEqualToString:@" "]) {
            text = [text stringByReplacingCharactersInRange:NSMakeRange(index, 1) withString:@"&nbsp;"];
            index += 5;
        }
        index++;
    }
//    NSLog(@"%@", text);
    return text;
}

- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)cancel:(id)sender {
    if (self.textBody.text.length > 0 && !([self.textTitle.text isEqualToString:[DEFAULTS objectForKey:@"savedTitle"]] && [self.textBody.text isEqualToString:[DEFAULTS objectForKey:@"savedBody"]])) {
        [self showAlertWithTitle:@"确定退出" message:@"您编辑了正文内容，建议先保存草稿，确定要直接退出吗？" confirmTitle:@"退出" confirmAction:^(UIAlertAction *action) {
            [self dismissViewControllerAnimated:YES completion:nil];
        } cancelTitle:@"返回"];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)dismissKeyboard:(id)sender {
    [self.textBody resignFirstResponder];
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
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        imagePicker.mediaTypes = @[(NSString *)kUTTypeImage];
        imagePicker.delegate = self;
        [self performSelector:@selector(presentImagePicker:) withObject:imagePicker afterDelay:0.5];
    }]];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [action addAction:[UIAlertAction actionWithTitle:@"拍照" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
            imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
            imagePicker.mediaTypes = @[(NSString *)kUTTypeImage];
            imagePicker.delegate = self;
            [self performSelector:@selector(presentImagePicker:) withObject:imagePicker afterDelay:0.5];
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
- (void)presentImagePicker:(UIImagePickerController*)imagePicker {
    [self presentViewControllerSafe:imagePicker];
}
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    image = [info objectForKey:UIImagePickerControllerOriginalImage];
    if (image.size.width <= 800 && image.size.height <= 800) {
        [self prepareUpload];
    } else {
        [self performSelector:@selector(showResize) withObject:nil afterDelay:0.5];
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
}

CGSize ScaledSizeForImage(UIImage *image, CGFloat maxLength) {
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

- (void)showResize {
    UIAlertController *action = [UIAlertController alertControllerWithTitle:@"图片大小" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [action addAction:[UIAlertAction actionWithTitle:
        [NSString stringWithFormat:@"上传原图 (%d×%d)", (int)image.size.width, (int)image.size.height]
                                                 style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction * _Nonnull action) {
        [self prepareUpload];
    }]];
    // 多种缩图尺寸（最长边限制）
    NSArray<NSNumber *> *sizes = @[@800, @1600, @2400];
    for (NSNumber *size in sizes) {
        CGSize newSize = ScaledSizeForImage(image, size.floatValue);
        if (CGSizeEqualToSize(newSize, CGSizeZero)) {
            continue; // 跳过，无需缩放
        }
        NSString *title = [NSString stringWithFormat:@"上传压缩图 (%d×%d)", (int)newSize.width, (int)newSize.height];
        [action addAction:[UIAlertAction actionWithTitle:title
                                                   style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction * _Nonnull action) {
            image = [self reSizeImage:image toSize:newSize];
            [self prepareUpload];
        }]];
    }
    [action addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    if (!self.viewTools.isHidden) {
        action.popoverPresentationController.sourceView = self.buttonPic;
        action.popoverPresentationController.sourceRect = self.buttonPic.bounds;
    }
    [self presentViewControllerSafe:action];
}

- (void)prepareUpload {
    [hud showWithProgressMessage:@"正在压缩"];
    [self performSelectorInBackground:@selector(upload) withObject:nil];
}

- (void)upload {
    NSData * imageData = UIImageJPEGRepresentation(image, 1);
    float maxLength = IS_SUPER_USER ? 500 : 300; // 压缩超过300K / 500K的图片
    float ratio = 1.0;
    while (imageData.length / 1024 >= maxLength && ratio >= 0.05) {
        ratio *= 0.75;
        imageData = UIImageJPEGRepresentation(image, ratio);
    }
    NSLog(@"Image Size:%dkB", (int)imageData.length / 1024);
    [hud showWithProgressMessage:@"正在上传"];
    [performer performActionWithDictionary:@{ @"image" : [imageData base64EncodedStringWithOptions:0] } toURL:@"image" withBlock:^(NSArray *result, NSError *err) {
        if (err || result.count == 0) {
            [hud hideWithFailureMessage:@"上传失败"];
        } else {
            if ([[[result firstObject] objectForKey:@"code"] isEqualToString:@"-1"]) {
                [hud hideWithSuccessMessage:@"上传完成"];
                NSString *url = [[result firstObject] objectForKey:@"imgurl"];
                [self.textBody insertText:[NSString stringWithFormat:@"[img]%@[/img]",url]];
            } else {
                [hud hideWithFailureMessage:@"上传失败"];
            }
            [self.textBody becomeFirstResponder];
        }
    }];
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
    if ([[DEFAULTS objectForKey:@"savedTitle"] length] == 0 && [[DEFAULTS objectForKey:@"savedBody"] length] == 0) {
        self.restoreDraft.enabled = NO;
    }
}

- (void)restore {
    self.textTitle.text = [DEFAULTS objectForKey:@"savedTitle"];
    self.textBody.text = [DEFAULTS objectForKey:@"savedBody"];
    [self.textBody becomeFirstResponder];
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

- (IBAction)clearFormat:(id)sender {
    [self showAlertWithTitle:@"警告" message:[NSString stringWithFormat:@"确认要清除%@的HTML代码吗？\n图片、链接、字体等会得到保留\n清除前会自动保存草稿", self.textBody.selectedRange.length > 0 ? @"选定范围" : @"所有"] confirmTitle:@"清除" confirmAction:^(UIAlertAction *action) {
        [self save];
        if (self.textBody.selectedRange.length > 0) {
            [self.textBody replaceRange:self.textBody.selectedTextRange withText:[ContentViewController removeHTML:[self.textBody.text substringWithRange:self.textBody.selectedRange]]];
        } else {
            self.textBody.text = [ContentViewController removeHTML:self.textBody.text];
        }
        [hud showAndHideWithSuccessMessage:@"清除成功"];
    }];
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
        dest.textBody = [self transFormat:self.textBody.text];
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
