//
//  TextViewController.m
//  CAPUBBS
//
//  Created by 范志康 on 15/3/29.
//  Copyright (c) 2015年 熊典. All rights reserved.
//

#import "TextViewController.h"
#import "ActionPerformer.h"

@interface TextViewController ()

@end

@implementation TextViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = GRAY_PATTERN;
    [self.labelPreview.layer setCornerRadius:10.0];
    [self.labelPreview.layer setMasksToBounds:YES];
    [self.textInput.layer setCornerRadius:10.0];
    self.textInput.text = self.defaultText;
    self.textInput.delegate = self;
    
    [self.segmentColor addTarget:self action:@selector(changeColor:) forControlEvents:UIControlEventValueChanged];
    colors = @[[UIColor redColor], [UIColor orangeColor], [UIColor yellowColor], [UIColor greenColor], [UIColor cyanColor], [UIColor blueColor], [UIColor purpleColor], [UIColor whiteColor], [UIColor grayColor], [UIColor blackColor]];
    colorNames = @[@"red", @"orange", @"yellow", @"green", @"cyan", @"blue", @"purple", @"white", @"gray", @"black"];
    [self setDefault];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.dragging) {
        [self.view endEditing:YES];
    }
}

- (void)textViewDidChange:(UITextView *)textView {
    if (textView.text.length > 0) {
        self.labelPreview.text = textView.text;
    }else {
        self.labelPreview.text = @"北大车协 CAPU";
    }
    [self updateLabel];
}

- (void)updateLabel {
    NSArray *fontSizes = @[@10, @13, @16, @18, @24, @32];
    NSArray *fontNames = @[@"ArialMT", @"Arial-BoldMT"];
    textPreview = [[NSMutableAttributedString alloc] initWithString:self.labelPreview.text];
    int size = [[fontSizes objectAtIndex:fontSize-1] intValue];
    NSRange range = NSMakeRange(0, self.labelPreview.text.length);
    
    [textPreview addAttribute:NSForegroundColorAttributeName value:[colors objectAtIndex:color] range:range];
    if ([[colorNames objectAtIndex:color] isEqualToString:@"white"]) {
        [self.labelPreview setBackgroundColor:[UIColor lightGrayColor]];
    }else {
        [self.labelPreview setBackgroundColor:[UIColor whiteColor]];
    }
    UIFontDescriptor *desc = [UIFontDescriptor fontDescriptorWithName:[fontNames objectAtIndex:isBold] size:size];
    if (isItalics) {
        CGAffineTransform matrix = CGAffineTransformMake(1, 0, tanf(15 * (CGFloat)M_PI / 180), 1, 0, 0);
        desc = [UIFontDescriptor fontDescriptorWithName:[fontNames objectAtIndex:isBold] matrix:matrix];
    }
    [textPreview addAttribute:NSFontAttributeName value:[UIFont fontWithDescriptor:desc size:size] range:range];
    if (isUnderscore) {
        [textPreview addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:range];
    }
    if (isDelete) {
        [textPreview addAttribute:NSStrikethroughStyleAttributeName value:@(NSUnderlineStyleSingle) range:range];
    }
    
    //NSLog(@"Update Status");
    self.labelPreview.attributedText = textPreview;
}

- (void)setDefault {
    color = 9;
    fontSize = 3;
    isBold = NO;
    isItalics = NO;
    isUnderscore = NO;
    isDelete = NO;
    [self.segmentColor setSelectedSegmentIndex:color];
    [self.sliderSize setValue:fontSize];
    self.labelSize.text = [NSString stringWithFormat:@"%d号", fontSize];
    self.labelDefault.hidden = NO;
    [self.switchBold setOn:isBold];
    [self.switchItalics setOn:isItalics];
    [self.switchUnderscore setOn:isUnderscore];
    [self.switchDelete setOn:isDelete];
    [self textViewDidChange:self.textInput];
}

- (void)changeColor:(UISegmentedControl *)sender {
    color = (int)sender.selectedSegmentIndex;
    [self updateLabel];
}

- (IBAction)changeSize:(UISlider *)sender {
    int oriSize = fontSize;
    fontSize = round(sender.value);
    [sender setValue:fontSize];
    if (fontSize != oriSize) {
        self.labelSize.text = [NSString stringWithFormat:@"%d号", fontSize];
        self.labelDefault.hidden = (fontSize != 3);
        [self updateLabel];
    }
}

- (IBAction)changeBold:(id)sender {
    isBold = self.switchBold.isOn;
    [self updateLabel];
}

- (IBAction)changeItalics:(id)sender {
    isItalics = self.switchItalics.isOn;
    [self updateLabel];
}

- (IBAction)changeUnderscore:(id)sender {
    isUnderscore = self.switchUnderscore.isOn;
    [self updateLabel];
}

- (IBAction)changeDelete:(id)sender {
    isDelete = self.switchDelete.isOn;
    [self updateLabel];
}

- (IBAction)addText:(id)sender {
    if (self.textInput.text.length == 0) {
        [[[UIAlertView alloc] initWithTitle:@"错误" message:@"您还未输入正文内容！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil] show];
        [self.textInput becomeFirstResponder];
    }else {
        [self postText];
        [[[UIAlertView alloc] initWithTitle:@"插入成功" message:@"请选择操作" delegate:self cancelButtonTitle:@"继续插入" otherButtonTitles:@"返回发帖", nil] show];
    }
}

- (void)postText {
    NSString *text = self.textInput.text;
    text = [NSString stringWithFormat:@"[size=%d][color=%@]%@[/color][/size]", fontSize, [colorNames objectAtIndex:color], text];
    if (isBold) {
        text = [NSString stringWithFormat:@"[b]%@[/b]", text];
    }
    if (isItalics) {
        text = [NSString stringWithFormat:@"[i]%@[/i]", text];
    }
    if (isUnderscore) {
        text = [NSString stringWithFormat:@"<u>%@</u>", text];
    }
    if (isDelete) {
        text = [NSString stringWithFormat:@"<strike>%@</strike>", text];
    }
    [NOTIFICATION postNotificationName:@"addContent" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:text, @"HTML", nil]];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == alertView.cancelButtonIndex) {
        if ([alertView.title isEqualToString:@"插入成功"]) {
            [[[UIAlertView alloc] initWithTitle:@"继续插入" message:@"是否清空已输入内容？" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"清空", nil] show];
        }
        return;
    }
    if ([alertView.title isEqualToString:@"插入成功"]) {
        [self.navigationController popViewControllerAnimated:YES];
    }else if ([alertView.title isEqualToString:@"继续插入"]) {
        self.textInput.text = @"";
    }
}

#pragma mark - Table view data source

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 1) {
        [self setDefault];
        if (!hud && self.navigationController) {
            hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
            [self.navigationController.view addSubview:hud];
        }
        hud.labelText = @"恢复默认";
        [hud show:YES];
        hud.mode = MBProgressHUDModeCustomView;
        hud.customView = [[UIImageView alloc] initWithImage:SUCCESSMARK];
        [hud hide:YES afterDelay:0.5];
    }
}

@end
