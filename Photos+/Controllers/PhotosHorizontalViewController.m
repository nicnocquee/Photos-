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

#import "UIView+Additionals.h"

#import "PhotoInfoViewController.h"

#import <objc/runtime.h>

#import <UIView+AutoLayout.h>

#import "NSString+Additionals.h"

#import "UIFont+Additionals.h"

#import "LocationManager.h"

#import "DateInfoView.h"

#define CELL_SPACING 20
#define PBX_DID_SHOW_SCROLL_UP_AND_DOWN_TO_CLOSE_FULL_SCREEN_PHOTO @"photobox.PBX_DID_SHOW_SCROLL_UP_AND_DOWN_TO_CLOSE_FULL_SCREEN_PHOTO"


@interface PhotosHorizontalViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate, PhotoZoomableCellDelegate, PhotoInfoViewControllerDelegate> {
    BOOL shouldHideNavigationBar;
}

@property (nonatomic, strong) NSValue *itemSize;

@property (nonatomic, strong) UIView *darkBackgroundView;

@property (nonatomic, assign) NSInteger previousPage;
@property (nonatomic, assign) BOOL justOpened;
@property (nonatomic, strong) UIView *backgroundViewControllerView;
@property (nonatomic, strong) UIView *photoInfoBackgroundGradientView;

@property (nonatomic, strong) DateInfoView *dateInfoView;

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
    [self.collectionView setContentInset:UIEdgeInsetsMake(0, 0, 0, CELL_SPACING)];
    [self.collectionView registerClass:[PhotoZoomableCell class] forCellWithReuseIdentifier:NSStringFromClass([PhotoZoomableCell class])];
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.firstShownPhotoIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionLeft animated:NO];
    [self.collectionView setBackgroundColor:[UIColor clearColor]];
    
    UITapGestureRecognizer *tapOnce = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnce:)];
    [tapOnce setDelegate:self];
    [tapOnce setNumberOfTapsRequired:1];
    [self.collectionView addGestureRecognizer:tapOnce];
    
    self.darkBackgroundView = [[UIView alloc] initWithFrame:self.view.frame];
    [self.darkBackgroundView setBackgroundColor:[UIColor colorWithWhite:1 alpha:1]];
    [self.collectionView setBackgroundView:self.darkBackgroundView];
    
    UIBarButtonItem *infoButton = [[UIBarButtonItem alloc] initWithTitle:@"Info" style:UIBarButtonItemStyleBordered target:self action:@selector(infoButtonTapped:)];
    [self.navigationItem setRightBarButtonItem:infoButton];
    
    [self insertDateInfoView];
}

- (void)viewWillAppear:(BOOL)animated {
    [self insertBackgroundSnapshotView];
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

- (void)insertDateInfoView {
    if (!self.dateInfoView) {
        self.dateInfoView = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([DateInfoView class]) owner:nil options:nil] firstObject];
        [self.dateInfoView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.view addSubview:self.dateInfoView];
        [self.dateInfoView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.view];
        [self.dateInfoView autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:self.view];
        [self.dateInfoView autoPinEdge:ALEdgeRight toEdge:ALEdgeRight ofView:self.view];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(infoButtonTapped:)];
        [self.dateInfoView addGestureRecognizer:tap];
        [self.dateInfoView setUserInteractionEnabled:YES];
    }
    
    [self setDateInfoText];
}

- (void)setDateInfoText {
    NSInteger currentPage = [self currentCollectionViewPage:self.collectionView];
    PhotoAsset *asset = [self.photos objectAtIndex:currentPage];
    NSString *date = [asset dateTakenString];
    if (!date) {
        date = [asset dateCreatedString];
    }
    [self.dateInfoView.dateLabel setText:date];
    
    CLLocation *location = [asset clLocation];
    if (location) {
        [[LocationManager sharedManager] nameForLocation:location completionHandler:^(NSString *placemark, NSError *error) {
            if (currentPage == [self currentCollectionViewPage:self.collectionView]) {
                if (!error) {
                    [self.dateInfoView.locationLabel setText:placemark];;
                } else {
                    [self.dateInfoView.locationLabel setText:NSLocalizedString(@"Not available", nil)];
                }
            }
            
        }];
    } else {
        [self.dateInfoView.locationLabel setText:NSLocalizedString(@"Not available", nil)];
    }
}

- (void)setDateInfoLabelHidden:(BOOL)hidden {
    [UIView animateWithDuration:0.3 animations:^{
        [self.dateInfoView setAlpha:(hidden)?0:1];
    } completion:^(BOOL finished) {
        [self.dateInfoView setHidden:hidden];
    }];
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
    [cell setDelegate:self];
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
                id photo = [self.photos objectAtIndex:page];
                [self.delegate photosHorizontalScrollingViewController:self didChangePage:page item:photo];
            }
            [self insertBackgroundSnapshotView];
            [self setDateInfoText];
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
    return [cell.thisImageview convertFrameRectToView:view];
}

- (CGRect)endRectInContainerView:(UIView *)view {
    return CGRectZero;
}

#pragma mark - Zoomable Cell delegate

- (void)didCancelClosingPhotosHorizontalViewController {
    
}

- (void)didClosePhotosHorizontalViewController{
    [[self currentCell] setClosingViewController:YES];
    [self.delegate photosHorizontalWillClose];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didDragDownWithPercentage:(float)progress {
    CGFloat alpha = MIN(1-progress+0.3, 1);
    [self.darkBackgroundView setAlpha:alpha];
}

#pragma mark - Info

- (void)infoButtonTapped:(id)sender {
    [sender setEnabled:NO];
    
    [self setDateInfoLabelHidden:YES];
    
    BOOL isGrayscaled = [[self currentCell] isGrayscaled];
    [self setNavigationBarHidden:!isGrayscaled animated:YES];
    [[self currentCell] setGrayscaleAndZoom:!isGrayscaled];
    
    UIView *gradientView = [[self currentCell] addTransparentGradientWithStartColor:[UIColor blackColor] fromStartPoint:CGPointMake(0, 1) endPoint:CGPointMake(0.7, 0.5)];
    self.photoInfoBackgroundGradientView = gradientView;
    [gradientView setAlpha:0];
    
    PhotoInfoViewController *photoInfo = [[PhotoInfoViewController alloc] initWithStyle:UITableViewStyleGrouped];
    PhotoAsset *photo = [[self currentCell] item];
    [photoInfo setPhoto:photo];
    [photoInfo setDelegate:self];
    [photoInfo willMoveToParentViewController:self];
    [self addChildViewController:photoInfo];
    [self.view addSubview:photoInfo.view];
    [photoInfo didMoveToParentViewController:self];
    [photoInfo.view setOriginY:CGRectGetHeight(self.collectionView.frame)];
    
    [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        [gradientView setAlpha:1];
        [photoInfo.view setOriginY:CGRectGetHeight([[UIApplication sharedApplication] statusBarFrame])];
    } completion:^(BOOL finished) {
        [sender setEnabled:YES];
    }];
}

#pragma mark - Photo Info View Controller

- (void)photoInfoViewControllerDidClose:(PhotoInfoViewController *)photoInfo {
    UIViewController *childVC = [self childViewControllers][0];
    [childVC removeFromParentViewController];
    [UIView animateWithDuration:0.5 animations:^{
        [childVC.view setOriginY:CGRectGetHeight(self.collectionView.frame)];
        [self.photoInfoBackgroundGradientView setAlpha:0];
    } completion:^(BOOL finished) {
        [childVC.view removeFromSuperview];
        [self.photoInfoBackgroundGradientView removeFromSuperview];
        [[self currentCell] setGrayscaleAndZoom:NO animated:YES];
    }];
    
    [self setDateInfoLabelHidden:NO];
}

- (void)photoInfoViewController:(PhotoInfoViewController *)photoInfo didDragToClose:(CGFloat)progress {
    [[[self currentCell] grayImageView] setAlpha:1-progress];
}

@end
