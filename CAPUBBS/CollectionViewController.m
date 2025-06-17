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
#define SORT_BY_POST_DATE 3

@interface CollectionViewController ()

@end

@implementation CollectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = GREEN_BACK;
    if (!SIMPLE_VIEW) {
        AnimatedImageView *backgroundView = [[AnimatedImageView alloc] init];
        [backgroundView setBlurredImage:[UIImage imageNamed:@"bcollection"] animated:NO];
        [backgroundView setContentMode:UIViewContentModeScaleAspectFill];
        self.tableView.backgroundView = backgroundView;
    }
    UIView *targetView = self.navigationController ? self.navigationController.view : self.view;
    hud = [[MBProgressHUD alloc] initWithView:targetView];
    [targetView addSubview:hud];
    
    [NOTIFICATION addObserver:self selector:@selector(refresh) name:@"collectionChanged" object:nil];
    sortType = [[DEFAULTS objectForKey:@"viewCollectionType"] intValue];
    
    self.searchController = [[CustomSearchController alloc] initWithSearchResultsController:nil];
    self.searchController.delegate = self;
    self.searchController.searchResultsUpdater = self;
    self.searchController.obscuresBackgroundDuringPresentation = NO;
    self.searchController.hidesNavigationBarDuringPresentation = NO;
    [self.searchController.searchBar sizeToFit];
    self.searchController.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchController.searchBar.placeholder = @"搜索";
    self.searchController.searchBar.delegate = self;
    
    self.tableView.tableHeaderView = self.searchController.searchBar;
    
    self.definesPresentationContext = YES;
    // self.tableView.backgroundView = [[UIView alloc] init]; // 否则顶部颜色不一样
    
    formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    NSTimeZone *beijingTimeZone = [NSTimeZone timeZoneWithName:@"Asia/Shanghai"];
    [formatter setTimeZone:beijingTimeZone];
    
    [self refresh];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self toggleEditMode:NO animated:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // 恢复上次的搜索状态
    if (lastSearch.length > 0) {
        [self.searchController setActive:YES];
    }
    
//    if (![[DEFAULTS objectForKey:@"FeatureCollection3.2"] boolValue]) {
//        [self showAlertWithTitle:@"新功能！" message:@"在帖子里添加/删除个人收藏\n点右上角以管理个人收藏" cancelTitle:@"我知道了"];
//        [DEFAULTS setObject:@(YES) forKey:@"FeatureCollection3.2"];
//    }
    if (![[DEFAULTS objectForKey:@"FeatureExport4.0"] boolValue]) {
        [self showAlertWithTitle:@"Tips" message:@"可以导出/导入收藏夹数据\n点右上角以管理个人收藏" cancelTitle:@"我知道了"];
        [DEFAULTS setObject:@(YES) forKey:@"FeatureExport4.0"];
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
    } else {
        [self updateSearchResultsForSearchController:searchController];
    }
}

- (void)toggleEditMode:(BOOL)editMode animated:(BOOL)animated {
    [self.tableView setEditing:editMode animated:animated];
    [self.navigationController setToolbarHidden:!editMode animated:animated];
    if (editMode) {
        [self updateActionAvailability];
        [self.navigationItem setRightBarButtonItems:@[self.buttonCancelOrganize] animated:animated];
    } else {
        [self.navigationItem setRightBarButtonItems:@[self.buttonOrganize] animated:animated];
    }
}

- (UIViewController *)getVcToShowAlert {
    if (self.searchController.isActive) {
        return self.searchController;
    }
    return self;
}

- (void)refresh {
    data = [[DEFAULTS objectForKey:@"collection"] mutableCopy];
    [self sortData];
    
    if (self.searchController.isActive) {
        [self updateSearchResultsForSearchController:self.searchController];
    } else {
        dispatch_main_async_safe(^{
            [self.tableView reloadData];
        });
    }
}

- (void)sortData {
    // 默认按收藏日期排序
    if (sortType != SORT_BY_POST_DATE) {
        [data sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            NSString *val1 = obj1[@"collectionTime"];
            NSString *val2 = obj2[@"collectionTime"];
            return [val2 compare:val1];
        }];
    }
    
    if (!sortData) {
        sortData = [[NSMutableArray alloc] init];
    }
    
    if (sortType == SORT_BY_POST_DATE) {
        [data sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            NSString *val1 = obj1[@"time"];
            NSString *val2 = obj2[@"time"];
            return [val2 compare:val1];
        }];
    } else if (sortType == SORT_BY_BOARD_INDEX) {
        [data sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            NSString *val1 = obj1[@"bid"];
            NSString *val2 = obj2[@"bid"];
            return [val1 compare:val2 options:NSNumericSearch];
        }];
        [self indexByKeyword:@"bid"];
    } else if (sortType == SORT_BY_AUTHOR) {
        [data sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            NSString *val1 = obj1[@"author"];
            NSString *val2 = obj2[@"author"];
            return [val1 localizedCompare:val2]; // 考虑汉字
        }];
        [self indexByKeyword:@"author"];
    }
}

- (void)indexByKeyword:(NSString *)keyword {
    [sortData removeAllObjects];
    NSString *nowValue;
    NSMutableArray *nowArray = [[NSMutableArray alloc] init];
    for (NSDictionary *dict in data) {
        NSString *value = dict[keyword];
        if (value.length == 0) {
            value = @"未知";
        }
        if (![value isEqualToString:nowValue]) {
            if (nowValue.length > 0) {
                [sortData addObject:[NSArray arrayWithArray:nowArray]];
            }
            [nowArray removeAllObjects];
            nowValue = value;
        }
        [nowArray addObject:dict];
    }
    [sortData addObject:[NSArray arrayWithArray:nowArray]];
}

- (IBAction)toggleOrganize:(id)sender {
    // 处理搜索时的Index
    if (self.tableView.isEditing) {
        [self toggleEditMode:NO animated:YES];
        return;
    }
    UIAlertController *action = [UIAlertController alertControllerWithTitle:@"个人收藏" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [action addAction:[UIAlertAction actionWithTitle:@"按收藏日期查看" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        sortType = SORT_BY_COLLECTION_DATE;
        [DEFAULTS setObject:@(sortType) forKey:@"viewCollectionType"];
        [self refresh];
    }]];
    [action addAction:[UIAlertAction actionWithTitle:@"按发帖日期查看" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        sortType = SORT_BY_POST_DATE;
        [DEFAULTS setObject:@(sortType) forKey:@"viewCollectionType"];
        [self refresh];
    }]];
    [action addAction:[UIAlertAction actionWithTitle:@"按讨论板块查看" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        sortType = SORT_BY_BOARD_INDEX;
        [DEFAULTS setObject:@(sortType) forKey:@"viewCollectionType"];
        [self refresh];
    }]];
    [action addAction:[UIAlertAction actionWithTitle:@"按文章作者查看" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        sortType = SORT_BY_AUTHOR;
        [DEFAULTS setObject:@(sortType) forKey:@"viewCollectionType"];
        [self refresh];
    }]];
    [action addAction:[UIAlertAction actionWithTitle:@"管理收藏" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self toggleEditMode:YES animated:YES];
    }]];
    [action addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    action.popoverPresentationController.barButtonItem = self.buttonOrganize;
    [[self getVcToShowAlert] presentViewControllerSafe:action];
}

- (IBAction)selectAll:(id)sender {
    for (NSInteger section = 0; section < [self.tableView numberOfSections]; section++) {
        for (NSInteger row = 0; row < [self.tableView numberOfRowsInSection:section]; row++) {
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section] animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
    }
    [self updateActionAvailability];
}

- (IBAction)selectReverse:(id)sender {
    NSSet<NSIndexPath *> *selectedRowsSet = [NSSet setWithArray:[self.tableView indexPathsForSelectedRows]];
    
    for (NSInteger section = 0; section < [self.tableView numberOfSections]; section++) {
        for (NSInteger row = 0; row < [self.tableView numberOfRowsInSection:section]; row++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
            if ([selectedRowsSet containsObject:indexPath]) {
                [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
            } else {
                [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            }
        }
    }
    [self updateActionAvailability];
}

- (IBAction)shareSelection:(id)sender {
    NSArray<NSDictionary *> *selectedData = [self getSelectedData];
    [[self getVcToShowAlert] showAlertWithTitle:@"提示" message:[NSString stringWithFormat:@"您将导出所选的%ld个收藏\n可以存为文件以备份，或使用AirDrop立即分享\n使用客户端打开导出的文件可以导入收藏", selectedData.count] confirmTitle:@"导出" confirmAction:^(UIAlertAction *action) {
        NSURL *fileUrl = [self exportCollectionsToFile:selectedData];
        if (!fileUrl) {
            [[self getVcToShowAlert] showAlertWithTitle:@"错误" message:@"创建导出文件失败"];
            return;
        }
        UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[fileUrl] applicationActivities:nil];
        activityViewController.popoverPresentationController.barButtonItem = self.buttonShare;
        activityViewController.completionWithItemsHandler = ^(UIActivityType  _Nullable activityType, BOOL completed, NSArray * _Nullable returnedItems, NSError * _Nullable activityError) {
            [MANAGER removeItemAtURL:fileUrl error:nil];
        };
        [[self getVcToShowAlert] presentViewControllerSafe:activityViewController];
    }];
}

- (IBAction)deleteSelection:(id)sender {
    NSArray<NSDictionary *> *selectedData = [self getSelectedData];
    [[self getVcToShowAlert] showAlertWithTitle:@"警告" message:[NSString stringWithFormat:@"确认删除所选的%ld个收藏吗？\n删除操作不可逆", selectedData.count] confirmTitle:@"删除" confirmAction:^(UIAlertAction *action) {
        for (NSDictionary *dict in selectedData) {
            [data removeObject:dict];
            [searchData removeObject:dict];
        }
        [DEFAULTS setObject:data forKey:@"collection"];
        [hud showAndHideWithSuccessMessage:@"删除完成"];
        [self performSelector:@selector(commitChange) withObject:nil afterDelay:0.5];
    }];
}

- (NSArray<NSDictionary *> *)getSelectedData {
    NSMutableArray *selectedData = [NSMutableArray array];
    for (NSIndexPath *indexPath in [self.tableView indexPathsForSelectedRows]) {
        [selectedData addObject:[self getCollectionDataForIndexPath:indexPath]];
    }
    return selectedData;
}

- (NSURL *)exportCollectionsToFile:(NSArray<NSDictionary *> *)collections {
    NSArray *wrappedData = @[
        @{
            @"type": @"capubbs_collection",
            @"data": collections,
            @"sig": [ActionPerformer getSigForData:collections]
        }
    ];
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:wrappedData
                                                       options:NSJSONWritingPrettyPrinted|NSJSONWritingSortedKeys
                                                         error:&error];
    if (error) {
        NSLog(@"JSON serialization error: %@", error);
        return nil;
    }
    
    NSURL *fileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"CAPUBBS收藏夹.json"]];
    if (![jsonData writeToURL:fileURL options:NSDataWritingAtomic error:&error]) {
        NSLog(@"File write error: %@", error);
        return nil;
    }
    return fileURL;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.searchController.searchBar.text.length > 0) {
        return 1;
    }
    if (sortType == SORT_BY_COLLECTION_DATE || sortType == SORT_BY_POST_DATE) {
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
    if (sortType == SORT_BY_COLLECTION_DATE || sortType == SORT_BY_POST_DATE) {
        return data.count;
    }
    if (sortType == SORT_BY_BOARD_INDEX || sortType == SORT_BY_AUTHOR) {
        return [sortData[section] count];
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (self.searchController.searchBar.text.length > 0) {
        if (searchData.count == 0) {
            return @"没有搜索结果";
        } else {
            return [NSString stringWithFormat:@"搜索到%d个结果", (int)searchData.count];
        }
    }
    if (data.count == 0) {
        return @"您还没有收藏";
    }
    if (sortType == SORT_BY_COLLECTION_DATE || sortType == SORT_BY_POST_DATE) {
        return [NSString stringWithFormat:@"您一共有%d个收藏", (int)data.count];
    }
    if (sortType == SORT_BY_BOARD_INDEX) {
        return [ActionPerformer getBoardTitle:sortData[section][0][@"bid"]];
    }
    if (sortType == SORT_BY_AUTHOR) {
        return sortData[section][0][@"author"] ?: @"未知";
    }
    return nil;
}

- (NSDictionary *)getCollectionDataForIndexPath:(NSIndexPath *)indexPath {
    if (self.searchController.searchBar.text.length > 0) {
        return searchData[indexPath.row];
    } else if (sortType == SORT_BY_COLLECTION_DATE || sortType == SORT_BY_POST_DATE) {
        return data[indexPath.row];
    } else if (sortType == SORT_BY_BOARD_INDEX || sortType == SORT_BY_AUTHOR) {
        return sortData[indexPath.section][indexPath.row];
    }
    NSLog(@"Could not get collection data for row:%ld in section: %ld. This should not happen!", indexPath.row, indexPath.section);
    return nil;
}

- (NSDictionary *)getCollectionDataForCell:(UITableViewCell *)cell {
    return [self getCollectionDataForIndexPath:[self.tableView indexPathForCell:cell]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CollectionViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"collection" forIndexPath:indexPath];
    // Configure the cell...
    NSDictionary *dict = [self getCollectionDataForIndexPath:indexPath];
    if (!dict) {
        return nil;
    }
    
    cell.labelTitle.text = dict[@"title"];
    
    NSString *postTime = dict[@"time"];
    if (sortType == SORT_BY_AUTHOR) {
        NSString *boardTitle = [ActionPerformer getBoardTitle:dict[@"bid"]];
        if (postTime.length > 0) {
            cell.labelSubtitle.text = [NSString stringWithFormat:@"%@  %@", boardTitle, postTime];
        } else {
            cell.labelSubtitle.text = boardTitle;
        }
    } else {
        NSString *author = dict[@"author"];
        if (author.length == 0) {
            author = @"未知";
        }
        if (sortType == SORT_BY_COLLECTION_DATE) {
            NSDate *collectionDate = [NSDate dateWithTimeIntervalSince1970:[dict[@"collectionTime"] intValue]];
            NSString *dateStr = [formatter stringFromDate:collectionDate];
            cell.labelSubtitle.text = [NSString stringWithFormat:@"%@  收藏日期：%@", author, dateStr];
        } else {
            if (postTime.length > 0) {
                cell.labelSubtitle.text = [NSString stringWithFormat:@"%@  %@", author, postTime];
            } else {
                cell.labelSubtitle.text = author;
            }
        }
    }
    
    if ([dict[@"text"] length] == 0) {
        cell.labelInfo.text = @"查看楼主楼层后可获取信息";
    } else {
        cell.labelInfo.text = dict[@"text"];
    }
    
    NSString *icon = dict[@"icon"];
    if (icon.length > 0) {
        [cell.icon setUrl:icon];
    } else {
        [cell.icon setImage:PLACEHOLDER];
    }
    
    return cell;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        NSDictionary *dict = [self getCollectionDataForIndexPath:indexPath];
        NSUInteger sectionCount = sortData.count;
        [data removeObject:dict];
        [searchData removeObject:dict];
        [self sortData];
        
        if (!self.searchController.isActive && sectionCount != sortData.count) {
            [tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
        } else {
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
        [DEFAULTS setObject:data forKey:@"collection"];
        [self performSelector:@selector(commitChange) withObject:nil afterDelay:0.5];
    }
}

- (void)commitChange {
    [NOTIFICATION postNotificationName:@"collectionChanged" object:nil];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.tableView.isEditing) {
        [self updateActionAvailability];
    } else {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.tableView.isEditing) {
        [self updateActionAvailability];
    }
}

- (void)updateActionAvailability {
    dispatch_main_sync_safe(^{
        NSArray *selectedRows = [self.tableView indexPathsForSelectedRows];
        NSUInteger selectedCount = selectedRows.count;
        NSUInteger totalRowCount = 0;
        NSInteger numberOfSections = [self.tableView numberOfSections];
        for (NSInteger section = 0; section < numberOfSections; section++) {
            totalRowCount += [self.tableView numberOfRowsInSection:section];
        }
        self.buttonSelectAll.enabled = selectedCount < totalRowCount;
        self.buttonShare.enabled = selectedCount > 0;
        self.buttonTrash.enabled = selectedCount > 0;
    });
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
            BOOL isMatch = YES;
            NSString *title = dict[@"title"] ?: @"";
            NSString *author = dict[@"author"] ?: @"";
            NSString *text = dict[@"text"] ?: @"";
            for (NSString *keyword in keywords) {
                if (keyword.length == 0) {
                    continue;
                }
                if ([title rangeOfString:keyword options:NSCaseInsensitiveSearch].location == NSNotFound && [author rangeOfString:keyword options:NSCaseInsensitiveSearch].location == NSNotFound && [text rangeOfString:keyword options:NSCaseInsensitiveSearch].location == NSNotFound) {
                    isMatch = NO;
                    break;
                }
            }
            if (isMatch) {
                [searchData addObject:dict];
            }
        }
    }
    dispatch_main_async_safe(^{
        [self.tableView reloadData];
        [self updateActionAvailability];
    });
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    searchBar.placeholder = @"关键词以空格隔开";
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    searchBar.placeholder = @"搜索";
}

- (void)willPresentSearchController:(UISearchController *)searchController {
    [self updateActionAvailability];
}

- (void)didDismissSearchController:(UISearchController *)searchController {
    lastSearch = nil;
    wasFirstResponder = NO;
    [self updateActionAvailability];
}

#pragma mark - Navigation

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if ([identifier isEqualToString:@"post"]) {
        if (self.tableView.isEditing) {
            return NO;
        }
        return [self getCollectionDataForCell:sender];;
    }
    return YES;
}

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"post"]) {
        ContentViewController *dest = [segue destinationViewController];
        NSDictionary *dict = [self getCollectionDataForCell:sender];
        dest.tid = dict[@"tid"];
        dest.bid = dict[@"bid"];
        dest.title = dict[@"title"];
        dest.isCollection = YES;
    }
}

@end
