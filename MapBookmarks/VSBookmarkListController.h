//
//  VSBookmarkListController.h
//  MapBookmarks
//
//  Created by Sergey Voinov on 3/24/15.
//  Copyright (c) 2015 Sergey Voinov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "VSBookmark.h"

@interface VSBookmarkListController : UITableViewController<NSFetchedResultsControllerDelegate>

@property (nonatomic,strong) NSManagedObjectContext* managedObjectContext;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@property (nonatomic, strong) IBOutlet UIBarButtonItem * editButton;

- (IBAction)toogleEditMode:(id)sender;

@property (copy)void (^selectionCellBlock)(VSBookmark *);

@end
