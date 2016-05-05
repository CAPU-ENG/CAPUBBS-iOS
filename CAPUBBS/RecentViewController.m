//
//  RecentViewController.m
//  CAPUBBS
//
//  Created by 范志康 on 15/7/6.
//  Copyright (c) 2015年 熊典. All rights reserved.
//

#import "RecentViewController.h"
#import "ContentViewController.h"

@interface RecentViewController ()

@end

@implementation RecentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = GRAY_PATTERN;
    if (self.iconData.length > 0) {
        [self refreshBackgroundView:YES];
    }else {
        [NOTIFICATION addObserver:self selector:@selector(refresh:) name:[@"imageSet" stringByAppendingString:self.iconUrl] object:nil];
    }

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)refresh:(NSNotification *)noti {
    if (self.iconData.length == 0) {
        self.iconData = noti.userInfo[@"data"];
        [self performSelectorOnMainThread:@selector(refreshBackgroundView:) withObject:nil waitUntilDone:NO];
    }
}

- (void)refreshBackgroundView:(BOOL)noAnimation {
    if ([[DEFAULTS objectForKey:@"simpleView"] boolValue] == NO) {
        if (!backgroundView) {
            backgroundView = [[AsyncImageView alloc] init];
            [backgroundView setContentMode:UIViewContentModeScaleAspectFill];
            self.tableView.backgroundView = backgroundView;
        }
        [backgroundView setBlurredImage:[UIImage imageWithData:self.iconData] animated:!noAnimation];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return MAX(self.data.count, 1);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    if (self.data.count > 0) {
        cell.textLabel.text = [ActionPerformer removeRe:[[self.data objectAtIndex:indexPath.row] objectForKey:@"title"]];
        cell.detailTextLabel.text = [[self.data objectAtIndex:indexPath.row] objectForKey:@"time"];
    }else {
        cell.textLabel.text = [@"暂无" stringByAppendingString:self.title];
        cell.detailTextLabel.text = @"";
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.userInteractionEnabled = NO;
    }
    
    // Configure the cell...
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)dismiss:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"post"]) {
        ContentViewController *dest = [[[segue destinationViewController] viewControllers] firstObject];
        NSDictionary *dict = [self.data objectAtIndex:[self.tableView indexPathForCell:(UITableViewCell *)sender].row];
        dest.bid = dict[@"bid"];
        dest.tid = dict[@"tid"];
        dest.floor = dict[@"pid"];
        dest.title = dict[@"title"];
        dest.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
    }
}

- (void)done {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
