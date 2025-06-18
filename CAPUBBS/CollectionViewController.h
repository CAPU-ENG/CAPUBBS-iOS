//
//  CollectionViewController.h
//  CAPUBBS
//
//  Created by 范志康 on 15/11/10.
//  Copyright © 2015年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CollectionViewController : CustomTableViewController<UISearchControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate> {
    MBProgressHUD *hud;
    NSMutableArray *data;
    NSMutableArray *searchData;
    NSMutableArray *sortData;
    NSDateFormatter *formatter;
    NSString *lastSearch;
    BOOL wasFirstResponder;
    int sortType;
}

@property (strong, nonatomic) CustomSearchController *searchController;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *buttonSelectAll;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *buttonSelectReverse;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *buttonShare;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *buttonTrash;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *buttonOrganize;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *buttonCancelOrganize;

@end
