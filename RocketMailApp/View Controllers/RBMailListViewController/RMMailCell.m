//
//  RMMailCell.m
//  RocketMailApp
//
//  Created by Igor Kamenev on 8/27/13.
//  Copyright (c) 2013 Igor Kamenev. All rights reserved.
//

#import "RMMailCell.h"

@interface RMMailCell ()

@end

@implementation RMMailCell

-(void)awakeFromNib
{
    
    UIImage* delimiterImage = [UIImage imageNamed:@"RMMailCellDelimiter.png"];
    UIImageView* delimiterImageView = [[UIImageView alloc] initWithFrame:CGRectMake(-320, self.frame.size.height-1, 320*3, 1)];
    
    delimiterImageView.image = delimiterImage;
    delimiterImageView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    
    [self addSubview:delimiterImageView];
    
    CGRect rect = self.doneView.frame;
    rect.origin.x = -self.frame.size.width;
    rect.size.width = self.frame.size.width;
    self.doneView.frame = rect;
    
    rect = self.deleteView.frame;
    rect.origin.x = self.frame.size.width;
    rect.size.width = self.frame.size.width;
    self.deleteView.frame = rect;
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)layoutSubviews
{
}

-(void)prepareForReuse
{
    CGRect rect = self.contentView.frame;
    rect.origin.x = 0;
    self.contentView.frame = rect;
}

@end
