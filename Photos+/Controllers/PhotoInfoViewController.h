//
//  PhotoInfoViewController.h
//  PhotoBox
//
//  Created by Nico Prananta on 10/29/13.
//  Copyright (c) 2013 Touches. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PhotoInfoViewController;
@class PhotoAsset;

@protocol PhotoInfoViewControllerDelegate <NSObject>

@optional
- (void)photoInfoViewController:(PhotoInfoViewController *)photoInfo didDragToClose:(CGFloat)progress;
- (void)photoInfoViewControllerDidClose:(PhotoInfoViewController *)photoInfo;

@end

@interface PhotoInfoViewController : UITableViewController

@property (nonatomic, strong) PhotoAsset *photo;
@property (nonatomic, weak) id<PhotoInfoViewControllerDelegate>delegate;

@end
