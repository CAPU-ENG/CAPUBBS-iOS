//
//  CollectionViewController.h
//  CAPUBBS
//
//  Created by 范志康 on 15/11/10.
//  Copyright © 2015年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CollectionViewController : CustomTableViewController<UISearchControllerDelegate, UISearchResultsUpdating, UIAlertViewDelegate, UISearchBarDelegate> {
    NSMutableArray *data;
    NSMutableArray *searchData;
    NSMutableArray *sortData;
    NSString *lastSearch;
    BOOL wasFirstResponder;
    int sortType;
}

@property (strong, nonatomic) UISearchController *searchController;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *buttonOrganize;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *buttonDeleteAll;

@end
