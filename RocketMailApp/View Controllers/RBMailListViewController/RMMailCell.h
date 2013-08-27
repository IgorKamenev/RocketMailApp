//
//  RMMailCell.h
//  RocketMailApp
//
//  Created by Igor Kamenev on 8/27/13.
//  Copyright (c) 2013 Igor Kamenev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RMMailCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *starImageView;
@property (weak, nonatomic) IBOutlet UILabel *fromLabel;
@property (weak, nonatomic) IBOutlet UILabel *subjectLabel;
@property (weak, nonatomic) IBOutlet UILabel *bodyLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;

@end
