//
//  PhotosViewController.m
//  Photos+
//
//  Created by  on 8/12/14.
//  Copyright (c) 2014 Delightful. All rights reserved.
//

#import "PhotosViewController.h"

#import "PhotoCell.h"

#import "PhotosViewControllerCollectionViewDelegate.h"

#import "PhotoAsset.h"

static void * photosToCheckKVO = &photosToCheckKVO;

@interface PhotosViewController () <UICollectionViewDataSource>

@property (nonatomic, strong) PhotosViewControllerCollectionViewDelegate *collectionViewDelegate;

@end

@implementation PhotosViewController

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
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
    
    self.title = [self title];
    
    self.collectionViewDelegate = [[PhotosViewControllerCollectionViewDelegate alloc] initWithCollectionView:self.collectionView];
    [self.collectionView setDataSource:self];
    [self.collectionView registerClass:[PhotoCell class] forCellWithReuseIdentifier:NSStringFromClass([PhotoCell class])];
        
    self.assets = [[NSMutableOrderedSet alloc] init];
    
    [self loadPhotos];
}

- (void)initObservers {
    [[PhotosLibrary sharedLibrary] addObserver:self forKeyPath:[self photosLibraryPropertyToObserve] options:NSKeyValueObservingOptionNew context:photosToCheckKVO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadPhotos {
    if ([self cachedQueryString]) {
        RLMRealm *realm = [RLMRealm defaultRealm];
        RLMArray *array = [PhotoAsset objectsInRealm:realm where:[self cachedQueryString]];
        for (PhotoAsset *asset in array) {
            [self.assets addObject:asset];
        }
        [self setTitle:[NSString stringWithFormat:@"%@ (%d)", [self title], (int)self.assets.count]];
    } else {
        self.assets = [[PhotosLibrary sharedLibrary] photos];
        NSLog(@"number of assets: %d", (int)self.assets.count);
    }
    [self.collectionView reloadData];
}

- (NSString *)cachedQueryString {
    return nil;
}

- (void)setTitleForProgress:(NSNumber *)prog {
    float progress = [prog floatValue];
    if (progress >= 100) {
        [self.navigationItem setTitleView:nil];
        self.navigationItem.title = [NSString stringWithFormat:@"%@ (%d)", [self title], (int)self.assets.count];
    } else {
        NSString *progressString = [NSString stringWithFormat:NSLocalizedString(@"Analyzing photos %.f%%", nil), progress];
        NSString *text = [NSString stringWithFormat:@"%@\n%@", [self title], progressString];
        NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:text];
        [attr addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:17] range:[text rangeOfString:[self title]]];
        [attr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:12] range:[text rangeOfString:progressString]];
        
        UILabel *label = (UILabel *)self.navigationItem.titleView;
        if (!label || label.tag == 1200) {
            label = [[UILabel alloc] init];
            [label setNumberOfLines:2];
            label.tag = 1200;
            [label setTextAlignment:NSTextAlignmentCenter];
            [self.navigationItem setTitleView:label];
        }
        [label setAttributedText:attr];
        [label sizeToFit];
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

#pragma mark - Notifications

- (void)photosLibraryDidChangeNotification:(NSNotification *)notification {
    NSLog(@"photos library did change");
    [self loadPhotos];
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

@end
