#import <RCTAppDelegate.h>
#import <UIKit/UIKit.h>
#import <Expo/Expo.h>

#import <ExpoModulesCore/EXReactDelegateWrapper.h>
#import <React-RCTAppDelegate/RCTAppDelegate.h>

@interface AppDelegate : RCTAppDelegate

@property (nonatomic, strong, readonly) EXReactDelegateWrapper *reactDelegate;
@property (nonatomic, strong) UIView *rootView;

- (BOOL)initAppFromScene:(UISceneConnectionOptions *)connectionOptions;

- (void)finishedLaunchingWithOptions:(UISceneConnectionOptions *)connectionOptions;

@end
