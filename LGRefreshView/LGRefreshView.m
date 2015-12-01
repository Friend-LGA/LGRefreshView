//
//  LGRefreshView.m
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

#import "LGRefreshView.h"
#import "DACircularProgressView.h"

#define kLGRefreshViewMainScreenSideMax         MAX(UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height)
#define kLGRefreshViewDeviceIsOld               (NSProcessInfo.processInfo.activeProcessorCount < 2)
#define kLGRefreshViewDegreesToRadians(d)       ((d) * M_PI / 180)
#define kLGRefreshViewCircleOutMaxProgress      (_loadingView ? 1.f : 0.93)
#define kLGRefreshViewCircleInMaxProgress       (_loadingView ? 1.f : 0.9)
#define kLGRefreshViewHeight                    64.f
#define kLGRefreshViewCircleOutSize             (kLGRefreshViewHeight * 0.5)
#define kLGRefreshViewCircleInSize              (kLGRefreshViewHeight * 0.3)
#define kLGRefreshViewCircleOutThicknessRatio   0.2
#define kLGRefreshViewCircleInThicknessRatio    0.25

static UIView *kLGRefreshViewLoadingView;
static UIColor *kLGRefreshViewTintColor;

@interface LGRefreshView ()

@property (assign, nonatomic, getter=isObserversAdded)  BOOL observersAdded;
@property (assign, nonatomic, getter=isRefreshing)      BOOL refreshing;
@property (assign, nonatomic, getter=isIgnoreInset)     BOOL ignoreInset;
@property (assign, nonatomic, getter=isIgnoreOffset)    BOOL ignoreOffset;
@property (assign, nonatomic, getter=isTransformed)     BOOL transformed;
@property (assign, nonatomic, getter=isTriggered)       BOOL triggered;

@property (assign, nonatomic) UIScrollView              *scrollView;
@property (strong, nonatomic) UIView                    *backgroundView;
@property (strong, nonatomic) DACircularProgressView    *circleViewOut;
@property (strong, nonatomic) DACircularProgressView    *circleViewIn;

@property (assign, nonatomic) UIEdgeInsets originalContentInset;
/** 0.0 - 1.0 */
@property (assign, nonatomic) CGFloat   timeOffset;
@property (strong, nonatomic) NSDate    *beginUpdatingDate;

@end

@implementation LGRefreshView

- (instancetype)initWithScrollView:(UIScrollView *)scrollView
{
    self = [super init];
    if (self)
    {
        _enabled = YES;
        _tintColor = (kLGRefreshViewTintColor ? kLGRefreshViewTintColor : [UIColor colorWithRed:0.f green:0.5 blue:1.0 alpha:1.f]);

        _scrollView = scrollView;

        _originalContentInset = _scrollView.contentInset;

        [super setBackgroundColor:[UIColor clearColor]];

        _circleViewOut = [DACircularProgressView new];
        _circleViewOut.backgroundColor = [UIColor clearColor];
        _circleViewOut.trackTintColor = [UIColor clearColor];
        _circleViewOut.progressTintColor = _tintColor;
        _circleViewOut.roundedCorners = 3;
        [_circleViewOut setProgress:0.f animated:NO];
        _circleViewOut.alpha = 0.f;
        _circleViewOut.layer.anchorPoint = CGPointMake(0.5, 0.5);
        _circleViewOut.thicknessRatio = kLGRefreshViewCircleOutThicknessRatio;
        [self addSubview:_circleViewOut];

        _circleViewIn = [DACircularProgressView new];
        _circleViewIn.backgroundColor = [UIColor clearColor];
        _circleViewIn.trackTintColor = [UIColor clearColor];
        _circleViewIn.progressTintColor = _tintColor;
        _circleViewIn.roundedCorners = 3;
        [_circleViewIn setProgress:0.f animated:NO];
        _circleViewIn.alpha = 0.f;
        _circleViewIn.layer.anchorPoint = CGPointMake(0.5, 0.5);
        _circleViewIn.transform = CGAffineTransformScale(_circleViewIn.transform, -1, 1);
        _circleViewIn.thicknessRatio = kLGRefreshViewCircleInThicknessRatio;
        [self addSubview:_circleViewIn];

        if (kLGRefreshViewLoadingView)
        {
            _loadingView = kLGRefreshViewLoadingView;
            _loadingView.alpha = 0.f;
            [_loadingView removeFromSuperview];
            [self addSubview:_loadingView];
        }

        [_scrollView insertSubview:self atIndex:0];

        [self layoutInvalidate];
    }
    return self;
}

+ (instancetype)refreshViewWithScrollView:(UIScrollView *)scrollView
{
    return [[self alloc] initWithScrollView:scrollView];
}

#pragma mark -

- (instancetype)initWithScrollView:(UIScrollView *)scrollView refreshHandler:(void(^)(LGRefreshView *refreshView))refreshHandler;
{
    self = [self initWithScrollView:scrollView];
    if (self)
    {
        _refreshHandler = refreshHandler;
    }
    return self;
}

+ (instancetype)refreshViewWithScrollView:(UIScrollView *)scrollView refreshHandler:(void(^)(LGRefreshView *refreshView))refreshHandler
{
    return [[self alloc] initWithScrollView:scrollView
                             refreshHandler:refreshHandler];
}

#pragma mark -

- (instancetype)initWithScrollView:(UIScrollView *)scrollView delegate:(id<LGRefreshViewDelegate>)delegate
{
    self = [self initWithScrollView:scrollView];
    if (self)
    {
        _delegate = delegate;
    }
    return self;
}

+ (instancetype)refreshViewWithScrollView:(UIScrollView *)scrollView delegate:(id<LGRefreshViewDelegate>)delegate
{
    return [[self alloc] initWithScrollView:scrollView
                                   delegate:delegate];
}

#pragma mark - Dealloc

- (void)dealloc
{
#if DEBUG
    NSLog(@"%s [Line %d]", __PRETTY_FUNCTION__, __LINE__);
#endif

    _delegate = nil;
}

#pragma mark -

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [super willMoveToSuperview:newSuperview];

    if (!newSuperview)
        [self removeObservers];
    else
        [self addObservers];
}

#pragma mark - Setters and Getters

- (void)setTintColor:(UIColor *)tintColor
{
    _tintColor = tintColor;

    if (_circleViewOut) _circleViewOut.progressTintColor = _tintColor;
    if (_circleViewIn) _circleViewIn.progressTintColor = _tintColor;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    if ([backgroundColor isEqual:[UIColor clearColor]])
    {
        if (_backgroundView)
        {
            [_backgroundView removeFromSuperview];
            _backgroundView = nil;
        }
    }
    else
    {
        if (!_backgroundView)
        {
            _backgroundView = [UIView new];
            _backgroundView.backgroundColor = backgroundColor;
            _backgroundView.frame = CGRectMake(0.f, self.frame.size.height-kLGRefreshViewMainScreenSideMax, self.frame.size.width, kLGRefreshViewMainScreenSideMax);
            [self insertSubview:_backgroundView atIndex:0];
        }

        _backgroundView.backgroundColor = backgroundColor;
    }
}

- (void)setEnabled:(BOOL)enabled
{
    if (enabled != _enabled)
    {
        _enabled = enabled;

        self.hidden = !_enabled;

        if (_enabled) [self addObservers];
        else [self removeObservers];
    }
}

- (void)setOffsetY:(CGFloat)offsetY
{
    if (offsetY != _offsetY)
    {
        _offsetY = offsetY;

        [self layoutInvalidate];
    }
}

- (void)setLoadingView:(UIView *)loadingView
{
    if (_loadingView)
        [_loadingView removeFromSuperview];

    _loadingView = loadingView;

    if (_loadingView)
    {
        _loadingView.alpha = 0.f;
        [_loadingView removeFromSuperview];
        [self addSubview:_loadingView];
    }
}

+ (void)setLoadingView:(UIView *)view
{
    kLGRefreshViewLoadingView = view;

    if (kLGRefreshViewLoadingView)
        kLGRefreshViewLoadingView.alpha = 0.f;
}

+ (void)setTintColor:(UIColor *)tintColor
{
    kLGRefreshViewTintColor = tintColor;
}

#pragma mark -

- (void)layoutInvalidate
{
    if (self.superview)
    {
        CGRect selfFrame = CGRectMake(0.f, -kLGRefreshViewHeight+_offsetY, _scrollView.frame.size.width, kLGRefreshViewHeight);
        if ([UIScreen mainScreen].scale == 1.f)
            selfFrame = CGRectIntegral(selfFrame);
        self.frame = selfFrame;

        if (_backgroundView)
            _backgroundView.frame = CGRectMake(0.f, self.frame.size.height-kLGRefreshViewMainScreenSideMax, self.frame.size.width, kLGRefreshViewMainScreenSideMax);

        CGRect circleFrame = CGRectMake((self.frame.size.width-kLGRefreshViewCircleOutSize)/2,
                                        (self.frame.size.height-kLGRefreshViewCircleOutSize)/2,
                                        kLGRefreshViewCircleOutSize,
                                        kLGRefreshViewCircleOutSize);
        if ([UIScreen mainScreen].scale == 1.f)
            circleFrame = CGRectIntegral(circleFrame);
        _circleViewOut.frame = circleFrame;

        circleFrame = CGRectMake((self.frame.size.width-kLGRefreshViewCircleInSize)/2,
                                 (self.frame.size.height-kLGRefreshViewCircleInSize)/2,
                                 kLGRefreshViewCircleInSize,
                                 kLGRefreshViewCircleInSize);
        if ([UIScreen mainScreen].scale == 1.f)
            circleFrame = CGRectIntegral(circleFrame);
        _circleViewIn.frame = circleFrame;

        if (_loadingView)
            _loadingView.center = CGPointMake(self.frame.size.width/2.f, self.frame.size.height/2.f);
    }
}

- (CGSize)sizeThatFits:(CGSize)size
{
    return CGSizeMake(size.width, kLGRefreshViewHeight);
}

- (void)restoreDefaultState
{
    [_circleViewOut.layer removeAllAnimations];
    _circleViewOut.transform = CGAffineTransformIdentity;
    _circleViewOut.alpha = 0.f;
    [_circleViewOut setProgress:0.f animated:NO];

    [_circleViewIn.layer removeAllAnimations];
    _circleViewIn.transform = CGAffineTransformIdentity;
    _circleViewIn.transform = CGAffineTransformScale(_circleViewIn.transform, -1, 1);
    _circleViewIn.alpha = 0.f;
    [_circleViewIn setProgress:0.f animated:NO];

    [_loadingView.layer removeAllAnimations];
    _loadingView.alpha = 0.f;

    _transformed = NO;

    [self layoutInvalidate];
}

- (void)triggerAnimated:(BOOL)animated
{
    if (!self.isTriggered && !self.isRefreshing)
    {
        _triggered = YES;

        _scrollView.scrollEnabled = YES;
        _scrollView.userInteractionEnabled = YES;

        [self restoreDefaultState];

        [_circleViewOut setProgress:kLGRefreshViewCircleOutMaxProgress animated:NO];
        [_circleViewIn setProgress:kLGRefreshViewCircleInMaxProgress animated:NO];

        if (!_loadingView)
            [self runSpinAnimation];

        if (animated)
        {
            [LGRefreshView animateStandardWithAnimations:^(void)
             {
                 [self triggerAnimations];
             }
                                              completion:^(BOOL finished)
             {
                 [self triggerCompletion];
             }];
        }
        else
        {
            [self triggerAnimations];
            [self triggerCompletion];
        }
    }
}

- (void)triggerAnimations
{
    if (_loadingView)
    {
        if (![_loadingView.superview isEqual:self])
        {
            [_loadingView removeFromSuperview];
            [self addSubview:_loadingView];
        }

        _loadingView.alpha = 1.f;
        _circleViewOut.alpha = 0.f;
        _circleViewIn.alpha = 0.f;

        _loadingView.center = CGPointMake(self.frame.size.width/2.f, self.frame.size.height/2.f);
    }
    else
    {
        _circleViewOut.alpha = 1.f;
        _circleViewIn.alpha = 1.f;
    }

    _circleViewOut.center = CGPointMake(self.frame.size.width/2.f, self.frame.size.height/2.f);
    _circleViewIn.center = CGPointMake(self.frame.size.width/2.f, self.frame.size.height/2.f);

    _ignoreInset = YES;
    _ignoreOffset = YES;
    [_scrollView setContentInset:UIEdgeInsetsMake(self.frame.size.height+_originalContentInset.top, _originalContentInset.left, _originalContentInset.bottom, _originalContentInset.right)];
    _ignoreInset = NO;
    _ignoreOffset = NO;
}

- (void)triggerCompletion
{
    [self beginRefreshing];
}

#pragma mark - Observers

- (void)addObservers
{
    if (!self.isObserversAdded && _scrollView)
    {
        _observersAdded = YES;

        _originalContentInset = _scrollView.contentInset;

        [_scrollView addObserver:self forKeyPath:@"contentInset" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionPrior context:nil];
        [_scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
        [_scrollView addObserver:self forKeyPath:@"bounds" options:NSKeyValueObservingOptionNew context:nil];
    }
}

- (void)removeObservers
{
    if (self.isObserversAdded && _scrollView)
    {
        _observersAdded = NO;

        [_scrollView removeObserver:self forKeyPath:@"contentInset"];
        [_scrollView removeObserver:self forKeyPath:@"contentOffset"];
        [_scrollView removeObserver:self forKeyPath:@"bounds"];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"bounds"])
    {
        if (self.bounds.size.width != _scrollView.bounds.size.width)
        {
            [self layoutInvalidate];

            if (self.isRefreshing)
            {
                [self removeFromSuperview];

                [self restoreDefaultState];

                UIEdgeInsets contentInset = _scrollView.contentInset;
                contentInset.top -= self.bounds.size.height;
                _scrollView.contentInset = contentInset;

                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void)
                               {
                                   if (!self.superview)
                                   {
                                       _refreshing = NO;
                                       _triggered = NO;

                                       [_scrollView insertSubview:self atIndex:0];
                                       [self layoutInvalidate];

                                       _scrollView.scrollEnabled = YES;
                                       _scrollView.userInteractionEnabled = YES;
                                   }
                               });
            }
        }
    }
    else if ([keyPath isEqualToString:@"contentInset"])
    {
        if (self.isIgnoreInset) return;

        UIEdgeInsets newInset = [[change valueForKey:NSKeyValueChangeNewKey] UIEdgeInsetsValue];

        _originalContentInset = newInset;
    }
    else if ([keyPath isEqualToString:@"contentOffset"])
    {
        if (self.isIgnoreOffset) return;

        BOOL isTrackingAndDragging = (_scrollView.isTracking && _scrollView.isDragging);

        CGPoint newOffset = [[change valueForKey:NSKeyValueChangeNewKey] CGPointValue];

        CGFloat offsetY = newOffset.y + _originalContentInset.top;

        // Set position of refreshView subviews
        if (offsetY < 0.f)
        {
            CGFloat tempOffsetY = offsetY+self.frame.size.height/2;
            CGFloat progress = (tempOffsetY >= 0.f ? 0.f : -tempOffsetY/self.frame.size.height) * 2;

            // -----

            if (!self.isRefreshing)
            {
                _circleViewOut.alpha = progress * 2;
                _circleViewIn.alpha = progress * 2;
            }

            // -----

            BOOL isCanTransform = YES;

            if (!kLGRefreshViewDeviceIsOld)
            {
                CGFloat scale = progress + 0.5;

                if (!self.isTransformed && (scale <= 1.f || !CGSizeEqualToSize(_circleViewOut.frame.size, CGSizeMake(kLGRefreshViewCircleOutSize, kLGRefreshViewCircleOutSize))))
                {
                    isCanTransform = NO;

                    if (scale > 1.f) scale = 1.f;

                    CGFloat circleOutSize = kLGRefreshViewCircleOutSize * scale;

                    _circleViewOut.frame = CGRectMake((self.frame.size.width-circleOutSize)/2, self.frame.size.height-circleOutSize/2+offsetY/2, circleOutSize, circleOutSize);

                    CGFloat circleInSize = kLGRefreshViewCircleInSize * scale;

                    _circleViewIn.frame = CGRectMake((self.frame.size.width-circleInSize)/2, self.frame.size.height-circleInSize/2+offsetY/2, circleInSize, circleInSize);
                }
                else
                {
                    _circleViewOut.center = CGPointMake(self.frame.size.width/2, self.frame.size.height+offsetY/2);
                    _circleViewIn.center = CGPointMake(self.frame.size.width/2, self.frame.size.height+offsetY/2);

                    if (_loadingView)
                        _loadingView.center = CGPointMake(self.frame.size.width/2, self.frame.size.height+offsetY/2);
                }
            }
            else
            {
                _circleViewOut.center = CGPointMake(self.frame.size.width/2, self.frame.size.height+offsetY/2);
                _circleViewIn.center = CGPointMake(self.frame.size.width/2, self.frame.size.height+offsetY/2);

                if (_loadingView)
                    _loadingView.center = CGPointMake(self.frame.size.width/2, self.frame.size.height+offsetY/2);
            }

            // -----

            if (!self.isRefreshing && isTrackingAndDragging)
            {
                if (isCanTransform)
                {
                    if (progress > 1.f)
                    {
                        CGFloat angle = progress-1.f;
                        angle = kLGRefreshViewDegreesToRadians(angle);
                        angle *= 150;

                        _circleViewOut.transform = CGAffineTransformIdentity;
                        _circleViewOut.transform = CGAffineTransformRotate(_circleViewOut.transform, angle);

                        _circleViewIn.transform = CGAffineTransformIdentity;
                        _circleViewIn.transform = CGAffineTransformScale(_circleViewIn.transform, -1, 1);
                        _circleViewIn.transform = CGAffineTransformRotate(_circleViewIn.transform, angle);

                        _transformed = YES;
                    }
                    else if (self.isTransformed)
                    {
                        _circleViewOut.transform = CGAffineTransformIdentity;

                        _circleViewIn.transform = CGAffineTransformIdentity;
                        _circleViewIn.transform = CGAffineTransformScale(_circleViewIn.transform, -1, 1);

                        _transformed = NO;
                    }
                }

                // -----

                if (progress > 1.f) progress = 1.f;

                [_circleViewOut setProgress:progress*kLGRefreshViewCircleOutMaxProgress animated:NO];
                [_circleViewIn setProgress:progress*kLGRefreshViewCircleInMaxProgress animated:NO];
            }
        }

        if (self.isRefreshing)
        {
            // Set the inset depending on the situation
            if (!isTrackingAndDragging && offsetY < 0 && offsetY >= -self.frame.size.height)
            {
                _ignoreInset = YES;
                _ignoreOffset = YES;
                [_scrollView setContentInset:UIEdgeInsetsMake(self.frame.size.height+_originalContentInset.top, _originalContentInset.left, _originalContentInset.bottom, _originalContentInset.right)];
                _ignoreInset = NO;
                _ignoreOffset = NO;
            }
        }
        else
        {
            // Start refreshing
            if (!isTrackingAndDragging && _circleViewOut.progress >= kLGRefreshViewCircleOutMaxProgress && offsetY <= -self.frame.size.height)
                [self beginRefreshing];
        }
    }
    else [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

#pragma mark - Animations

- (void)showLoadingView:(BOOL)animated
{
    if (![_loadingView.superview isEqual:self])
    {
        [_loadingView removeFromSuperview];
        [self addSubview:_loadingView];
    }

    if (animated)
    {
        NSTimeInterval duration = 0.2;

        CABasicAnimation *animation;
        animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        animation.duration = duration;
        animation.fromValue = [NSNumber numberWithFloat:1.f];
        animation.removedOnCompletion = NO;

        _circleViewIn.layer.opacity = 0.f;
        [_circleViewIn.layer addAnimation:animation forKey:@"opacityAnimation"];
        _circleViewOut.layer.opacity = 0.f;
        [_circleViewOut.layer addAnimation:animation forKey:@"opacityAnimation"];

        [UIView animateWithDuration:duration
                         animations:^{
                             _loadingView.alpha = 1.f;
                         }];
    }
    else
    {
        _circleViewIn.alpha = 0.f;
        _circleViewOut.alpha = 0.f;
        _loadingView.alpha = 1.f;
    }
}

- (void)runSpinAnimation
{
    if (![_circleViewOut.layer.animationKeys containsObject:@"rotationAnimation"])
    {
        CGFloat multiplier = 1000000.f;
        NSTimeInterval duration = 0.7 * multiplier;
        CGFloat rotations = 1.f * multiplier;

        float value = (M_PI * 2.0 * rotations);

        CABasicAnimation *rotationAnimation;
        rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        rotationAnimation.duration = duration;
        rotationAnimation.cumulative = YES;
        rotationAnimation.repeatCount = 1;

        rotationAnimation.toValue = [NSNumber numberWithFloat:value];

        [_circleViewOut.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];

        rotationAnimation.toValue = [NSNumber numberWithFloat:-value];

        [_circleViewIn.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
    }
}

- (void)beginRefreshing
{
    if (!self.isRefreshing)
    {
        _refreshing = YES;

        _scrollView.scrollEnabled = NO;
        _scrollView.userInteractionEnabled = NO;

        if (_loadingView && !_loadingView.alpha)
            [self showLoadingView:YES];
        else
            [self runSpinAnimation];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void)
                       {
                           _beginUpdatingDate = [NSDate date];

                           // -----

                           [[NSNotificationCenter defaultCenter] postNotificationName:kLGRefreshViewBeginRefreshingNotification object:self userInfo:nil];

                           if (_refreshHandler) _refreshHandler(self);

                           if (_delegate && [_delegate respondsToSelector:@selector(refreshViewRefreshing:)])
                               [_delegate refreshViewRefreshing:self];
                       });
    }
}

- (void)endRefreshing
{
    if (self.isRefreshing)
    {
        NSDate *endUpdatingDate = [NSDate date];
        NSTimeInterval interval = [endUpdatingDate timeIntervalSinceDate:_beginUpdatingDate];

        NSTimeInterval minimum = 1.5;

        if (interval < minimum)
        {
            NSTimeInterval after = minimum-interval;

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(after * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void)
                           {
                               [self endRefreshing2];
                           });
        }
        else [self endRefreshing2];
    }
}

- (void)endRefreshing2
{
    if (self.superview)
    {
        [LGRefreshView animateStandardWithAnimations:^(void)
         {
             [self endRefreshing2Animation];
         }
                                          completion:^(BOOL finished)
         {
             [self endRefreshing2Completion];
         }];
    }
}

- (void)endRefreshing2Animation
{
    if (self.superview)
    {
        _circleViewOut.alpha = 0.f;
        _circleViewIn.alpha = 0.f;

        if (_loadingView && [_loadingView.superview isEqual:self])
            _loadingView.alpha = 0.f;

        _ignoreInset = YES;
        [_scrollView setContentInset:_originalContentInset];
        _ignoreInset = NO;
    }
}

- (void)endRefreshing2Completion
{
    if (self.superview)
    {
        [self restoreDefaultState];

        _refreshing = NO;
        _triggered = NO;

        _scrollView.scrollEnabled = YES;
        _scrollView.userInteractionEnabled = YES;

        // -----

        [[NSNotificationCenter defaultCenter] postNotificationName:kLGRefreshViewEndRefreshingNotification object:self userInfo:nil];
    }
}

#pragma mark - Support

+ (void)animateStandardWithAnimations:(void(^)())animations completion:(void(^)(BOOL finished))completion
{
    if ([UIDevice currentDevice].systemVersion.floatValue >= 7.0)
    {
        [UIView animateWithDuration:0.5
                              delay:0.0
             usingSpringWithDamping:1.f
              initialSpringVelocity:0.5
                            options:0
                         animations:animations
                         completion:completion];
    }
    else
    {
        [UIView animateWithDuration:0.5*0.66
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:animations
                         completion:completion];
    }
}

@end
