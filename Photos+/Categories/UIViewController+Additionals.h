//
//  UIViewController+Additionals.h
//  PhotoBox
//
//  Created by Nico Prananta on 8/31/13.
//  Copyright (c) 2013 Touches. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (Additionals)

- (void)showLoadingView:(BOOL)show atBottomOfScrollView:(BOOL)bottom;

- (void)showLoadingView:(BOOL)show atCenterY:(CGFloat)centerY;

- (void)openActivityPickerForImage:(UIImage *)image;

- (void)openActivityPickerForURL:(NSURL *)URL completion:(void(^)())completion;

- (void)toggleNavigationBarHidden;

- (void)hideNavigationBar;

- (void)setNavigationBarHidden:(BOOL)hidden animated:(BOOL)animated;

@end
