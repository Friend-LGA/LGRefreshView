//
//  RefreshTableViewController.m
//  LGRefreshViewDemo
//
//  Created by Grigory Lutkov on 21.02.15.
//  Copyright (c) 2015 Grigory Lutkov. All rights reserved.
//

#import "RefreshTableViewController.h"
#import "LGRefreshView.h"

@interface RefreshTableViewController () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) UITableView   *tableView;
@property (strong, nonatomic) NSString      *updateString;
@property (strong, nonatomic) UIButton      *triggerButton;
@property (strong, nonatomic) LGRefreshView *refreshView;

@end

@implementation RefreshTableViewController

- (id)initWithTitle:(NSString *)title
{
    self = [super init];
    if (self)
    {
        self.title = title;

        // -----

        UIColor *blueColor = [UIColor colorWithRed:0.f green:0.5 blue:1.f alpha:1.f];
        UIColor *grayColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.f];

        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.backgroundColor = [UIColor whiteColor];
        _tableView.alwaysBounceVertical = YES;
        _tableView.allowsSelection = NO;
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
        [self.view addSubview:_tableView];

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

        _refreshView = [LGRefreshView refreshViewWithScrollView:_tableView
                                                 refreshHandler:^(LGRefreshView *refreshView)
                        {
                            if (wself)
                            {
                                __strong typeof(wself) self = wself;

                                NSDate *date = [NSDate date];
                                NSDateFormatter *dateFormatter = [NSDateFormatter new];
                                dateFormatter.dateFormat = @"yyyy.MM.dd HH:mm:ss";

                                self.updateString = [NSString stringWithFormat:@"Updated at %@", [dateFormatter stringFromDate:date]];

                                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];

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

    _tableView.frame = CGRectMake(0.f, 0.f, self.view.frame.size.width, self.view.frame.size.height);

    _triggerButton.frame = CGRectMake(0.f, self.view.frame.size.height-44.f, self.view.frame.size.width, 44.f);
}

#pragma mark - Rotation

/** It's not necessary, but better doing like so */
- (BOOL)shouldAutorotate
{
    return !_refreshView.isRefreshing;
}

#pragma mark - UITableView DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

#pragma mark - UITableView Delegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];

    cell.textLabel.text = _updateString;
    
    return cell;
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44.f;
}

#pragma mark -

- (void)triggerAction
{
    [_refreshView triggerAnimated:YES];
}

@end
