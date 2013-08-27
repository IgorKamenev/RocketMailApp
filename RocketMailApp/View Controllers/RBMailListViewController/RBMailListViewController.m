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

@interface RBMailListViewController ()

@property (nonatomic, strong) IKImageSegmentedControl* segmentedControl;
@property (nonatomic, strong) DataProvider* dataProvider;
@property (nonatomic, strong) NSArray* emails;

@property (nonatomic) int currentPage;

@end

@implementation RBMailListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupAppearance];
    [self setupSegmentedControl];
    [self setupRefreshButton];
    
    self.currentPage = 0;
    self.dataProvider = [DataProvider sharedInstance];

    [self loadEmails];
    
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

- (void) didRefreshButtonPressed
{
    DLog(@"");
}

- (void) loadEmails
{
    
    [self.dataProvider mailByPage:0 withType:RMMailTypeActual successBlock:^(NSArray *emails) {

        self.emails = emails;
        [self.tableView reloadData];
    }];
}


#pragma mark UITableViewDataSource

//-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    
//    CGFloat cellHeight = 44;
//    return cellHeight;
//}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.emails.count;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    RMMail* mail = self.emails[indexPath.row];
    RMMailCell* cell = [tableView dequeueReusableCellWithIdentifier:@"RMMailCell"];

    cell.fromLabel.text = mail.from;
    cell.subjectLabel.text = mail.subject;
    cell.bodyLabel.text = mail.body;
    cell.dateLabel.text = [mail.receivedAt description];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


@end
