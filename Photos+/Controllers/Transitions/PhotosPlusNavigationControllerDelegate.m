//
//  PhotoBoxNavigationControllerDelegate.m
//  PhotoBox
//
//  Created by Nico Prananta on 9/1/13.
//  Copyright (c) 2013 Touches. All rights reserved.
//

#import "PhotosPlusNavigationControllerDelegate.h"

#import "PhotosHorizontalViewController.h"
#import "PhotosViewController.h"

#import "ShowFullScreenPhotosAnimatedTransitioning.h"

@implementation PhotosPlusNavigationControllerDelegate

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                  animationControllerForOperation:(UINavigationControllerOperation)operation
                                               fromViewController:(UIViewController *)fromVC
                                                 toViewController:(UIViewController *)toVC {
    if (operation == UINavigationControllerOperationPop) {
        return nil;
    }
    ShowFullScreenPhotosAnimatedTransitioning *transitioning = [[ShowFullScreenPhotosAnimatedTransitioning alloc] init];
    transitioning.operation = operation;
    if (([fromVC isKindOfClass:[PhotosViewController class]] &&
         [toVC isKindOfClass:[PhotosHorizontalViewController class]] &&
         operation==UINavigationControllerOperationPush) ||
        ([fromVC isKindOfClass:[PhotosHorizontalViewController class]] &&
         [toVC isKindOfClass:[PhotosViewController class]] && operation==UINavigationControllerOperationPop)) {
        return transitioning;
    }
    return nil;
}

@end
