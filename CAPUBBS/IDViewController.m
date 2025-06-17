//
//  IDViewController.m
//  CAPUBBS
//
//  Created by 范志康 on 15/3/11.
//  Copyright (c) 2015年 熊典. All rights reserved.
//

#import "IDViewController.h"
#import "AnimatedImageView.h"
#import "IDCell.h"

@interface IDViewController ()

@end

@implementation IDViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = GRAY_PATTERN;
    self.preferredContentSize = CGSizeMake(400, 0);
    if (!IS_SUPER_USER) {
        self.navigationItem.rightBarButtonItems = @[self.buttonLogout];
    }
    [NOTIFICATION addObserver:self selector:@selector(userChanged:) name:@"userChanged" object:nil];
    [NOTIFICATION addObserver:self selector:@selector(userChanged:) name:@"infoRefreshed" object:nil];
    performer = [[ActionPerformer alloc] init];
    [self userChanged:nil];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return MIN(ID_NUM - isDelete, data.count + 1);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    IDCell *cell;
    if (indexPath.row < data.count) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"id" forIndexPath:indexPath];
        cell.labelText.text = data[indexPath.row][@"id"];
        if ([cell.labelText.text isEqualToString:UID] && [ActionPerformer checkLogin:NO]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            cell.userInteractionEnabled = NO;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.userInteractionEnabled = YES;
        }
        [cell.icon setUrl:data[indexPath.row][@"icon"]];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"new" forIndexPath:indexPath];
    }
    // Configure the cell...
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    return [NSString stringWithFormat:@"您目前共存有%d个账号", (int)data.count];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section{
    return [NSString stringWithFormat:@"您最多可以存%d个账号", ID_NUM];
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    if (indexPath.row < data.count) {
        return YES;
    } else {
        return NO;
    }
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [data removeObjectAtIndex:indexPath.row];
        [DEFAULTS setObject:data forKey:@"ID"];
        // Delete the row from the data source
        isDelete = YES;
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        isDelete = NO;
        if (data.count + 1 == MAX_ID_NUM) {
            [self.tableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.5];
        }
    }  
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (IBAction)logIn:(id)sender {
    IDCell *lastCell = nil; // 当前登录的账号最后一次登录
    for (int i = 0; i < data.count; i++) {
        IDCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
            lastCell = cell;
        } else {
            [self performSegueWithIdentifier:@"login" sender:cell];
        }
    }
    if (lastCell) {
        [self performSegueWithIdentifier:@"login" sender:lastCell];
    }
}

- (IBAction)logOut:(id)sender {
    [self showAlertWithTitle:@"警告" message:@"您确定要注销当前账号吗？" confirmTitle:@"确定" confirmAction:^(UIAlertAction *action) {
        [performer performActionWithDictionary:nil toURL:@"logout" withBlock:^(NSArray *result, NSError *err) {}];
        NSLog(@"Logout - %@", UID);
        [GROUP_DEFAULTS removeObjectForKey:@"uid"];
        [GROUP_DEFAULTS removeObjectForKey:@"pass"];
        [GROUP_DEFAULTS removeObjectForKey:@"token"];
        [GROUP_DEFAULTS removeObjectForKey:@"userInfo"];
        dispatch_main_async_safe(^{
            [NOTIFICATION postNotificationName:@"userChanged" object:nil userInfo:nil];
        });
    }];
}

- (IBAction)back:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)userChanged:(NSNotification*)noti {
    dispatch_main_async_safe(^{
        data = [[DEFAULTS objectForKey:@"ID"] mutableCopy];
        isDelete = NO;
        self.buttonLogout.enabled = ([UID length] > 0);
        [self.tableView reloadData];
    });
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"login"]) {
        InternalLoginViewController *dest = [segue destinationViewController];
        NSIndexPath *indexPath = [self.tableView indexPathForCell:(UITableViewCell *)sender];
        dest.defaultUid = data[indexPath.row][@"id"];
        dest.defaultPass = data[indexPath.row][@"pass"];
    }
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

@end
