//
//  LGRefreshView.h
//  LGRefreshView
//
//
//  The MIT License (MIT)
//
//  Copyright (c) 2015 Grigory Lutkov <Friend.LGA@gmail.com>
//  (https://github.com/Friend-LGA/LGRefreshView)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

#import <UIKit/UIKit.h>

@class LGRefreshView;

static NSString *const kLGRefreshViewBeginRefreshingNotification = @"LGRefreshViewBeginRefreshingNotification";
static NSString *const kLGRefreshViewEndRefreshingNotification   = @"LGRefreshViewEndRefreshingNotification";

@protocol LGRefreshViewDelegate <NSObject>

@required

- (void)refreshViewRefreshing:(LGRefreshView *)refreshView;

@end

@interface LGRefreshView : UIView

@property (assign, nonatomic, readonly, getter=isRefreshing) BOOL refreshing;
@property (assign, nonatomic, getter=isEnabled) BOOL              enabled;
@property (strong, nonatomic) UIColor                             *tintColor;
@property (assign, nonatomic) CGFloat                             offsetY;
@property (assign, nonatomic) UIView                              *loadingView;

/** Do not forget about weak referens to self */
@property (strong, nonatomic) void (^refreshHandler)(LGRefreshView *refreshView);

@property (assign, nonatomic) id<LGRefreshViewDelegate> delegate;

- (instancetype)initWithScrollView:(UIScrollView *)scrollView;
+ (instancetype)refreshViewWithScrollView:(UIScrollView *)scrollView;

#pragma mark -

/** Do not forget about weak referens to self for refreshHandler block */
- (instancetype)initWithScrollView:(UIScrollView *)scrollView
                    refreshHandler:(void(^)(LGRefreshView *refreshView))refreshHandler;

/** Do not forget about weak referens to self for refreshHandler block */
+ (instancetype)refreshViewWithScrollView:(UIScrollView *)scrollView
                           refreshHandler:(void(^)(LGRefreshView *refreshView))refreshHandler;

#pragma mark -

- (instancetype)initWithScrollView:(UIScrollView *)scrollView
                          delegate:(id<LGRefreshViewDelegate>)delegate;

+ (instancetype)refreshViewWithScrollView:(UIScrollView *)scrollView
                                 delegate:(id<LGRefreshViewDelegate>)delegate;

#pragma mark -

+ (void)setTintColor:(UIColor *)tintColor;
+ (void)setLoadingView:(UIView *)view;

/** Needs to be called when refreshing is ended */
- (void)endRefreshing;
/** Force refreshing programmatically */
- (void)triggerAnimated:(BOOL)animated;

#pragma mark -

/** Unavailable, use +refreshViewWithScrollView... instead */
+ (instancetype)new __attribute__((unavailable("use +refreshViewWithScrollView... instead")));
/** Unavailable, use -initWithScrollView... instead */
- (instancetype)init __attribute__((unavailable("use -initWithScrollView... instead")));
/** Unavailable, use -initWithScrollView... instead */
- (instancetype)initWithFrame:(CGRect)frame __attribute__((unavailable("use -initWithScrollView... instead")));

@end
