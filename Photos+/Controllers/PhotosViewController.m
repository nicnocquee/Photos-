//
//  PhotosViewController.m
//  Photos+
//
//  Created by  on 8/12/14.
//  Copyright (c) 2014 Delightful. All rights reserved.
//

#import "PhotosViewController.h"

#import "PhotoCell.h"

#import "PhotoCellView.h"

#import "PhotosHorizontalViewController.h"

#import "PhotoAsset.h"

#import "PhotosPlusNavigationControllerDelegate.h"

#import "UIView+Additionals.h"

#import "UIViewController+Additionals.h"

static void * photosToCheckKVO = &photosToCheckKVO;

@interface PhotosViewController () <UICollectionViewDataSource, UICollectionViewDelegate, CustomAnimationTransitionFromViewControllerDelegate, PhotosHorizontalViewControllerDelegate>

@property (nonatomic, strong) NSValue *cellSize;

@property (nonatomic, assign) int numberOfColumns;

@property (nonatomic, assign) CGFloat cellSpacing;

@property (nonatomic, strong) PhotosPlusNavigationControllerDelegate *navigationDelegate;

@property (nonatomic, strong) PhotoCell *selectedCell;

@property (nonatomic, strong) PhotoAsset *selectedAsset;

@property (nonatomic, assign) CGRect selectedItemRect;

@end

@implementation PhotosViewController

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.numberOfColumns = 3;
        self.cellSpacing = 1;
        [self setupNotifications];
        [self initObservers];
    }
    return self;
}

- (void)setupNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(photosLibraryDidChangeNotification:) name:photosUpdatedNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:photosUpdatedNotification object:nil];
}

- (void)awakeFromNib {
    self.navigationController.tabBarItem.title = [self tabBarItemTitle];
    self.navigationController.tabBarItem.image = [self tabBarItemImage];
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationDelegate = [[PhotosPlusNavigationControllerDelegate alloc] init];
    [self.navigationController setDelegate:self.navigationDelegate];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    self.title = [self title];

    [self.collectionView setDelegate:self];
    [self.collectionView setDataSource:self];
    [self.collectionView registerClass:[PhotoCell class] forCellWithReuseIdentifier:NSStringFromClass([PhotoCell class])];
        
    self.assets = [[NSMutableOrderedSet alloc] init];
    
    [self loadPhotos];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [self setTabbarHidden:NO];
}

- (void)initObservers {
    [[PhotosLibrary sharedLibrary] addObserver:self forKeyPath:[self photosLibraryPropertyToObserve] options:NSKeyValueObservingOptionNew context:photosToCheckKVO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setTabbarHidden:(BOOL)hidden {
    [UIView animateWithDuration:0.3 animations:^{
        self.navigationController.tabBarController.tabBar.frame = ({
            CGRect frame = self.tabBarController.tabBar.frame;
            frame.origin.x = 0;
            frame.origin.y = CGRectGetHeight(self.navigationController.tabBarController.tabBar.superview.frame) - CGRectGetHeight(self.navigationController.tabBarController.tabBar.frame);
            frame;
        });
        [self.navigationController.tabBarController.tabBar setAlpha:(hidden)?0:1];
    } completion:^(BOOL finished) {
        [self.navigationController.tabBarController.tabBar setHidden:hidden];
    }];
}

- (void)loadPhotos {
    if ([self cachedQueryString]) {
        NSArray *photos = [PhotoAsset instancesWhere:[NSString stringWithFormat:@"%@ order by dateCreated desc", [self cachedQueryString]]];
        [self.assets addObjectsFromArray:photos];
        [self setTitle:[NSString stringWithFormat:@"%@ (%d)", [self title], (int)self.assets.count]];
    } else {
        [self.assets removeAllObjects];
        NSArray *photos = [PhotoAsset instancesOrderedBy:@"dateCreated DESC"];
        [self.assets addObjectsFromArray:photos];
        NSLog(@"number of assets: %d", (int)self.assets.count);
    }
    [self setTitle:[NSString stringWithFormat:@"%@ (%d)", [self title], (int)self.assets.count]];
    
    [self.collectionView reloadData];
    
    if (self.assets.count > 0) {
        for (PhotoAsset *photoAsset in self.assets) {
            [[[PhotosLibrary sharedLibrary] library] assetForURL:photoAsset.url resultBlock:^(ALAsset *asset) {
                if (!asset) {
                    [[PhotosLibrary sharedLibrary] removeAssetWithURL:photoAsset.url];
                }
            } failureBlock:^(NSError *error) {
                
            }];
        }
    }
    
}

- (NSInteger)insertPhotoAsset:(PhotoAsset *)photoAsset {
    NSInteger indexToInsert = 0;
    NSInteger index = [self.assets indexOfObject:photoAsset];
    NSInteger count = self.assets.count;
    if (index != NSNotFound) {
        //NSLog(@"inserted asset exists, ignore");
        indexToInsert = NSNotFound;
    } else {
        //NSLog(@"to insert asset index %d", (int)photoAsset.assetIndex);
        NSArray *assets = [self.assets.array filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"assetIndex > %d", (int)photoAsset.assetIndex]];
        if (assets.count > 0) {
            assets = [assets sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"assetIndex" ascending:NO]]];
            PhotoAsset *nextAsset = [assets lastObject];
            NSAssert(nextAsset, @"Next asset should not be nil");   
            //NSLog(@"last asset index %d", (int)nextAsset.assetIndex);
            NSInteger indexInAssets = [self.assets indexOfObject:nextAsset];
            NSInteger insertIndex = MIN(indexInAssets+1, self.assets.count);
            [self.assets insertObject:photoAsset atIndex:insertIndex];
            indexToInsert = insertIndex;
        } else {
            [self.assets insertObject:photoAsset atIndex:0];
        }
    }
    
    if (self.assets.count > count) {
        if (self.assets.count == 1) {
            [self.collectionView reloadData];
        } else {
            [self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:indexToInsert inSection:0]]];
        }
        
    }
    return indexToInsert;
}

- (void)removePhotoAsset:(PhotoAsset *)photoAsset {
    NSLog(@"[%@] Removing asset url: %@", NSStringFromClass(self.class), photoAsset.url);
}

- (NSString *)cachedQueryString {
    return nil;
}

- (void)setTitleForProgress:(NSNumber *)prog {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:NEW_DATABASE_DEFAULT_KEY]) {
        [self.navigationItem setTitleView:nil];
        self.navigationItem.title = [NSString stringWithFormat:@"%@ (%d)", [self title], (int)self.assets.count];
    } else {
        float progress = [prog floatValue];
        if (progress >= 100) {
            [self.navigationItem setTitleView:nil];
            self.navigationItem.title = [NSString stringWithFormat:@"%@ (%d)", [self title], (int)self.assets.count];
        } else {
            NSString *progressString = [NSString stringWithFormat:NSLocalizedString(@"Analyzing photos %.f%%", nil), progress];
            NSString *title = [self title];
            if (self.assets.count > 0) {
                title = [title stringByAppendingString:[NSString stringWithFormat:@" (%d)", (int)self.assets.count]];
            }
            NSString *text = [NSString stringWithFormat:@"%@\n%@", title, progressString];
            NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:text];
            [attr addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:17] range:[text rangeOfString:title]];
            [attr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:12] range:[text rangeOfString:progressString]];
            
            UILabel *label = [[UILabel alloc] init];
            [label setNumberOfLines:2];
            label.tag = 1200;
            [label setTextAlignment:NSTextAlignmentCenter];
            [self.navigationItem setTitleView:label];
            [label setAttributedText:attr];
            [label sizeToFit];
        }
    }
}

- (void)showLoadingView:(BOOL)show {
    if (show) {
        UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        UIBarButtonItem *loadingItem = [[UIBarButtonItem alloc] initWithCustomView:indicator];
        [self.navigationItem setRightBarButtonItem:loadingItem];
        [indicator startAnimating];
    } else {
        [self.navigationItem setRightBarButtonItem:nil];
    }
}

- (NSString *)tabBarItemTitle {
    return self.title;
}

- (UIImage *)tabBarItemImage {
    return nil;
}

- (NSString *)title {
    return NSLocalizedString(@"All Photos", nil);
}

- (NSString *)photosLibraryPropertyToObserve {
    return NSStringFromSelector(@selector(numberOfPhotosToCheckForAllPhotos));
}

- (void)setSelectedItemRectAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *attributes = [self.collectionView.collectionViewLayout layoutAttributesForItemAtIndexPath:indexPath];
    self.selectedItemRect = attributes.frame;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.assets.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PhotoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([PhotoCell class]) forIndexPath:indexPath];
    [cell setPhotoAsset:[self.assets objectAtIndex:indexPath.item]];
    return cell;
}

#pragma mark - UICollectionViewDelegate

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

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self setTabbarHidden:YES];
    PhotoCell *cell = (PhotoCell *)[collectionView cellForItemAtIndexPath:indexPath];
    self.selectedCell = cell;
    self.selectedAsset = self.assets[indexPath.item];
    [self setSelectedItemRectAtIndexPath:indexPath];
    
    PhotosHorizontalViewController *horizontalPhotos = [[PhotosHorizontalViewController alloc] init];
    [horizontalPhotos setFirstShownPhotoIndex:indexPath.item];
    [horizontalPhotos setDelegate:self];
    [horizontalPhotos setPhotos:self.assets.array];
    
    [self.navigationController pushViewController:horizontalPhotos animated:YES];
}


#pragma mark - Notifications

- (void)photosLibraryDidChangeNotification:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    if (userInfo[insertedAssetKey]) {
        PhotoAsset *asset = [PhotoAsset firstInstanceWhere:@"url = ? order by assetIndex limit 1", userInfo[insertedAssetKey]];
        [self insertPhotoAsset:asset];
    }
    if (userInfo[deletedAssetKey]) {
        NSURL *url = userInfo[deletedAssetKey];
        NSInteger index = [self.assets indexOfObjectPassingTest:^BOOL(PhotoAsset *obj, NSUInteger idx, BOOL *stop) {
            if (obj.url == url) {
                *stop = YES;
                return YES;
            }
            return NO;
        }];
        if (index != NSNotFound) {
            [self.assets removeObjectAtIndex:index];
            [self.collectionView deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:index inSection:0]]];
        }
    }
}

- (void)willEnterForeground:(NSNotification *)notification {
    NSLog(@"%@ did become active", NSStringFromClass(self.class));
    
    [[PhotosLibrary sharedLibrary] checkAssetsExist];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == photosToCheckKVO) {
        NSInteger index = [change[@"new"] integerValue];
        NSInteger total = [[PhotosLibrary sharedLibrary] numberOfPhotosToCheck];
        if (total > 0 && index >= 0) {
            float progress = ((float)(total-index)/(float)total)*100;
            [self performSelectorOnMainThread:@selector(setTitleForProgress:) withObject:@(progress) waitUntilDone:YES];
        }
    }
}

#pragma mark - CustomAnimationTransitionFromViewControllerDelegate

- (UIImage *)imageToAnimate {
    if (self.selectedCell) {
        return self.selectedCell.cellView.imageView.image;
    }
    return nil;
}

- (CGRect)startRectInContainerView:(UIView *)containerView {
    if (self.selectedCell) {
        return [self.selectedCell convertFrameRectToView:containerView];
    }
    return CGRectZero;
}

- (CGSize)actualImageSize {
    ALAsset *asset = self.selectedAsset.rawAsset;
    
    return asset.defaultRepresentation.dimensions;
}

- (CGRect)endRectInContainerView:(UIView *)containerView {
    if (self.selectedCell) {
        CGRect originalPosition = CGRectOffset(self.selectedItemRect, 0, self.collectionView.contentInset.top);
        CGFloat adjustment = self.collectionView.contentOffset.y + self.collectionView.contentInset.top;
        return CGRectOffset(originalPosition, 0, -adjustment);
    }
    return CGRectZero;
    
}

- (UIView *)viewToAnimate {
    return nil;
}

#pragma mark - PhotosHorizontalViewControllerDelegate

- (void)photosHorizontalScrollingViewController:(PhotosHorizontalViewController *)viewController didChangePage:(NSInteger)page item:(id)item {
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[self.assets indexOfObject:item] inSection:0];
    if (indexPath) {
        
        if (indexPath.section < [self.collectionView numberOfSections]) {
            [self setSelectedItemRectAtIndexPath:indexPath];
            
            [self.collectionView scrollRectToVisible:self.selectedItemRect animated:NO];
        }
    }
    
}

- (UIView *)snapshotView {
    return [self.view snapshotViewAfterScreenUpdates:YES];
}

- (CGRect)selectedItemRectInSnapshot {
    return [self endRectInContainerView:nil];
}

- (void)photosHorizontalWillClose {
    [self setNavigationBarHidden:NO animated:YES];
}

@end
