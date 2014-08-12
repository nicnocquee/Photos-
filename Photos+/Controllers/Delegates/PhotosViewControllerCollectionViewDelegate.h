//
//  PhotosViewControllerCollectionViewDelegate.h
//  Photos+
//
//  Created by  on 8/12/14.
//  Copyright (c) 2014 Delightful. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PhotosViewControllerCollectionViewDelegate : NSObject <UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic, assign) int numberOfColumns;

@property (nonatomic, assign) CGFloat cellSpacing;

- (id)initWithCollectionView:(UICollectionView *)collectionView;

@end
