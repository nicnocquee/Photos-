//
//  UIWindow+Additionals.h
//  PhotoBox
//
//  Created by Nico Prananta on 10/17/13.
//  Copyright (c) 2013 Touches. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIWindow (Additionals)

+ (UIViewController *)rootViewController;
+ (UIViewController *)topMostViewController;
+ (UIWindow *)appWindow;

@end
