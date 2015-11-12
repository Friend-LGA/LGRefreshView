# LGRefreshView

iOS pull to refresh for UIScrollView, UITableView and UICollectionView.

## Preview

<img src="https://raw.githubusercontent.com/Friend-LGA/ReadmeFiles/master/LGRefreshView/Preview.gif" width="250"/>
<img src="https://raw.githubusercontent.com/Friend-LGA/ReadmeFiles/master/LGRefreshView/1.png" width="250"/>

## Installation

### With source code

- [Download repository](https://github.com/Friend-LGA/LGRefreshView/archive/master.zip), then add [LGRefreshView directory](https://github.com/Friend-LGA/LGRefreshView/blob/master/LGRefreshView/) to your project.
- Also you need to install [DACircularProgress](https://github.com/danielamitay/DACircularProgress) library.

### With CocoaPods

CocoaPods is a dependency manager for Objective-C, which automates and simplifies the process of using 3rd-party libraries in your projects. To install with cocoaPods, follow the "Get Started" section on [CocoaPods](https://cocoapods.org/).

#### Podfile
```ruby
platform :ios, '6.0'
pod 'LGRefreshView', '~> 1.0.0'
```

### With Carthage

Carthage is a lightweight dependency manager for Swift and Objective-C. It leverages CocoaTouch modules and is less invasive than CocoaPods. To install with carthage, follow the instruction on [Carthage](https://github.com/Carthage/Carthage/).

#### Cartfile
```
github "Friend-LGA/LGRefreshView" ~> 1.0.0
```

## Usage

In the source files where you need to use the library, import the header file:

```objective-c
#import "LGRefreshView.h"
```

### Initialization

You have several methods for initialization:

```objective-c
- (instancetype)initWithScrollView:(UIScrollView *)scrollView; // also you can pass UITableView and UICollectionView, becose its subclasses of UIScrollView
```

More init methods you can find in [LGRefreshView.h](https://github.com/Friend-LGA/LGRefreshView/blob/master/LGRefreshView/LGRefreshView.h)

### Handle actions

To handle actions you can use initialization methods with blocks or delegate, or implement it after initialization.

#### Delegate

```objective-c
@property (assign, nonatomic) id<LGRefreshViewDelegate> delegate;

- (void)refreshViewRefreshing:(LGRefreshView *)refreshView;
```

#### Blocks

```objective-c
@property (strong, nonatomic) void (^refreshHandler)(LGRefreshView *refreshView);
```

#### Notifications

Here is also some notifications, that you can add to NSNotificationsCenter:

```objective-c
kLGRefreshViewBeginRefreshingNotification;
kLGRefreshViewEndRefreshingNotification;
```

### More

For more details try Xcode [Demo project](https://github.com/Friend-LGA/LGRefreshView/blob/master/Demo) and see [LGRefreshView.h](https://github.com/Friend-LGA/LGRefreshView/blob/master/LGRefreshView/LGRefreshView.h)

## License

LGRefreshView is released under the MIT license. See [LICENSE](https://raw.githubusercontent.com/Friend-LGA/LGRefreshView/master/LICENSE) for details.
