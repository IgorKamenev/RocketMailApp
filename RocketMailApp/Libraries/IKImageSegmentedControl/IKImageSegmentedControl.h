//
//  IKImageSegmentedControl.h
//  RocketMailApp
//
//  Created by Igor Kamenev on 8/27/13.
//  Copyright (c) 2013 Igor Kamenev. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol IKImageSegmentedControlDelegate;

@interface IKImageSegmentedControl : UIView

@property (nonatomic, strong) id<IKImageSegmentedControlDelegate> delegate;
@property (nonatomic) int selectedIndex;

- (void) addSegmentWithNormalImage: (UIImage*) normalImage selectedImage: (UIImage*) selectedImage;

@end


@protocol IKImageSegmentedControlDelegate <NSObject>

@optional

- (void) didSelectSegmentWithIndex: (int) segmentIndex;

@end