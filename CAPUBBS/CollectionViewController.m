//
//  CollectionViewController.m
//  CAPUBBS
//
//  Created by 范志康 on 15/11/10.
//  Copyright © 2015年 熊典. All rights reserved.
//

#import "CollectionViewController.h"
#import "CollectionViewCell.h"
#import "ContentViewController.h"

#define SORT_BY_COLLECTION_DATE 0
#define SORT_BY_BOARD_INDEX 1
#define SORT_BY_AUTHOR 2

@interface CollectionViewController ()

@end

@implementation CollectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = GREEN_BACK;
    if ([[DEFAULTS objectForKey:@"simpleView"] boolValue] == NO) {
        AsyncImageView *backgroundView = [[AsyncImageView alloc] init];
        [backgroundView setBlurredImage:[UIImage imageNamed:@"bcollection"] animated:NO];
        [backgroundView setContentMode:UIViewContentModeScaleAspectFill];
        self.tableView.backgroundView = backgroundView;
    }
    
    [NOTIFICATION addObserver:self selector:@selector(refresh) name:@"collectionChanged" object:nil];
    sortType = [[DEFAULTS objectForKey:@"viewCollectionType"] intValue];
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.delegate = self;
    self.searchController.searchResultsUpdater = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    if (IOS > 9.0) {
        self.searchController.hidesNavigationBarDuringPresentation = NO;
    }
    [self.searchController.searchBar sizeToFit];
    self.searchController.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchController.searchBar.placeholder = @"搜索";
    self.searchController.searchBar.delegate = self;
    
    self.tableView.tableHeaderView = self.searchController.searchBar;
    self.definesPresentationContext = YES;
    // self.tableView.backgroundView = [[UIView alloc] init]; // 否则顶部颜色不一样
    
    [self refresh];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // 恢复上次的搜索状态
    if (lastSearch.length > 0) {
        [self.searchController setActive:YES];
    }
    
    if (![[DEFAULTS objectForKey:@"FeatureCollection3.2"] boolValue]) {
        [[[UIAlertView alloc] initWithTitle:@"新功能！" message:@"在帖子里添加/删除个人收藏\n点右上角以管理个人收藏\niOS 9及更高可以在系统中搜索收藏" delegate:nil cancelButtonTitle:@"我知道了" otherButtonTitles:nil, nil] show];
        [DEFAULTS setObject:[NSNumber numberWithBool:YES] forKey:@"FeatureCollection3.2"];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setToolbarHidden:NO];
    
    // 记住上次的搜索状态
    if (self.searchController.isActive) {
        lastSearch = self.searchController.searchBar.text;
        wasFirstResponder = self.searchController.searchBar.isFirstResponder;
        [self.searchController setActive:NO];
    }
}

- (void)didPresentSearchController:(UISearchController *)searchController {
    self.searchController.searchBar.text = lastSearch;
    if (wasFirstResponder) {
        [searchController.searchBar becomeFirstResponder];
    }else {
        [self updateSearchResultsForSearchController:searchController];
    }
}

- (void)refresh {
    // 先按收藏日期进行一次排序
    data = [NSMutableArray arrayWithArray:[[DEFAULTS objectForKey:@"collection"] sortedArrayUsingComparator:(NSComparator)^(id obj1, id obj2) {
        NSString *val1 = [obj1 objectForKey:@"collectionTime"];
        NSString *val2 = [obj2 objectForKey:@"collectionTime"];
        return [val2 compare:val1];
    }]];
    [self sortData];
    
    if (self.searchController.isActive) {
        [self updateSearchResultsForSearchController:self.searchController];
    }else {
        [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
    }
}

- (void)sortData {
    if (!sortData) {
        sortData = [[NSMutableArray alloc] init];
    }
    
    if (sortType == SORT_BY_BOARD_INDEX) {
        data = [NSMutableArray arrayWithArray:[data sortedArrayUsingComparator:(NSComparator)^(id obj1, id obj2) {
            NSString *val1 = [obj1 objectForKey:@"bid"];
            NSString *val2 = [obj2 objectForKey:@"bid"];
            return [val1 compare:val2 options:NSNumericSearch];
        }]];
        
        [self indexByKeyword:@"bid"];
    }
    
    if (sortType == SORT_BY_AUTHOR) {
        data = [NSMutableArray arrayWithArray:[data sortedArrayUsingComparator:(NSComparator)^(id obj1, id obj2) {
            NSString *val1 = [obj1 objectForKey:@"author"];
            NSString *val2 = [obj2 objectForKey:@"author"];
            return [val1 localizedCompare:val2]; // 考虑汉字
        }]];
        
        [self indexByKeyword:@"author"];
    }
}

- (void)indexByKeyword:(NSString *)keyword {
    [sortData removeAllObjects];
    NSString *nowBid;
    NSMutableArray *nowArray = [[NSMutableArray alloc] init];
    for (NSDictionary *dict in data) {
        if (![dict[keyword] isEqualToString:nowBid]) {
            if (nowBid.length > 0) {
                [sortData addObject:[NSArray arrayWithArray:nowArray]];
            }
            [nowArray removeAllObjects];
            nowBid = dict[keyword];
        }
        [nowArray addObject:dict];
    }
    [sortData addObject:[NSArray arrayWithArray:nowArray]];
}

- (IBAction)organize:(id)sender {
    // 处理搜索时的Index
    if (self.tableView.isEditing) {
        [self.tableView setEditing:NO animated:YES];
        [self.navigationController setToolbarHidden:YES animated:YES];
        return;
    }
    UIAlertController *action = [UIAlertController alertControllerWithTitle:@"个人收藏" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [action addAction:[UIAlertAction actionWithTitle:@"按收藏日期查看" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        sortType = SORT_BY_COLLECTION_DATE;
        [DEFAULTS setObject:[NSNumber numberWithInt:sortType] forKey:@"viewCollectionType"];
        [self refresh];
    }]];
    [action addAction:[UIAlertAction actionWithTitle:@"按讨论板块查看" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        sortType = SORT_BY_BOARD_INDEX;
        [DEFAULTS setObject:[NSNumber numberWithInt:sortType] forKey:@"viewCollectionType"];
        [self refresh];
    }]];
    [action addAction:[UIAlertAction actionWithTitle:@"按文章作者查看" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        sortType = SORT_BY_AUTHOR;
        [DEFAULTS setObject:[NSNumber numberWithInt:sortType] forKey:@"viewCollectionType"];
        [self refresh];
    }]];
    [action addAction:[UIAlertAction actionWithTitle:@"管理收藏" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self.navigationController setToolbarHidden:NO animated:YES];
        [self.tableView setEditing:YES animated:YES];
    }]];
    [action addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    action.popoverPresentationController.barButtonItem = self.buttonOrganize;
    [self presentViewController:action animated:YES completion:nil];
}

- (IBAction)clearAll:(id)sender {
    [[[UIAlertView alloc] initWithTitle:@"警告" message:@"确认删除所有个人收藏吗？\n删除操作不可逆" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确认", nil] show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == alertView.cancelButtonIndex) {
        return;
    }
    if ([alertView.title isEqualToString:@"警告"]) {
        [DEFAULTS removeObjectForKey:@"collection"];
        [self.tableView setEditing:NO];
        [self.navigationController setToolbarHidden:YES animated:YES];
        [NOTIFICATION postNotificationName:@"collectionChanged" object:nil];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.searchController.searchBar.text.length > 0) {
        return 1;
    }
    if (sortType == SORT_BY_COLLECTION_DATE) {
        return 1;
    }
    if (sortType == SORT_BY_BOARD_INDEX || sortType == SORT_BY_AUTHOR) {
        return sortData.count;
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.searchController.searchBar.text.length > 0) {
        return searchData.count;
    }
    if (sortType == SORT_BY_COLLECTION_DATE) {
        return data.count;
    }
    if (sortType == SORT_BY_BOARD_INDEX || sortType == SORT_BY_AUTHOR) {
        return [[sortData objectAtIndex:section] count];
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (self.searchController.searchBar.text.length > 0) {
        if (searchData.count == 0) {
            return @"没有搜索结果";
        }else {
            return [NSString stringWithFormat:@"搜索到%d个结果", (int)searchData.count];
        }
    }
    if (data.count == 0) {
        return @"您还没有收藏";
    }
    if (sortType == SORT_BY_COLLECTION_DATE) {
        return [NSString stringWithFormat:@"您一共有%d个收藏", (int)data.count];
    }
    if (sortType == SORT_BY_BOARD_INDEX) {
        return [ActionPerformer getBoardTitle:[[[sortData objectAtIndex:section] firstObject] objectForKey:@"bid"]];
    }
    if (sortType == SORT_BY_AUTHOR) {
        return [[[sortData objectAtIndex:section] firstObject] objectForKey:@"author"];
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CollectionViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"collection" forIndexPath:indexPath];
    // Configure the cell...
    NSDictionary *dict;
    if (self.searchController.searchBar.text.length > 0) {
        dict = [searchData objectAtIndex:indexPath.row];
    }else if (sortType == SORT_BY_COLLECTION_DATE) {
        dict = data[indexPath.row];
    }else if (sortType == SORT_BY_BOARD_INDEX || sortType == SORT_BY_AUTHOR) {
        dict = [[sortData objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    }
    cell.infoDict = dict;
    
    cell.labelTitle.text = dict[@"title"];
    
    if (sortType == SORT_BY_AUTHOR) {
        cell.labelSubtitle.text = [ActionPerformer getBoardTitle:dict[@"bid"]];
    }
    if (sortType == SORT_BY_COLLECTION_DATE || sortType == SORT_BY_BOARD_INDEX) {
        cell.labelSubtitle.text = ([dict[@"author"] length] > 0) ? dict[@"author"] : @"未知";
    }
    
    if ([dict[@"text"] length] == 0) {
        cell.labelInfo.text = @"查看楼主楼层后即可显示";
    }else {
        cell.labelInfo.text = dict[@"text"];
    }
    
    [cell.icon.layer setCornerRadius:cell.icon.frame.size.width / 2]; // 圆形
    if (sortType == SORT_BY_AUTHOR) {
        [cell.icon setUrl:dict[@"icon"]];
    }
    if (sortType == SORT_BY_COLLECTION_DATE || sortType == SORT_BY_BOARD_INDEX) {
        [cell.icon setImage:[UIImage imageNamed:[NSString stringWithFormat:@"b%@", dict[@"bid"]]]];
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        CollectionViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        NSUInteger sectionCount = sortData.count;
        [data removeObject:cell.infoDict];
        [searchData removeObject:cell.infoDict];
        [self sortData];
        
        if (!self.searchController.isActive && sectionCount != sortData.count) {
            [tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
        }else {
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
        [DEFAULTS setObject:data forKey:@"collection"];
        [self performSelector:@selector(commitDelete) withObject:nil afterDelay:0.5];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
}

- (void)commitDelete {
    [NOTIFICATION postNotificationName:@"collectionChanged" object:nil];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Search

// 搜索时触发的方法
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    if (!searchData) {
        searchData = [[NSMutableArray alloc] init];
    }
    [searchData removeAllObjects];
    NSString *word = searchController.searchBar.text;
    if (word.length > 0) {
        NSArray *keywords = [word componentsSeparatedByString:@" "]; // 多关键字以空格分开
        for (NSDictionary *dict in data) {
            BOOL isAnswer = YES;
            for (NSString *keyword in keywords) {
                if (keyword.length > 0 && !([dict[@"title"] containsString:keyword] || [dict[@"author"] containsString:keyword] || [dict[@"text"] containsString:keyword])) {
                    isAnswer = NO;
                    break;
                }
            }
            if (isAnswer) {
                [searchData addObject:dict];
            }
        }
    }
    [self.tableView reloadData];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    searchBar.placeholder = @"关键词以空格隔开";
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    searchBar.placeholder = @"搜索";
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    lastSearch = nil;
    wasFirstResponder = NO;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"post"]) {
        ContentViewController *dest = [segue destinationViewController];
        CollectionViewCell *cell = (CollectionViewCell *)sender;
        NSDictionary *one = cell.infoDict;
        dest.tid = [one objectForKey:@"tid"];
        dest.bid = [one objectForKey:@"bid"];
        dest.title = [one objectForKey:@"title"];
        dest.isCollection = YES;
    }
}

@end
