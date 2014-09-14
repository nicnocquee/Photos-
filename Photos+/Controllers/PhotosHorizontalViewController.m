//
//  PhotosHorizontalViewController.m
//  Photos+
//
//  Created by  on 9/13/14.
//  Copyright (c) 2014 Delightful. All rights reserved.
//

#import "PhotosHorizontalViewController.h"

#import "PhotoZoomableCell.h"

#import "UIViewController+Additionals.h"

#import <objc/runtime.h>

#define CELL_SPACING 20
#define PBX_DID_SHOW_SCROLL_UP_AND_DOWN_TO_CLOSE_FULL_SCREEN_PHOTO @"photobox.PBX_DID_SHOW_SCROLL_UP_AND_DOWN_TO_CLOSE_FULL_SCREEN_PHOTO"


@interface PhotosHorizontalViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate> {
    BOOL shouldHideNavigationBar;
}

@property (nonatomic, strong) NSValue *itemSize;

@property (nonatomic, strong) UIView *darkBackgroundView;

@property (nonatomic, assign) NSInteger previousPage;
@property (nonatomic, assign) BOOL justOpened;
@property (nonatomic, strong) UIView *backgroundViewControllerView;
@property (nonatomic, strong) UIView *photoInfoBackgroundGradientView;

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
    [self setAutomaticallyAdjustsScrollViewInsets:NO];
    [self.collectionView setContentInset:UIEdgeInsetsZero];
    [self.collectionView registerClass:[PhotoZoomableCell class] forCellWithReuseIdentifier:NSStringFromClass([PhotoZoomableCell class])];
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.firstShownPhotoIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionLeft animated:NO];
    
    UITapGestureRecognizer *tapOnce = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnce:)];
    [tapOnce setDelegate:self];
    [tapOnce setNumberOfTapsRequired:1];
    [self.collectionView addGestureRecognizer:tapOnce];
    
    self.darkBackgroundView = [[UIView alloc] initWithFrame:self.view.frame];
    [self.darkBackgroundView setBackgroundColor:[UIColor colorWithWhite:1 alpha:1]];
    [self.collectionView setBackgroundView:self.darkBackgroundView];
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

- (NSInteger)currentCollectionViewPage:(UIScrollView *)scrollView{
    if (self.justOpened) {
        return self.firstShownPhotoIndex;
    }
    CGFloat pageWidth = scrollView.frame.size.width;
    float fractionalPage = scrollView.contentOffset.x / pageWidth;
    NSInteger page = lround(fractionalPage);
    self.firstShownPhotoIndex = page;
    return page;
}

- (void)insertBackgroundSnapshotView {
    if (self.backgroundViewControllerView) {
        [self.backgroundViewControllerView removeFromSuperview];
    }
    UIView *bgView = [self.delegate snapshotView];
    self.backgroundViewControllerView = bgView;
    [self.backgroundViewControllerView setBackgroundColor:[UIColor whiteColor]];
    CGRect frame = ({
        CGRect frame = self.backgroundViewControllerView.frame;
        frame.origin = self.collectionView.frame.origin;
        frame;
    });
    [self.backgroundViewControllerView setFrame:frame];
    UIView *whiteView = [[UIView alloc] initWithFrame:[self.delegate selectedItemRectInSnapshot]];
    [whiteView setBackgroundColor:[UIColor whiteColor]];
    [self.backgroundViewControllerView addSubview:whiteView];
    [self.collectionView.superview insertSubview:self.backgroundViewControllerView belowSubview:self.collectionView];
}

#pragma mark - Tap and Gesture

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
        UITapGestureRecognizer *tap = (UITapGestureRecognizer *)gestureRecognizer;
        if (tap.numberOfTapsRequired == 1) {
            if ([otherGestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
                UITapGestureRecognizer *other = (UITapGestureRecognizer *)otherGestureRecognizer;
                if (other.numberOfTapsRequired == 2) {
                    return YES;
                }
            }
        }
    }
    return NO;
}

- (void)tapOnce:(UITapGestureRecognizer *)tapGesture {
    [self toggleNavigationBarHidden];
    if (self.navigationController.navigationBar.alpha == 0) {
        [self darkenBackground];
    } else [self brightenBackground];
}

#pragma mark - background

- (void)darkenBackground {
    [self setBackgroundBrightness:0];
}

- (void)brightenBackground {
    [self setBackgroundBrightness:1];
}

- (void)setBackgroundBrightness:(float)brightness {
    [UIView animateWithDuration:0.4 animations:^{
        [self.darkBackgroundView setBackgroundColor:[UIColor colorWithWhite:brightness alpha:1]];
    }];
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
    self.itemSize = [NSValue valueWithCGSize:CGSizeMake(size.width, CGRectGetHeight(self.collectionView.frame))];
    return size;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return CELL_SPACING;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return CELL_SPACING;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsZero;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    NSInteger page = [self currentCollectionViewPage:scrollView];
    if (self.previousPage != page) {
        if (!shouldHideNavigationBar) {
            [self hideNavigationBar];
            [self darkenBackground];
        } else {
            shouldHideNavigationBar = NO;
        }
        
        self.previousPage = page;
        if (!self.justOpened) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(photosHorizontalScrollingViewController:didChangePage:item:)]) {
                //NSManagedObject *photo = [self.dataSource managedObjectItemAtIndexPath:[NSIndexPath indexPathForItem:page inSection:0]];
                id photo = [self.photos objectAtIndex:page];
                [self.delegate photosHorizontalScrollingViewController:self didChangePage:page item:photo];
            }
            [self insertBackgroundSnapshotView];
        } else {
            self.justOpened = NO;
            [self showHintIfNeeded];
        }
    }
}

#pragma mark - Hint

- (void)showHintIfNeeded {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:PBX_DID_SHOW_SCROLL_UP_AND_DOWN_TO_CLOSE_FULL_SCREEN_PHOTO]) {
        PhotoZoomableCell *currentCell = [self currentCell];
        if (currentCell) {
            [currentCell doTeasingGesture];
        }
    }
}

#pragma mark - CustomAnimationTransitionFromViewControllerDelegate


- (PhotoZoomableCell *)currentCell {
    return [[self.collectionView visibleCells] firstObject];
}

- (UIView *)viewToAnimate {
    return [self currentCell].thisImageview;
}

- (UIImage *)imageToAnimate {
    return nil;
}

- (CGSize)actualImageSize {
    return CGSizeZero;
}

- (CGRect)startRectInContainerView:(UIView *)view {
    PhotoZoomableCell *cell = [self currentCell];
    return cell.thisImageview.frame;
}

- (CGRect)endRectInContainerView:(UIView *)view {
    return CGRectZero;
}


@end
