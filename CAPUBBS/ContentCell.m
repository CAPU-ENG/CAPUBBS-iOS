//
//  ContentCell.m
//  CAPUBBS
//
//  Created by 熊典 on 14-2-17.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import "ContentCell.h"

@implementation ContentCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    [self.icon setRounded:YES];
    [self.webViewContainer.layer setCornerRadius:10.0];
    [self.webViewContainer.layer setBorderColor:GREEN_LIGHT.CGColor];
    [self.webViewContainer.layer setBorderWidth:1.0];
    [self.webViewContainer.layer setMasksToBounds:YES];
    [self.webViewContainer setBackgroundColor:[UIColor whiteColor]];
    [self.webViewContainer initiateWebViewForToken:nil];
    [self.webViewContainer.webView.scrollView setScrollEnabled:NO];
    [self.lzlTableView setBackgroundColor:[UIColor clearColor]];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    // 加载空HTML以快速清空，防止reuse后还短暂显示之前的内容
    [self.webViewContainer.webView loadHTMLString:EMPTY_HTML baseURL:[NSURL URLWithString:CHEXIE]];
    if (self.heightCheckTimer && [self.heightCheckTimer isValid]) {
        [self.heightCheckTimer invalidate];
    }
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath { 
    ContentLzlCell *cell = [tableView dequeueReusableCellWithIdentifier:@"lzl" forIndexPath:indexPath];
    NSDictionary *dict = self.lzlDetail[indexPath.row];
    cell.lzlAuthor.text = dict[@"author"];
    cell.lzlTime.text = dict[@"time"];
    // Fit into one line
    cell.lzlText.text = [dict[@"text"] stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    [cell.lzlIcon setUrl:dict[@"icon"]];
    
    if (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1) {
        cell.separatorInset = UIEdgeInsetsMake(0, 10000, 0, 0); // 隐藏
    } else {
        cell.separatorInset = UIEdgeInsetsZero; // 正常显示
    }
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.lzlDetail ? self.lzlDetail.count : 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.buttonLzl sendActionsForControlEvents:UIControlEventTouchUpInside];
}

@end

@implementation ContentLzlCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    [self.lzlIcon setRounded:YES];
}

@end
