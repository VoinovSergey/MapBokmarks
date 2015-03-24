//
//  VSDetailsViewController.m
//  MapBookmarks
//
//  Created by Sergey Voinov on 3/24/15.
//  Copyright (c) 2015 Sergey Voinov. All rights reserved.
//

#import "VSDetailsViewController.h"
#import "ViewController.h"
#import "AFNetworking.h"
#import "AFHTTPRequestOperationManager.h"
#import <MapKit/MapKit.h>

@implementation VSDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self retriveLocationDescriptionForCoordinate:((CLLocation *)self.bookmark.coordinates).coordinate]; //self.bookmark.coordinates
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.bookmark.named = YES;
    self.bookmark.title = self.placeArray[indexPath.row];
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.bookmark.named) {
        return 0;
    }
    if ([self.placeArray count] == 0) {
        return 1;
    }
    return [self.placeArray count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (self.bookmark.named) {
        return 60;
    }
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView * headerView = nil;
    if (self.bookmark.named) {
        headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 768, 60)];
        headerView.backgroundColor = [UIColor lightGrayColor];
        UIButton * showPlacesButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [showPlacesButton addTarget:self action:@selector(makeUnnamedAndShowPlaces) forControlEvents:UIControlEventTouchUpInside];
        [showPlacesButton setTitle:@"Load nearby places" forState:UIControlStateNormal];
        [headerView addSubview:showPlacesButton];
        showPlacesButton.frame = CGRectMake(300, 20, 200, 40);
    }
    return headerView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"DetailsCellIdentifier"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DetailsCellIdentifier"];
    }
    if (self.bookmark.named) {
        cell.textLabel.text = @"Make unnamed";
    } else {
        if ([self.placeArray count] == 0) {
            cell.textLabel.text = @"No found any places";
        } else {
            cell.textLabel.text = self.placeArray[indexPath.row];
            NSLog(@"Cell %@", self.placeArray[indexPath.row]);
        }
    }
    return cell;
}

- (void)makeUnnamedAndShowPlaces {
    self.bookmark.named = NO;
    [self retriveLocationDescriptionForCoordinate:((CLLocation *)self.bookmark.coordinates).coordinate];
}

- (void)retriveLocationDescriptionForCoordinate:(CLLocationCoordinate2D)coordinate
{
    if (self.progressIndicator == nil)
    {
        self.progressIndicator = [[SAMHUDView alloc] initWithTitle:@"Loading" loading:YES];
    }
    
    [self.view addSubview:self.progressIndicator];
    NSLog(@"%f , %f\n", coordinate.latitude, coordinate.longitude);
    NSString *urlString = [NSString stringWithFormat:@"http://maps.googleapis.com/maps/api/geocode/json?latlng=%f,%f&sensor=true", coordinate.latitude, coordinate.longitude];
    //NSString *urlString = [NSString stringWithFormat:@"https://graph.facebook.com/search?type=place&center=%f,%f&distance=1000", coordinate.latitude, coordinate.longitude];
    //APICall *call = [APICall callWithURLString:urlString delegate:self];
    //[call start];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET:urlString parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@, %@", responseObject, [responseObject class]);
        NSMutableArray * placeArray = [[NSMutableArray alloc] initWithCapacity:5];
        NSArray * results = [responseObject objectForKey:@"results"];
        if (results != nil) {
            for (NSDictionary * place in results) {
                NSString * formattedAddress = [place objectForKey:@"formatted_address"];
                NSLog(@"%@ ", formattedAddress);
                if (formattedAddress != nil) {
                    [placeArray addObject:formattedAddress];
                }
            }
        }
        [self.progressIndicator removeFromSuperview];
        self.placeArray = placeArray;
        [self.tableView reloadData];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

@end
