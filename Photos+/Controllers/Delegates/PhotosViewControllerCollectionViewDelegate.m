//
//  PhotosViewControllerCollectionViewDelegate.m
//  Photos+
//
//  Created by  on 8/12/14.
//  Copyright (c) 2014 Delightful. All rights reserved.
//

#import "PhotosViewControllerCollectionViewDelegate.h"

@interface PhotosViewControllerCollectionViewDelegate ()

@property (nonatomic, strong) NSValue *cellSize;

@property (nonatomic, strong) UICollectionView *collectionView;

@end

@implementation PhotosViewControllerCollectionViewDelegate

- (id)initWithCollectionView:(UICollectionView *)collectionView {
    self = [super init];
    if (self) {
        _numberOfColumns = 3;
        _cellSpacing = 1;
        _collectionView = collectionView;
        _collectionView.delegate = self;
    }
    return self;
}

- (void)setNumberOfColumns:(int)numberOfColumns {
    if (_numberOfColumns != numberOfColumns) {
        _numberOfColumns = MIN(1, numberOfColumns);
    }
    
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.cellSize) {
        return [self.cellSize CGSizeValue];
    }
    
    CGFloat width = floorf((CGRectGetWidth(self.collectionView.frame) - ((self.numberOfColumns+1)*self.cellSpacing))/self.numberOfColumns);
    CGSize size = CGSizeMake(width, width);
    self.cellSize = [NSValue valueWithCGSize:size];
    return size;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(self.cellSpacing, self.cellSpacing, self.cellSpacing, self.cellSpacing);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return self.cellSpacing;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return self.cellSpacing;
}

@end
