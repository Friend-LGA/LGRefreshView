//
//  RefreshCollectionViewController.m
//  LGRefreshViewDemo
//
//  Created by Grigory Lutkov on 22.02.15.
//  Copyright (c) 2015 Grigory Lutkov. All rights reserved.
//

#import "RefreshCollectionViewController.h"
#import "LGRefreshView.h"

@interface RefreshCollectionViewCell : UICollectionViewCell

@property (strong, nonatomic) UILabel   *textLabel;
@property (strong, nonatomic) UIView    *separatorView;

@end

@implementation RefreshCollectionViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _textLabel = [UILabel new];
        _textLabel.font = [UIFont systemFontOfSize:16.f];
        [self addSubview:_textLabel];

        _separatorView = [UIView new];
        _separatorView.backgroundColor = [UIColor colorWithRed:0.85 green:0.85 blue:0.85 alpha:1.f];
        [self addSubview:_separatorView];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    [_textLabel sizeToFit];
    _textLabel.center = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
    _textLabel.frame = CGRectIntegral(_textLabel.frame);

    _separatorView.frame = CGRectMake(15.f, self.frame.size.height-1.f, self.frame.size.width-30.f, 1.f);
}

@end

#pragma mark -

@interface RefreshCollectionViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (strong, nonatomic) UICollectionView  *collectionView;
@property (strong, nonatomic) NSString          *updateString;
@property (strong, nonatomic) UIButton          *triggerButton;
@property (strong, nonatomic) LGRefreshView     *refreshView;

@end

@implementation RefreshCollectionViewController

- (id)initWithTitle:(NSString *)title
{
    self = [super init];
    if (self)
    {
        self.title = title;

        // -----

        UIColor *blueColor = [UIColor colorWithRed:0.f green:0.5 blue:1.f alpha:1.f];
        UIColor *grayColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.f];

        UICollectionViewFlowLayout *collectionViewLayout = [UICollectionViewFlowLayout new];
        collectionViewLayout.sectionInset = UIEdgeInsetsZero;
        collectionViewLayout.minimumLineSpacing = 0.f;
        collectionViewLayout.minimumInteritemSpacing = 0.f;
        collectionViewLayout.scrollDirection = UICollectionViewScrollDirectionVertical;

        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:collectionViewLayout];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        _collectionView.backgroundColor = [UIColor whiteColor];
        _collectionView.alwaysBounceVertical = YES;
        _collectionView.allowsSelection = NO;
        [_collectionView registerClass:[RefreshCollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
        [self.view addSubview:_collectionView];

        _updateString = @"Updated never";

        _triggerButton = [UIButton new];
        [_triggerButton setBackgroundImage:[self image1x1WithColor:grayColor] forState:UIControlStateNormal];
        [_triggerButton setBackgroundImage:[self image1x1WithColor:blueColor] forState:UIControlStateHighlighted];
        [_triggerButton setTitle:@"Trigger" forState:UIControlStateNormal];
        [_triggerButton setTitleColor:blueColor forState:UIControlStateNormal];
        [_triggerButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
        [_triggerButton addTarget:self action:@selector(triggerAction) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_triggerButton];

        // -----

        __weak typeof(self) wself = self;

        _refreshView = [LGRefreshView refreshViewWithScrollView:_collectionView
                                                 refreshHandler:^(LGRefreshView *refreshView)
                        {
                            if (wself)
                            {
                                __strong typeof(wself) self = wself;

                                NSDate *date = [NSDate date];
                                NSDateFormatter *dateFormatter = [NSDateFormatter new];
                                dateFormatter.dateFormat = @"yyyy.MM.dd HH:mm:ss";

                                self.updateString = [NSString stringWithFormat:@"Updated at %@", [dateFormatter stringFromDate:date]];

                                [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:0 inSection:0]]];

                                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void)
                                               {
                                                   [self.refreshView endRefreshing];
                                               });
                            }
                        }];
        _refreshView.tintColor = blueColor;
        _refreshView.backgroundColor = grayColor;
    }
    return self;
}

- (UIImage *)image1x1WithColor:(UIColor *)color
{
    CGRect rect = CGRectMake(0.f, 0.f, 1.f, 1.f);

    UIGraphicsBeginImageContext(rect.size);

    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, rect);

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return image;
}

#pragma mark - Dealloc

- (void)dealloc
{
    NSLog(@"%s [Line %d]", __PRETTY_FUNCTION__, __LINE__);
}

#pragma mark - Appearing

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    [_collectionView.collectionViewLayout invalidateLayout];
    _collectionView.frame = CGRectMake(0.f, 0.f, self.view.frame.size.width, self.view.frame.size.height);

    _triggerButton.frame = CGRectMake(0.f, self.view.frame.size.height-44.f, self.view.frame.size.width, 44.f);
}

#pragma mark - Rotation

/** Its not nessessery, but better duing like so */
- (BOOL)shouldAutorotate
{
    return !_refreshView.isRefreshing;
}

#pragma mark - UICollectionView DataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 1;
}

#pragma mark - UICollectionView Delegate

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    RefreshCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];

    cell.textLabel.text = _updateString;

    [cell setNeedsLayout];

    return cell;
}

#pragma mark - UICollectionViewLayout Delegate

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(self.view.frame.size.width, 44.f);
}

#pragma mark -

- (void)triggerAction
{
    [_refreshView triggerAnimated:YES];
}

@end
