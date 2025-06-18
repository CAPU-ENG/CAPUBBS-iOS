//
//  TextViewController.m
//  CAPUBBS
//
//  Created by 范志康 on 15/3/29.
//  Copyright (c) 2015年 熊典. All rights reserved.
//

#import "TextViewController.h"

#define DEFAULT_COLOR 10
#define DEFAULT_FONT_SIZE 3


@interface TextViewController ()

@end

@implementation TextViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = GRAY_PATTERN;
    UIView *targetView = self.navigationController ? self.navigationController.view : self.view;
    hud = [[MBProgressHUD alloc] initWithView:targetView];
    [targetView addSubview:hud];
    
    [self.labelPreview.layer setCornerRadius:10.0];
    [self.labelPreview.layer setMasksToBounds:YES];
    [self.textInput.layer setCornerRadius:10.0];
    self.textInput.text = self.defaultText;
    self.textInput.delegate = self;
    [self.segmentColor addTarget:self action:@selector(changeColor:) forControlEvents:UIControlEventValueChanged];
    
    colors = @[[UIColor redColor], [UIColor orangeColor], [UIColor yellowColor], [UIColor greenColor], [UIColor cyanColor], [UIColor blueColor], [UIColor purpleColor], [UIColor whiteColor], [UIColor grayColor], [UIColor blackColor], [UIColor blackColor]];
    colorNames = @[@"red", @"orange", @"yellow", @"green", @"cyan", @"blue", @"purple", @"white", @"gray", @"black", @"default"];
    fontSizes = @[@10, @13, @16, @16, @18, @24, @32];
    fontNames = @[@"ArialMT", @"Arial-BoldMT"];
    
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
    [self updateLabel];
}

- (void)updateLabel {
    NSString *previewText = self.textInput.text.length > 0 ? self.textInput.text : @"北大车协 CAPU";
    NSMutableAttributedString *textPreview = [[NSMutableAttributedString alloc] initWithString:previewText];
    int size = [[fontSizes objectAtIndex:fontSize] intValue];
    NSRange range = NSMakeRange(0, textPreview.length);
    
    [textPreview addAttribute:NSForegroundColorAttributeName value:[colors objectAtIndex:color] range:range];
    if ([[colorNames objectAtIndex:color] isEqualToString:@"white"]) {
        [self.labelPreview setBackgroundColor:[UIColor lightGrayColor]];
    } else {
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

- (int)getActualFontSize {
    return fontSize >= 3 ? fontSize : fontSize + 1;
}

- (void)setFontLabel {
    if (fontSize == 3) {
        self.labelSize.text = @"默认";
    } else {
        self.labelSize.text = [NSString stringWithFormat:@"%d号", [self getActualFontSize]];
    }
}

- (void)setDefault {
    color = DEFAULT_COLOR;
    fontSize = DEFAULT_FONT_SIZE;
    isBold = NO;
    isItalics = NO;
    isUnderscore = NO;
    isDelete = NO;
    [self.segmentColor setSelectedSegmentIndex:color];
    [self.sliderSize setValue:fontSize];
    [self setFontLabel];
    [self.switchBold setOn:isBold];
    [self.switchItalics setOn:isItalics];
    [self.switchUnderscore setOn:isUnderscore];
    [self.switchDelete setOn:isDelete];
    [self updateLabel];
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
        [self setFontLabel];
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
    NSString *inputText = self.textInput.text;
    if (inputText.length == 0) {
        [self showAlertWithTitle:@"错误" message:@"您还未输入正文内容！" cancelAction:^(UIAlertAction *action) {
            [self.textInput becomeFirstResponder];
        }];
        return;
    }
    NSString *text = inputText;
    if (fontSize != DEFAULT_FONT_SIZE) {
        text = [NSString stringWithFormat:@"[size=%d]%@[/size]", [self getActualFontSize], text];
    }
    if (color != DEFAULT_COLOR) {
        text = [NSString stringWithFormat:@"[color=%@]%@[/color]", [colorNames objectAtIndex:color], text];
    }
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
    if ([text isEqualToString:inputText]) {
        [self showAlertWithTitle:@"错误" message:@"您还未选择任何字体样式"];
        return;
    }
    
    [NOTIFICATION postNotificationName:@"addContent" object:nil userInfo:@{ @"HTML" : text }];
    UIAlertController *action = [UIAlertController alertControllerWithTitle:@"插入成功" message:@"请选择下一步操作" preferredStyle:UIAlertControllerStyleAlert];
    [action addAction:[UIAlertAction actionWithTitle:@"清空输入继续" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.textInput.text = @"";;
        [self.textInput becomeFirstResponder];
    }]];
    [action addAction:[UIAlertAction actionWithTitle:@"直接继续" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.textInput becomeFirstResponder];
    }]];
    [action addAction:[UIAlertAction actionWithTitle:@"返回发帖" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self.navigationController popViewControllerAnimated:YES];
    }]];
    [self presentViewControllerSafe:action];
}

#pragma mark - Table view data source

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 1) {
        [self setDefault];
        [hud showAndHideWithSuccessMessage:@"恢复默认"];
    }
}

@end
