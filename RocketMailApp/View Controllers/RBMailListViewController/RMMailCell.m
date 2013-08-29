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
    
    self.fromLabel.font = [UIFont fontWithName:@"ChevinPro-Medium" size:15.0];
    self.subjectLabel.font = [UIFont fontWithName:@"ChevinCyrillic-Bold" size:15.0];
    self.bodyLabel.font = [UIFont fontWithName:@"ChevinPro-Medium" size:15.0];
    self.dateLabel.font = [UIFont fontWithName:@"ChevinPro-Medium" size:15.0];
    self.messageCountLabel.font = [UIFont fontWithName:@"ChevinCyrillic-Bold" size:10.0];

    UIImage* messageCountBadge = [[UIImage imageNamed:@"messageCountBadge.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(3, 3, 3, 3) resizingMode:UIImageResizingModeStretch];

    self.messageCountImageView.image = messageCountBadge;
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)layoutSubviews
{
    //[super layoutSubviews];

}

-(void)prepareForReuse
{
    CGRect rect = self.contentView.frame;
    rect.origin.x = 0;
    self.contentView.frame = rect;
}

-(void)setMessageCount:(int)messageCount
{
    _messageCount = messageCount;
    
    if (messageCount > 1) {
        self.messageCountLabel.hidden = NO;
        self.messageCountImageView.hidden = NO;
        self.messageCountLabel.text = [NSString stringWithFormat:@"%d", messageCount];

        CGSize size = [self.messageCountLabel.text sizeWithFont:self.messageCountLabel.font constrainedToSize:CGSizeMake(255, 255)];
        
        CGRect rect = self.messageCountLabel.frame;
        rect.size.width = size.width + 8;
        self.messageCountLabel.frame = rect;
        self.messageCountImageView.frame = rect;
        
    } else {
        self.messageCountLabel.hidden = YES;
        self.messageCountImageView.hidden = YES;
    }
}

@end
