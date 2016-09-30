//
//  SearchViewController.m
//  CAPUBBS
//
//  Created by 范志康 on 15/3/6.
//  Copyright (c) 2015年 熊典. All rights reserved.
//

#import "SearchViewController.h"
#import "ContentViewController.h"

@interface SearchViewController ()

@end

@implementation SearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = GREEN_BACK;
    
    [self refreshBackgroundView:YES];
    [self.inputType setTintColor:GREEN_DARK];
    [self.inputText becomeFirstResponder];
    [self setDate];
    self.labelB.text = [ActionPerformer getBoardTitle:self.bid];
    control = [[UIRefreshControl alloc] init];
    [control addTarget:self action:@selector(refreshControlValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.tableview addSubview:control];
    performer = [[ActionPerformer alloc] init];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:YES];
}

- (void)refreshBackgroundView:(BOOL)noAnimation {
    if (SIMPLE_VIEW == NO) {
        if (!backgroundView) {
            backgroundView = [[AsyncImageView alloc] init];
            [backgroundView setContentMode:UIViewContentModeScaleAspectFill];
            [self.view addSubview:backgroundView];
            [self.view sendSubviewToBack:backgroundView];
            [backgroundView.layer setMasksToBounds:YES];
            [backgroundView setTranslatesAutoresizingMaskIntoConstraints:NO];
            int dir[4] = {NSLayoutAttributeTop, NSLayoutAttributeBottom, NSLayoutAttributeLeft, NSLayoutAttributeRight};
            for (int i = 0; i < 4; i++) {
                [self.view addConstraint:[NSLayoutConstraint constraintWithItem:backgroundView attribute:dir[i] relatedBy:NSLayoutRelationEqual toItem:self.view attribute:dir[i] multiplier:1.0 constant:0.0]];
            }
        }
        self.view.backgroundColor = [UIColor whiteColor];
        [backgroundView setBlurredImage:[UIImage imageNamed:[@"b" stringByAppendingString:self.bid]] animated:!noAnimation];
    }
}

- (void)refreshControlValueChanged:(UIRefreshControl *)refreshControl {
    control.attributedTitle = [[NSAttributedString alloc] initWithString:@"刷新"];
    [self search:nil];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (void)setDate { // 两个日期选择器
    NSDate *today = [NSDate date];
    formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    beginTime = @"2001-01-01";
    endTime = [formatter stringFromDate:today];
    NSDate *minDate = [formatter dateFromString:@"1995-10-25"];
    startDatePicker = [[UIDatePicker alloc] init];
    endDatePicker = [[UIDatePicker alloc] init];
    for (UIDatePicker *picker in @[startDatePicker, endDatePicker]) {
        picker.datePickerMode = UIDatePickerModeDate;
        picker.minimumDate = minDate;
        picker.maximumDate = today;
        [picker addTarget:self action:@selector(ValueChanged:) forControlEvents:UIControlEventValueChanged];
    }
    [startDatePicker setDate:[formatter dateFromString:beginTime] animated:YES];
    [endDatePicker setDate:today animated:YES];
    startDatePicker.tag = 0;
    endDatePicker.tag = 1;
    self.inputStart.inputView = startDatePicker;
    self.inputEnd.inputView = endDatePicker;
    UIToolbar *toolbar1 = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 1000, 40)];
    UIToolbar *toolbar2 = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 1000, 40)];
    UIBarButtonItem *jump1 = [[UIBarButtonItem alloc] initWithTitle:@"下一个" style:UIBarButtonItemStylePlain target:self action:@selector(next1)];
    UIBarButtonItem *jump2 = [[UIBarButtonItem alloc] initWithTitle:@"上一个" style:UIBarButtonItemStylePlain target:self action:@selector(next2)];
    UIBarButtonItem *blank = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *cancel1 = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(cancel1)];
    UIBarButtonItem *cancel2 = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(cancel2)];
    UIBarButtonItem *done1 = [[UIBarButtonItem alloc] initWithTitle:@"完成" style:UIBarButtonItemStylePlain target:self action:@selector(sure1)];
    UIBarButtonItem *done2 = [[UIBarButtonItem alloc] initWithTitle:@"完成" style:UIBarButtonItemStylePlain target:self action:@selector(sure2)];
    toolbar1.items = @[jump1, blank, cancel1, done1];
    self.inputStart.inputAccessoryView = toolbar1;
    toolbar2.items = @[jump2, blank, cancel2, done2];
    self.inputEnd.inputAccessoryView = toolbar2;
}

- (void)cancel1 {
    [self.inputStart resignFirstResponder];
}

- (void)cancel2 {
    [self.inputEnd resignFirstResponder];
}

- (void)next1 {
    self.inputStart.text = [formatter stringFromDate:startDatePicker.date];
    [self.inputStart resignFirstResponder];
    [self.inputEnd becomeFirstResponder];
}

- (void)next2 {
    self.inputEnd.text = [formatter stringFromDate:endDatePicker.date];
    [self.inputEnd resignFirstResponder];
    [self.inputStart becomeFirstResponder];
}

- (void)sure1 {
    self.inputStart.text = [formatter stringFromDate:startDatePicker.date];
    [self.inputStart resignFirstResponder];
}

- (void)sure2 {
    self.inputEnd.text = [formatter stringFromDate:endDatePicker.date];
    [self.inputEnd resignFirstResponder];
}

- (void)ValueChanged:(UIDatePicker *)datePicker{
    if (datePicker.tag == 0)
        self.inputStart.text = [formatter stringFromDate:datePicker.date];
    else if (datePicker.tag == 1)
        self.inputEnd.text = [formatter stringFromDate:datePicker.date];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return searchResult.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (searchResult.count > 0) {
        return @"搜索结果";
    }else {
        return nil;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (searchResult.count > 0) {
        return [NSString stringWithFormat:@"共有%d条结果", (int)searchResult.count];
    }else {
        return nil;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *dict = [searchResult objectAtIndex:indexPath.row];
    SearchViewCell *cell = [self.tableview dequeueReusableCellWithIdentifier:@"resultlist"];
    NSString *titleText = dict[@"text"];
    titleText = [ActionPerformer removeRe:titleText];
    cell.titleText.text = titleText;
    cell.authorText.text = dict[@"author"];
    cell.timeText.text = dict[@"time"];
    // Configure the cell...
    return cell;
}

- (IBAction)didEndOnExit:(id)sender {
    [self search:nil];
}

- (IBAction)search:(id)sender {
    [self.view endEditing:YES];
    text = self.inputText.text;
    author = self.inputAuthor.text;
    if (self.inputStart.text.length > 0) {
        beginTime = self.inputStart.text;
    }
    if (self.inputEnd.text.length > 0) {
        endTime = self.inputEnd.text;
    }
    if (self.inputType.selectedSegmentIndex == 0) {
        type = @"thread";
    }else {
        type = @"post";
    }
    if (text.length == 0 && author.length == 0) {
        [[[UIAlertView alloc] initWithTitle:@"警告" message:@"没有输入搜索内容！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil] show];
        [self.inputText becomeFirstResponder];
        if (control.isRefreshing) {
            [control endRefreshing];
        }
        return;
    }
    if (text.length == 0) { // 空内容 按作者搜索
        type = @"post";
        [self.inputType setSelectedSegmentIndex:1];
    }
    NSDate *begin = [formatter dateFromString:beginTime];
    NSDate *end = [formatter dateFromString:endTime];
    NSTimeInterval earlyDate = [begin timeIntervalSince1970]*1;
    NSTimeInterval lateDate = [end timeIntervalSince1970]*1;
    if (earlyDate - lateDate > 0) {
        [[[UIAlertView alloc] initWithTitle:@"警告" message:@"日期输入有误！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil] show];
        if (control.isRefreshing) {
            [control endRefreshing];
        }
        return;
    }
    // NSLog(@"Search Text:%@, Type:%@, BT:%@, ET:%@, Author:%@ Bid:%@", text, type, beginTime, endTime, author, self.b);
    if (!hud && self.navigationController) {
        hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
        [self.navigationController.view addSubview:hud];
    }
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = @"正在搜索";
    [hud show:YES];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:type, @"type", self.bid, @"bid", text, @"text", beginTime, @"starttime", endTime, @"endtime", author, @"username", nil];
    [performer performActionWithDictionary:dict toURL:@"search" withBlock:^(NSArray *result, NSError *err) {
        if (control.isRefreshing) {
            [control endRefreshing];
        }
        if (err || result.count == 0) {
            searchResult=nil;
            hud.customView = [[UIImageView alloc] initWithImage:FAILMARK];
            hud.labelText = @"搜索失败";
            hud.mode = MBProgressHUDModeCustomView;
            [hud hide:YES afterDelay:0.5];
            NSLog(@"%@",err);
            return;
        }
        hud.customView = [[UIImageView alloc] initWithImage:SUCCESSMARK];
        hud.labelText = @"搜索成功";
        hud.mode = MBProgressHUDModeCustomView;
        [hud hide:YES afterDelay:0.5];
        searchResult=[result subarrayWithRange:NSMakeRange(1, result.count-1)];
        // NSLog(@"Search Result:%@", searchResult);
        if (searchResult.count == 0) {
            [[[UIAlertView alloc] initWithTitle:@"没有结果" message:@"请尝试更换关键词、日期或讨论区" delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil] show];
        }else {
            [self.tableview reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }];
}

- (IBAction)chooseB:(id)sender {
    UIAlertController *action = [UIAlertController alertControllerWithTitle:@"请选择要搜索的讨论区" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    for (int i = 0; i < 9; i++) {
        [action addAction:[UIAlertAction actionWithTitle:[ActionPerformer getBoardTitle:[NUMBERS objectAtIndex:i]] style:([self.bid isEqualToString:[NUMBERS objectAtIndex:i]]) ? UIAlertActionStyleDestructive : UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            if (![ActionPerformer checkLogin:NO] && i == 0) {
                [[[UIAlertView alloc] initWithTitle:@"警告" message:@"您未登录，不能搜索工作区！" delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil] show];
            }else {
                self.bid = [NUMBERS objectAtIndex:i];
                self.labelB.text = [ActionPerformer getBoardTitle:self.bid];
                [self refreshBackgroundView:NO];
            }
        }]];
    }
    [action addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    action.popoverPresentationController.sourceView = self.labelB;
    action.popoverPresentationController.sourceRect = self.labelB.bounds;
    [self presentViewController:action animated:YES completion:nil];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"post"]) {
        ContentViewController *dest = [segue destinationViewController];
        NSDictionary *one = [searchResult objectAtIndex:[self.tableview indexPathForCell:(UITableViewCell *)sender].row];
        dest.bid = [one objectForKey:@"bid"];
        dest.tid = [one objectForKey:@"tid"];
        if ([one objectForKey:@"floor"]) {
            dest.floor = [one objectForKey:@"floor"];
        }
        if ([one objectForKey:@"title"]) {
            dest.title = [one objectForKey:@"title"];
        }else {
            dest.title = [one objectForKey:@"text"];
        }
        [self.navigationController setToolbarHidden:NO];
    }
}

@end
