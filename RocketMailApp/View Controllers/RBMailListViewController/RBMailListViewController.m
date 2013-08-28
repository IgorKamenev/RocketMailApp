//
//  RBMailListViewController.m
//  RocketMailApp
//
//  Created by Igor Kamenev on 8/27/13.
//  Copyright (c) 2013 Igor Kamenev. All rights reserved.
//

#import "RBMailListViewController.h"
#import "DataProvider.h"

#import "RMMailCell.h"
#import "RMMailLoadingCell.h"

#import <QuartzCore/QuartzCore.h>

@interface RBMailListViewController ()

@property (nonatomic, strong) IKImageSegmentedControl* segmentedControl;
@property (nonatomic, strong) DataProvider* dataProvider;
@property (nonatomic, strong) NSMutableArray* items;

@property (nonatomic) int currentPage;

@property (nonatomic, strong) UIPanGestureRecognizer* panRecognizer;

@property (nonatomic, strong) NSIndexPath* currentSwipingCellIndexPath;

@property (nonatomic, strong) NSCache* cellCache;

@property (nonatomic, strong) RMMailLoadingCell* loadingCell;
@property (nonatomic, strong) NSIndexPath* loadingCellIndexPath;
@property (nonatomic) BOOL isEmailLoading;
@property (nonatomic) BOOL isDragging;

@property (nonatomic, strong) UIView* emptyFolderView;

@end

static int kEmailsPerPage = 20;

@implementation RBMailListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupAppearance];
    [self setupSegmentedControl];
    [self setupRefreshButton];
    
    self.currentPage = 0;
    self.dataProvider = [DataProvider sharedInstance];


    self.panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognizer:)];
    self.panRecognizer.maximumNumberOfTouches = 1;
    self.panRecognizer.minimumNumberOfTouches = 1;
    self.panRecognizer.delegate = self;
    [self.tableView addGestureRecognizer:self.panRecognizer];

    self.cellCache = [NSCache new];
    
    [self loadEmailsFromDB];
    
}

- (void) loadEmailsFromDB
{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{

        RMMailType type;

        switch (self.segmentedControl.selectedIndex) {
            case 0: type = RMMailTypeDeleted; break;
            case 1: type = RMMailTypeActual; break;
            default: type = RMMailTypeDone; break;
        }
        
        NSMutableArray* emails = [self.dataProvider emailsFromDBWithType:type];

        dispatch_async(dispatch_get_main_queue(), ^{
            self.items = emails;
            [self.tableView reloadData];

            if (self.items.count == 0) {

                [self showEmptyFolder];
            } else {
                [self hideEmptyFolder];
            }
        });
        
    });
}

- (void) setupAppearance
{
   
    UIImage* navBg = [UIImage imageNamed:@"navigationBarBg.png"];
    [self.navigationController.navigationBar setBackgroundImage:navBg forBarMetrics:UIBarMetricsDefault];
}

- (void) setupSegmentedControl
{
    
    self.segmentedControl = [[IKImageSegmentedControl alloc] initWithFrame:CGRectMake(0, 0, 165, 31)];
    
    // Button 1
    UIImage *btnDeletedMailNormal = [UIImage imageNamed:@"segmentDeletedMail.png"];
    UIImage *btnDeletedMailSelected = [UIImage imageNamed:@"segmentDeletedMailOn.png"];

    // Button 2
    UIImage *btnActualMailNormal = [UIImage imageNamed:@"segmentActualMail.png"];
    UIImage *btnActualMailSelected = [UIImage imageNamed:@"segmentActualMailOn.png"];

    // Button 3
    UIImage *btnDoneMailNormal = [UIImage imageNamed:@"segmentDoneMail.png"];
    UIImage *btnDoneMailSelected = [UIImage imageNamed:@"segmentDoneMailOn.png"];

    [self.segmentedControl addSegmentWithNormalImage:btnDeletedMailNormal selectedImage:btnDeletedMailSelected];
    [self.segmentedControl addSegmentWithNormalImage:btnActualMailNormal selectedImage:btnActualMailSelected];
    [self.segmentedControl addSegmentWithNormalImage:btnDoneMailNormal selectedImage:btnDoneMailSelected];
    self.segmentedControl.delegate = self;
    [self.segmentedControl setSelectedIndex:1];
    self.navigationItem.titleView = self.segmentedControl;
}

- (void) setupRefreshButton
{
    UIButton* refreshButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 29, 29)];
    [refreshButton setImage:[UIImage imageNamed:@"refreshButton.png"] forState:UIControlStateNormal];
    [refreshButton addTarget:self action:@selector(didRefreshButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem* item = [[UIBarButtonItem alloc] initWithCustomView:refreshButton];
    [self.navigationItem setRightBarButtonItem:item];
}


- (void) makeNextEmailsRequest
{

    if (self.isEmailLoading) return;
    self.isEmailLoading = YES;

    [self.dataProvider mailByPage:self.currentPage withType:RMMailTypeActual successBlock:^(NSMutableArray *emails) {

        if (emails.count == kEmailsPerPage) {
            self.currentPage++;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{

            [self needsHideLoadingCell];
            [self loadEmailsFromDB];
            self.isEmailLoading = NO;
        });
        
    }];
}

- (void) needsShowLoadingCell
{
    
    DLog();
    self.loadingCellIndexPath = [NSIndexPath indexPathForRow:self.items.count inSection:0];
    self.loadingCell = [self.tableView dequeueReusableCellWithIdentifier:@"RMMailLoadingCell" ];
    
    [self.tableView beginUpdates];
    [self.items addObject:self.loadingCell];
    [self.tableView insertRowsAtIndexPaths:@[self.loadingCellIndexPath] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
    
}

- (void) needsHideLoadingCell
{

    if (self.loadingCellIndexPath && self.loadingCell) {

        [CATransaction begin];
        
        [CATransaction setCompletionBlock:^{
            self.loadingCellIndexPath = nil;
            self.loadingCell = nil;
        }];
        
        [self.tableView beginUpdates];
        [self.items removeObjectAtIndex: self.loadingCellIndexPath.row];
        [self.tableView deleteRowsAtIndexPaths:@[self.loadingCellIndexPath] withRowAnimation:UITableViewRowAnimationMiddle];
        [self.tableView endUpdates];
        
        [CATransaction commit];
    }
    
}

- (void) needsDeleteMailAtIndexPath: (NSIndexPath*) indexPath
{
    
    RMMail* mail = self.items[indexPath.row];
    mail.type = RMMailTypeDeleted;
    [mail save];

    [self removeRowAtIndexPath:indexPath];
}

- (void) needsCompleteMailAtIndexPath: (NSIndexPath*) indexPath
{

    RMMail* mail = self.items[indexPath.row];
    mail.type = RMMailTypeDone;
    [mail save];

    [self removeRowAtIndexPath:indexPath];
}

- (void) removeRowAtIndexPath: (NSIndexPath*) indexPath
{

    [CATransaction begin];
    
    [CATransaction setCompletionBlock:^{
        [self.cellCache removeAllObjects];
        [self.tableView reloadData];
    }];

    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationMiddle];
    [self.items removeObjectAtIndex: indexPath.row];
    [self.tableView endUpdates];

    [CATransaction commit];
}

- (BOOL) shouldMoveCellAtIndexPath: (NSIndexPath*) indexPath
{
    if (self.segmentedControl.selectedIndex == 1)
        return YES;
    
    return NO;
}

- (void) showEmptyFolder
{
    if (!self.emptyFolderView) {
        UILabel* label = [[UILabel alloc] initWithFrame:self.view.bounds];
        label.text = @"This folder is empty";
        label.textColor = [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1.0];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont fontWithName:@"ChevinCyrillic-Bold" size:30.0];
        self.emptyFolderView = label;
        [self.view addSubview:self.emptyFolderView];
    }
}

- (void) hideEmptyFolder
{
    if (self.emptyFolderView) {
        [self.emptyFolderView removeFromSuperview];
        self.emptyFolderView = nil;
    }
}

- (void) didRefreshButtonPressed
{
    
    self.items = nil;
    [self.tableView reloadData];
    [self.dataProvider removeAllEmails];
    
    self.currentPage = 0;
    [self makeNextEmailsRequest];
    
}

#pragma mark UITableViewDataSource

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    CGFloat cellHeight = 44;
    
    id object = self.items[indexPath.row];
    
    if ([object isKindOfClass:[RMMail class]]) {
        
        cellHeight = 85.0;

    } else if ([object isKindOfClass:[RMMailLoadingCell class]]) {
        
        cellHeight = 44.0;
    }
    
    return cellHeight;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.items.count;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    id object = self.items[indexPath.row];
    
    if ([object isKindOfClass:[RMMail class]]) {

        RMMail* mail = self.items[indexPath.row];
        RMMailCell* cell = [tableView dequeueReusableCellWithIdentifier:@"RMMailCell" forIndexPath:indexPath];
        
        cell.fromLabel.text = mail.from;
        cell.subjectLabel.text = mail.subject;
        cell.bodyLabel.text = mail.body;
        cell.dateLabel.text = [mail.receivedAt relativeDate];
        
        [self.cellCache setObject:cell forKey:indexPath];
        
        return cell;
        
    } else if ([object isKindOfClass:[RMMailLoadingCell class]]) {
        
        return object;
    }

    return nil;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark UIPanGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    
    if (gestureRecognizer == self.panRecognizer) {
        
        UIPanGestureRecognizer *pan = (UIPanGestureRecognizer *)gestureRecognizer;
        
        CGPoint point = [pan translationInView:self.tableView];
        CGPoint location = [pan locationInView:self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
        
        if (fabsf(point.y) > fabsf(point.x)) {
            return NO;
        } else if (indexPath == nil) {
            return NO;
        } else if (indexPath) {
            return YES;
        }
    }
    
    return YES;
}

- (void)panGestureRecognizer:(UIPanGestureRecognizer *)recognizer {
    
    if (recognizer.state == UIGestureRecognizerStateBegan && [recognizer numberOfTouches] > 0) {
        
        CGPoint location1 = [recognizer locationOfTouch:0 inView:self.tableView];
        
        NSIndexPath* indexPath = [self.tableView indexPathForRowAtPoint:location1];

        if ([self shouldMoveCellAtIndexPath:indexPath])
            self.currentSwipingCellIndexPath = indexPath;
    }
    
    else if (recognizer.state == UIGestureRecognizerStateChanged && [recognizer numberOfTouches] > 0 && self.currentSwipingCellIndexPath) {
        
        CGPoint translation = [recognizer translationInView:self.tableView];
        
        UITableViewCell* cell =  [self.cellCache objectForKey:self.currentSwipingCellIndexPath];
        CGRect rect = cell.contentView.frame;
        rect.origin.x = translation.x;
        cell.contentView.frame = rect;
        
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        
        UITableViewCell* cell =  [self.cellCache objectForKey:self.currentSwipingCellIndexPath];
        
        if (cell.contentView.frame.origin.x > cell.contentView.frame.size.width / 2.0) {
            
            // done
            
            [UIView animateWithDuration:0.2 animations:^{

                CGRect rect = cell.contentView.frame;
                rect.origin.x = cell.frame.size.width;
                cell.contentView.frame = rect;
                
            } completion:^(BOOL finished) {
                
                [self needsCompleteMailAtIndexPath:self.currentSwipingCellIndexPath];
                self.currentSwipingCellIndexPath = nil;
                
            }];
            
        } else if (abs(cell.contentView.frame.origin.x) > cell.contentView.frame.size.width / 2.0) {
        
            // delete

            [UIView animateWithDuration:0.2 animations:^{
                
                CGRect rect = cell.contentView.frame;
                rect.origin.x = -cell.frame.size.width;
                cell.contentView.frame = rect;
                
            } completion:^(BOOL finished) {

                [self needsDeleteMailAtIndexPath:self.currentSwipingCellIndexPath];
                self.currentSwipingCellIndexPath = nil;
            }];
            
        } else {
            
            [UIView animateWithDuration:0.2 animations:^{
                
                CGRect rect = cell.contentView.frame;
                rect.origin.x = 0;
                cell.contentView.frame = rect;
            } completion:^(BOOL finished) {
                self.currentSwipingCellIndexPath = nil;
            }];
        }
    }
}

#pragma mark IKImageSegmentedControlDelegate
-(void)didSelectSegmentWithIndex:(int)segmentIndex
{
    [self loadEmailsFromDB];
}

#pragma mark UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    
    if (self.segmentedControl.selectedIndex != 1) return;
    if (scrollView.contentOffset.y <= 0) return;
    
    if (scrollView.contentOffset.y > scrollView.contentSize.height - scrollView.frame.size.height) {
        
        if (self.loadingCellIndexPath) {
         
            return;
        }
        
        if (scrollView.frame.size.height < scrollView.contentSize.height) {
            [self needsShowLoadingCell];
            [self.loadingCell.activityIndicator startAnimating];
        }
        
        [self makeNextEmailsRequest];
        
    }
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    self.isDragging = YES;
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    self.isDragging = NO;

    if (self.loadingCell && !self.isEmailLoading) {
        self.isEmailLoading = YES;
    }
}

@end
