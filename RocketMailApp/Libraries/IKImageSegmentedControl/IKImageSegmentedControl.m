//
//  IKImageSegmentedControl.m
//  RocketMailApp
//
//  Created by Igor Kamenev on 8/27/13.
//  Copyright (c) 2013 Igor Kamenev. All rights reserved.
//

#import "IKImageSegmentedControl.h"

@interface IKImageSegmentedControl ()

@property (nonatomic) int buttonIdx;
@property (nonatomic) CGFloat nextOriginY;
@property (nonatomic, strong) NSMutableArray* buttons;

@end

@implementation IKImageSegmentedControl

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {

        self.nextOriginY = 0.0;
        self.buttonIdx = 0;
        self.buttons = [NSMutableArray new];
    }
    return self;
}

- (void) addSegmentWithNormalImage: (UIImage*) normalImage selectedImage: (UIImage*) selectedImage
{
 
    UIButton* button = [[UIButton alloc] initWithFrame:CGRectMake(self.nextOriginY, 0, normalImage.size.width, normalImage.size.height)];
    button.tag = self.buttonIdx;
    [button setImage:normalImage forState:UIControlStateNormal];
    
    if (selectedImage) {
        [button setImage:selectedImage forState:UIControlStateHighlighted];
        [button setImage:selectedImage forState:UIControlStateSelected];
        [button setImage:selectedImage forState:(UIControlStateSelected | UIControlStateHighlighted)];
    }
    
    [button addTarget:self action:@selector(didButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    self.buttonIdx++;
    self.nextOriginY += button.frame.size.width;
    
    [self addSubview:button];
    [self.buttons addObject:button];
}

- (void) setSelectedIndex: (int) index
{
    _selectedIndex = index;
    
    for (UIButton* button in self.buttons) {
        
        if (button.tag == index) {
            [button setSelected:YES];
        } else {
            [button setSelected:NO];
        }
    }
}

- (void) didButtonPressed: (UIButton*) button
{
    [self setSelectedIndex:button.tag];
    
    if ([self.delegate respondsToSelector:@selector(didSelectSegmentWithIndex:)]) {
        [self.delegate didSelectSegmentWithIndex:button.tag];
    }
}

@end
