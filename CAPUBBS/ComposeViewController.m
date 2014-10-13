//
//  ComposeViewController.m
//  CAPUBBS
//
//  Created by 熊典 on 14-2-19.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import "ComposeViewController.h"
#import "ActionPerformer.h"
#import <MobileCoreServices/MobileCoreServices.h>

#define isLandscape UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])
#define isPad (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)


@interface ComposeViewController ()

@end

@implementation ComposeViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (!self.reply) {
        self.reply=@"";
    }
    if (self.defaultContent) {
        self.textBody.text=self.defaultContent;
    }
    if (self.defaultTitle) {
        self.textTitle.text=self.defaultTitle;
    }
    performer=[[ActionPerformer alloc] init];
    origin=self.textBody.frame;
    delta=self.view.frame.size.height-self.textBody.frame.size.height-self.textBody.frame.origin.y;
    self.navigationItem.title=self.navigationTitle;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardHide:) name:UIKeyboardDidChangeFrameNotification object:nil];
    self.textBody.delegate=self;
    // Do any additional setup after loading the view.
    self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(done:)];
    self.navigationItem.leftBarButtonItem=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
    if ([self.navigationTitle isEqualToString:@"发表新帖"]) {
        [self.textTitle becomeFirstResponder];
    }else{
        [self.textBody becomeFirstResponder];
    }

    // Do any additional setup after loading the view.
}
-(BOOL) shouldAutorotate{
    return NO;
}
-(void)done:(id)sender{
    NSString *username=[[NSUserDefaults standardUserDefaults] objectForKey:@"uid"];
    if (!username) {
        [[[UIAlertView alloc] initWithTitle:@"错误" message:@"尚未登录" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
        return;
    }
    if (self.textTitle.text.length==0) {
        [[[UIAlertView alloc] initWithTitle:@"错误" message:@"请输入标题！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
        return;
    }
    if (self.textBody.text.length==0) {
        [[[UIAlertView alloc] initWithTitle:@"错误" message:@"请输入帖子内容！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
        return;
    }
    hud=[[MBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:hud];
    [hud show:YES];
    hud.labelText=@"发表中";
    NSDictionary *dict;
    if (self.isEdit) {
        dict=[NSDictionary dictionaryWithObjectsAndKeys:self.b,@"bid",self.reply,@"tid",self.textTitle.text,@"title",self.textBody.text,@"text",[NSString stringWithFormat:@"%ld",(long)self.segmentedControl.selectedSegmentIndex],@"sig",self.floor,@"pid", nil];
    }else{
        dict=[NSDictionary dictionaryWithObjectsAndKeys:self.b,@"bid",self.reply,@"tid",self.textTitle.text,@"title",self.textBody.text,@"text",[NSString stringWithFormat:@"%ld",(long)self.segmentedControl.selectedSegmentIndex],@"sig", nil];
    }
    [performer performActionWithDictionary:dict toURL:@"post" withBlock:^(NSArray *result, NSError *err) {
        NSInteger back=[[[result firstObject] objectForKey:@"code"] integerValue];
        switch (back) {
            case 0:{
                hud.customView=[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark"]];
                hud.mode=MBProgressHUDModeCustomView;
                hud.labelText=@"已发表";
                [hud hide:YES afterDelay:1];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"shouldRefresh" object:nil userInfo:nil];
                [self performSelector:@selector(dismiss) withObject:nil afterDelay:1];
            }
                break;
            case 1:{
                [[[UIAlertView alloc] initWithTitle:@"错误" message:@"密码错误，您可能在登录后修改过密码，请重新登录！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
                return;
            }
            case 2:{
                [[[UIAlertView alloc] initWithTitle:@"错误" message:@"用户名不存在，请重新登录！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
                return;
            }
                break;
            case 3:{
                [[[UIAlertView alloc] initWithTitle:@"错误" message:@"您的账号被封禁，请联系管理员！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
                return;
            }
                break;
            case 4:{
                [[[UIAlertView alloc] initWithTitle:@"错误" message:@"您的操作过快，请稍后再试！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
                return;
            }
                break;
            case 5:{
                [[[UIAlertView alloc] initWithTitle:@"错误" message:@"文章被锁定，无法回复！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
                return;
            }
                break;
            case 6:{
                [[[UIAlertView alloc] initWithTitle:@"错误" message:@"内部错误！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
                return;
            }
                break;
            case -25:{
                [[[UIAlertView alloc] initWithTitle:@"错误" message:@"登陆超时，请重新登录！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
                return;
            }
                break;
            default:{
                [[[UIAlertView alloc] initWithTitle:@"错误" message:@"未知错误！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
                return;
            }
        }
    }];
}
-(void)dismiss{
    [self dismissViewControllerAnimated:YES completion:nil];
}
-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
-(void)cancel:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}
-(void)dismissKeyboard:(id)sender{
    [self.textBody resignFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)textViewDidBeginEditing:(UITextView *)textView{
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissKeyboard:)] animated:YES];
}
-(void)keyboardHide:(NSNotification*)noti{
    if (isLandscape) {
        return;
    }
    self.textBody.frame=origin;
}
-(void)keyboardShow:(NSNotification*)noti{
    if (isLandscape) {
        return;
    }
    NSDictionary* info = [noti userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    CGRect newrect=self.textBody.frame;
    newrect.size.height=origin.size.height-(isLandscape?kbSize.width:kbSize.height)+delta-32;
    self.textBody.frame=newrect;
}
- (void)textViewDidEndEditing:(UITextView *)textView{
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(done:)] animated:YES];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)didEndOnExit:(id)sender {
    [sender resignFirstResponder];
}
- (IBAction)selectPic:(id)sender {
    UIActionSheet *action=[[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"选择来源", @"") delegate:self cancelButtonTitle:NSLocalizedString(@"取消",@"") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"从照片库导入",@""),[UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]?NSLocalizedString(@"拍照或摄像",@""):nil, nil];
        [action showInView:self.navigationController.view];
}
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex==actionSheet.cancelButtonIndex) {
        return;
    }
    if ([actionSheet.title isEqualToString:NSLocalizedString(@"选择来源",@"")]) {
        if(buttonIndex==0){
            UIImagePickerController *imagePicker=[[UIImagePickerController alloc] init];
            imagePicker.sourceType=UIImagePickerControllerSourceTypePhotoLibrary;
            imagePicker.mediaTypes=[UIImagePickerController availableMediaTypesForSourceType:imagePicker.sourceType];
            imagePicker.delegate=self;
            [self performSelector:@selector(presentImagePicker:) withObject:imagePicker afterDelay:0.5];
        }else if (buttonIndex==1){
            UIImagePickerController *imagePicker=[[UIImagePickerController alloc] init];
            imagePicker.sourceType=UIImagePickerControllerSourceTypeCamera;
            imagePicker.mediaTypes=[UIImagePickerController availableMediaTypesForSourceType:imagePicker.sourceType];
            imagePicker.delegate=self;
            
            [self performSelector:@selector(presentImagePicker:) withObject:imagePicker afterDelay:0.5];
        }
    }else if ([actionSheet.title isEqualToString:@"图片大小"]){
        if (buttonIndex==1) {
            if (image.size.width>800) {
                image=[self reSizeImage:image toSize:CGSizeMake(800, 800/image.size.width*image.size.height)];
            }
        }
        [self didUpload];
    }
}
- (void)presentImagePicker:(UIImagePickerController*)imagePicker{
    [self presentViewController:imagePicker animated:YES completion:nil];
}
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    if ([[info objectForKey:UIImagePickerControllerMediaType] isEqualToString:(NSString*)kUTTypeMovie]) {
        //[info objectForKey:UIImagePickerControllerMediaURL]
        //upload it
        [[[UIAlertView alloc] initWithTitle:@"错误" message:@"论坛不支持上传视频喵" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
    }else{
        image=[info objectForKey:UIImagePickerControllerOriginalImage];
        if (image.size.width<=800) {
            [self didUpload];
        }else{
            [self performSelector:@selector(showAskSheet) withObject:nil afterDelay:0.5];
        }
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
}
- (void)showAskSheet{
    NSLog(@"showAskSheet");
    UIActionSheet *sheet=[[UIActionSheet alloc] initWithTitle:@"图片大小" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle: nil otherButtonTitles:[NSString stringWithFormat:@"上传原图(%d*%d)",(NSInteger)image.size.width,(NSInteger)image.size.height],[NSString stringWithFormat:@"上传压缩图(%d*%d)",800,(NSInteger)(800*image.size.height/image.size.width)], nil];
    [sheet showInView:self.view];
}
- (void)didUpload{
    hud=[[MBProgressHUD alloc] initWithView:self.navigationController.view];
    hud.labelText=NSLocalizedString(@"正在上传",@"");
    [self.navigationController.view addSubview:hud];
    [hud show:YES];
    NSString *path=[NSTemporaryDirectory() stringByAppendingString:@"/temp.jpg"];
    [UIImageJPEGRepresentation(image, 1) writeToFile:path atomically:NO];
    
//    NSString *data=[[NSData dataWithContentsOfFile:path] base64EncodedStringWithOptions:0];
//    performer=[[ActionPerformer alloc] init];
//    [performer performActionWithDictionary:@{@"image":data} toURL:@"image" withBlock:^(NSArray *result, NSError *err) {
//        if (err) {
//            hud.mode=MBProgressHUDModeText;
//            hud.labelText=@"上传失败";
//            NSLog(@"%@",err);
//            [hud hide:YES afterDelay:0.5];
//        }
//        if([[[result firstObject] objectForKey:@"code"] isEqualToString:@"-1"]){
//            [self.textBody insertText:[NSString stringWithFormat:@"[img]%@[/img]",[[result firstObject] objectForKey:@"imgurl"]]];
//            hud.mode=MBProgressHUDModeCustomView;
//            hud.customView=[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Checkmark"]];
//            hud.labelText=@"上传完成";
//            [hud hide:YES afterDelay:0.5];
//        }else{
//            hud.mode=MBProgressHUDModeText;
//            hud.labelText=@"上传失败";
//            [hud hide:YES afterDelay:0.5];
//        }
//
//    }];

    httpRequest=[ASIFormDataRequest requestWithURL:[NSURL URLWithString:@"http://www.chexie.net/api/client.php?ask=file"]];
    [httpRequest setFile:path forKey:@"image"];
    httpRequest.delegate=self;
    uploaded=0;
    total=[[[[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil] objectForKey:NSFileSize] integerValue];
    [httpRequest startAsynchronous];
}
- (void)requestFinished:(ASIHTTPRequest *)request{
    [request setResponseEncoding:NSUTF8StringEncoding];
    NSXMLParser *parser=[[NSXMLParser alloc] initWithData:[request responseData]];
    NSLog(@"%@",request.responseString);
    [parser setDelegate:self];
    if(![parser parse]){
        NSLog(@"1");
        hud.mode=MBProgressHUDModeText;
        hud.labelText=@"上传失败";
        [hud hide:YES afterDelay:0.5];
    }else{
        NSLog(@"%@",finalData.firstObject);
        if([[[finalData firstObject] objectForKey:@"code"] isEqualToString:@"-1"]){
            [self.textBody insertText:[NSString stringWithFormat:@"[img]%@[/img]",[[finalData firstObject] objectForKey:@"imgurl"]]];
            hud.mode=MBProgressHUDModeCustomView;
            hud.customView=[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark"]];
            hud.labelText=@"上传完成";
            [hud hide:YES afterDelay:0.5];
        }else{
            hud.mode=MBProgressHUDModeText;
            hud.labelText=@"上传失败";
            [hud hide:YES afterDelay:0.5];
        }
    }
}
- (void)requestFailed:(ASIHTTPRequest *)request{
    
}
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict{
    if ([elementName isEqualToString:@"capu"]) {
        finalData=[[NSMutableArray alloc] init];
    }else if ([elementName isEqualToString:@"info"]) {
        tempData=[[NSMutableDictionary alloc] init];
    }else{
        currentString=nil;
    }
}
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName{
    if ([elementName isEqualToString:@"capu"]) {
        
    }else if ([elementName isEqualToString:@"info"]){
        [finalData addObject:tempData];
    }else{
        [tempData setObject:currentString?[currentString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]:@"" forKey:elementName];
    }
}
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string{
    if (!currentString) {
        currentString=[[NSMutableString alloc] init];
    }
    [currentString appendString:string];
}
- (void)parser:(NSXMLParser *)parser foundCDATA:(NSData *)CDATABlock{
    if (!currentString) {
        currentString=[[NSMutableString alloc] init];
    }
    [currentString appendString:[[NSString alloc] initWithData:CDATABlock encoding:NSUTF8StringEncoding]];
}
- (UIImage *)reSizeImage:(UIImage *)image toSize:(CGSize)reSize

{
    UIGraphicsBeginImageContext(CGSizeMake(reSize.width, reSize.height));
    [image drawInRect:CGRectMake(0, 0, reSize.width, reSize.height)];
    UIImage *reSizeImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return reSizeImage;
    
}


@end
