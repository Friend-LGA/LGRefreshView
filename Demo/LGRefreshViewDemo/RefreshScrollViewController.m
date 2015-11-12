//
//  RefreshScrollViewController.m
//  LGRefreshViewDemo
//
//  Created by Grigory Lutkov on 18.02.15.
//  Copyright (c) 2015 Grigory Lutkov. All rights reserved.
//

#import "RefreshScrollViewController.h"
#import "LGRefreshView.h"

@interface RefreshScrollViewController ()

@property (strong, nonatomic) UIScrollView  *scrollView;
@property (strong, nonatomic) UILabel       *updateLabel;
@property (strong, nonatomic) UIButton      *triggerButton;
@property (strong, nonatomic) LGRefreshView *refreshView;

@end

@implementation RefreshScrollViewController

- (id)initWithTitle:(NSString *)title
{
    self = [super init];
    if (self)
    {
        self.title = title;

        // -----

        UIColor *blueColor = [UIColor colorWithRed:0.f green:0.5 blue:1.f alpha:1.f];
        UIColor *grayColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.f];

        _scrollView = [UIScrollView new];
        _scrollView.backgroundColor = [UIColor whiteColor];
        _scrollView.alwaysBounceVertical = YES;
        [self.view addSubview:_scrollView];

        _updateLabel = [UILabel new];
        _updateLabel.font = [UIFont systemFontOfSize:16.f];
        _updateLabel.text = @"Updated never";
        [_scrollView addSubview:_updateLabel];

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

        _refreshView = [LGRefreshView refreshViewWithScrollView:_scrollView
                                                 refreshHandler:^(LGRefreshView *refreshView)
                        {
                            if (wself)
                            {
                                __strong typeof(wself) self = wself;

                                NSDate *date = [NSDate date];
                                NSDateFormatter *dateFormatter = [NSDateFormatter new];
                                dateFormatter.dateFormat = @"yyyy.MM.dd HH:mm:ss";

                                self.updateLabel.text = [NSString stringWithFormat:@"Updated at %@", [dateFormatter stringFromDate:date]];
                                [self.updateLabel sizeToFit];
                                self.updateLabel.center = CGPointMake(self.scrollView.frame.size.width/2, 20.f+self.updateLabel.frame.size.height/2);
                                self.updateLabel.frame = CGRectIntegral(self.updateLabel.frame);

                                self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, self.updateLabel.frame.origin.y+self.updateLabel.frame.size.height+20.f);

                                [UIView transitionWithView:self.updateLabel
                                                  duration:0.3
                                                   options:UIViewAnimationOptionTransitionCrossDissolve
                                                animations:nil
                                                completion:nil];

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

    _scrollView.frame = CGRectMake(0.f, 0.f, self.view.frame.size.width, self.view.frame.size.height);

    [_updateLabel sizeToFit];
    _updateLabel.center = CGPointMake(_scrollView.frame.size.width/2, 20.f+_updateLabel.frame.size.height/2);
    _updateLabel.frame = CGRectIntegral(_updateLabel.frame);

    _scrollView.contentSize = CGSizeMake(_scrollView.frame.size.width, _updateLabel.frame.origin.y+_updateLabel.frame.size.height+20.f);

    _triggerButton.frame = CGRectMake(0.f, self.view.frame.size.height-44.f, self.view.frame.size.width, 44.f);
}

#pragma mark - Rotation

/** It's not necessary, but better doing like so */
- (BOOL)shouldAutorotate
{
    return !_refreshView.isRefreshing;
}

#pragma mark -

- (void)triggerAction
{
    [_refreshView triggerAnimated:YES];
}

@end
