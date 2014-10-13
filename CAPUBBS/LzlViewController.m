//
//  LzlViewController.m
//  CAPUBBS
//
//  Created by XiongDian on 14/9/21.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import "LzlViewController.h"
#import "LzlCell.h"

@interface LzlViewController ()

@end

@implementation LzlViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    [self refresh];
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(void)refresh{
    performer=[[ActionPerformer alloc] init];
    [performer performActionWithDictionary:@{@"fid":self.fid,@"method":@"show"} toURL:@"lzl" withBlock:^(NSArray *result, NSError *err) {
        if (err) {
            return;
        }
        data=[result subarrayWithRange:NSMakeRange(1, result.count-1)];
        [self.tableView reloadData];
    }];

}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if (section==0) {
        return data.count;
    }else{
        return 1;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section==0) {
        LzlCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
        NSDictionary *currentObj=[data objectAtIndex:indexPath.row];
        
        cell.textAuthor.text=[currentObj objectForKey:@"author"];
        cell.textTime.text=[currentObj objectForKey:@"time"];
        cell.textMain.text=[currentObj objectForKey:@"text"];
        return cell;
    }else if (indexPath.section==1){
        UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:@"button" forIndexPath:indexPath];
        return cell;
    }else{
        return nil;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section==0) {
        NSString *text = [[data objectAtIndex:[indexPath row]] objectForKey:@"text"];
        
        //下句中(CELL_CONTENT_WIDTH - (CELL_CONTENT_MARGIN * 2)  表示显示内容的label的长度 ，20000.0f 表示允许label的最大高度
        CGSize constraint = CGSizeMake(self.view.frame.size.width - 12-30, 20000.0f);
        CGSize size = [text sizeWithFont:[UIFont systemFontOfSize:16] constrainedToSize:constraint lineBreakMode:NSLineBreakByWordWrapping];
        
        CGFloat height = MAX(size.height, 14.0f);
        
        return height + 34;
    }else if (indexPath.section==1){
        return 44;
    }
    return 44;
}

-(NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section{
    if (section==0) {
        if (!data) {
            return @"正在加载……";
        }else if (data.count==0){
            return @"暂时木有楼中楼";
        }
        return [NSString stringWithFormat:@"共有%d条楼中楼",data.count];
    }else{
        return @"";
    }
    
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if (section==0) {
        return @"您正在查看此楼层的楼中楼";
    }else{
        return @"";
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section==1) {
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"发表楼中楼" message:@"请输入要发表的楼中楼内容" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"发布", nil];
        alert.tag=0;
        alert.alertViewStyle=UIAlertViewStylePlainTextInput;
        [alert show];
    }
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex==alertView.cancelButtonIndex) {
        return;
    }
    if (alertView.tag==0) {
        hud=[[MBProgressHUD alloc] initWithView:self.navigationController.view];
        hud.labelText=@"正在发布";
        [self.navigationController.view addSubview:hud];
        [hud show:YES];
        performer=[[ActionPerformer alloc] init];
        [performer performActionWithDictionary:@{@"method":@"post",@"fid":self.fid,@"text":[alertView textFieldAtIndex:0].text} toURL:@"lzl" withBlock:^(NSArray *result, NSError *err) {
            if (err) {
                hud.labelText=@"发布失败";
                hud.mode=MBProgressHUDModeText;
            }else{
                if ([[[result firstObject] objectForKey:@"code"] integerValue]==0) {
                    hud.labelText=@"成功";
                    hud.customView=[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark"]];
                    hud.mode=MBProgressHUDModeCustomView;
                    [self performSelector:@selector(refresh) withObject:nil afterDelay:0.5];
                }else{
                    hud.labelText=[[result firstObject] objectForKey:@"msg"];
                    hud.mode=MBProgressHUDModeText;
                }
            }
            [hud hide:YES afterDelay:0.5];
        }];
    }
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}



// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        
        hud=[[MBProgressHUD alloc] initWithView:self.navigationController.view];
        hud.labelText=@"正在处理";
        [self.navigationController.view addSubview:hud];
        [hud show:YES];

        performer=[[ActionPerformer alloc] init];
        [performer performActionWithDictionary:@{@"method":@"delete",@"fid":self.fid,@"id":[[data objectAtIndex:indexPath.row] objectForKey:@"id"]} toURL:@"lzl" withBlock:^(NSArray *result, NSError *err) {
            if (err) {
                NSLog(@"%@",err);
                hud.labelText=@"删除失败";
                hud.mode=MBProgressHUDModeText;
                [hud hide:YES afterDelay:0.5];
            }else{
                if ([[result.firstObject objectForKey:@"code"] integerValue]==0) {
                    [hud hide:YES];
                    NSMutableArray *temp=[NSMutableArray arrayWithArray:data];
                    [temp removeObjectAtIndex:indexPath.row];
                    data=[NSArray arrayWithArray:temp];
                    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                }else{
                    hud.labelText=[result.firstObject objectForKey:@"msg"];
                    hud.mode=MBProgressHUDModeText;
                    [hud hide:YES afterDelay:0.5];
                }
            }
            
        }];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
