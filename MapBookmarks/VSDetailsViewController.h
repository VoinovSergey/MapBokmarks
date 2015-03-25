//
//  VSDetailsViewController.h
//  MapBookmarks
//
//  Created by Sergey Voinov on 3/24/15.
//  Copyright (c) 2015 Sergey Voinov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VSBookmark.h"
#import "SAMHUDView.h"

@interface VSDetailsViewController : UITableViewController<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, retain) NSArray * placeArray;
@property (nonatomic, retain) VSBookmark * bookmark;

@property (retain, nonatomic) SAMHUDView* progressIndicator;

- (IBAction)tapOnTrashButton:(id)sender;

@end
