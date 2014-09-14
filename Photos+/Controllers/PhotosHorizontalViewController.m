//
//  PhotosHorizontalViewController.m
//  Photos+
//
//  Created by  on 9/13/14.
//  Copyright (c) 2014 Delightful. All rights reserved.
//

#import "PhotosHorizontalViewController.h"

#import "PhotoZoomableCell.h"

#define CELL_SPACING 20

@interface PhotosHorizontalViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) NSValue *itemSize;

@end

@implementation PhotosHorizontalViewController

- (id)initWithPhotos:(NSArray *)photos {
    self = [super init];
    if (self) {
        self.photos = photos;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.collectionView registerClass:[PhotoZoomableCell class] forCellWithReuseIdentifier:NSStringFromClass([PhotoZoomableCell class])];
    
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.indexOfPhotoToShowOnLoad inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame) + CELL_SPACING, CGRectGetHeight(self.view.frame)) collectionViewLayout:flowLayout];
        [_collectionView setDelegate:self];
        [_collectionView setDataSource:self];
        [_collectionView setPagingEnabled:YES];
        [_collectionView setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
        [self.view addSubview:_collectionView];
    }
    return _collectionView;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.photos.count;
}

#pragma mark - UICollectionViewDelegate

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PhotoZoomableCell *cell = (PhotoZoomableCell *)[self.collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([PhotoZoomableCell class]) forIndexPath:indexPath];
    [cell setItem:self.photos[indexPath.item]];
    return cell;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.itemSize) {
        return [self.itemSize CGSizeValue];
    }
    
    CGSize size = self.view.frame.size;
    self.itemSize = [NSValue valueWithCGSize:size];
    return size;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return CELL_SPACING;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return CELL_SPACING;
}

#pragma mark - CustomAnimationTransitionFromViewControllerDelegate

@end
