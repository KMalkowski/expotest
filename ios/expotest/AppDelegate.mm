#import <Expo/Expo.h>
#import <ExpoModulesCore/EXReactDelegateWrapper.h>
#import <ExpoModulesCore/Swift.h>
#import <ReactCommon/RCTTurboModuleManager.h>
// This is broken in React Native < 0.76, so we call the implementation of the method manually
// https://github.com/facebook/react-native/issues/44329
// #import "RCTAppSetupUtils.h"
#import "AppDelegate.h"

#import <React/RCTBundleURLProvider.h>
#import <React/RCTLinkingManager.h>

@interface RCTAppDelegate () <RCTTurboModuleManagerDelegate>
@end

@interface AppDelegate()

@property (nonatomic, strong) EXReactDelegateWrapper *reactDelegate;

@end

@implementation AppDelegate {
    EXExpoAppDelegate *_expoAppDelegate;
}

// Synthesize window, so the AppDelegate can synthesize it too.
@synthesize window = _window;

- (instancetype)init
{
  if (self = [super init]) {
    _expoAppDelegate = [[EXExpoAppDelegate alloc] init];
    _reactDelegate = [[EXReactDelegateWrapper alloc] initWithExpoReactDelegate:_expoAppDelegate.reactDelegate];
  }
  return self;
}

// This needs to be implemented, otherwise forwarding won't be called.
// When the app starts, `UIApplication` uses it to check beforehand
// which `UIApplicationDelegate` selectors are implemented.
- (BOOL)respondsToSelector:(SEL)selector
{
  return [super respondsToSelector:selector]
    || [_expoAppDelegate respondsToSelector:selector];
}

// Forwards all invocations to `ExpoAppDelegate` object.
- (id)forwardingTargetForSelector:(SEL)selector
{
  return _expoAppDelegate;
}

- (UIViewController *)createRootViewController
{
  return [self.reactDelegate createRootViewController];
}

- (RCTRootViewFactory *)createRCTRootViewFactory
{
  RCTRootViewFactoryConfiguration *configuration =
      [[RCTRootViewFactoryConfiguration alloc] initWithBundleURL:self.bundleURL
                                                  newArchEnabled:self.fabricEnabled
                                              turboModuleEnabled:self.turboModuleEnabled
                                               bridgelessEnabled:self.bridgelessEnabled];

  __weak __typeof(self) weakSelf = self;
  configuration.createRootViewWithBridge = ^UIView *(RCTBridge *bridge, NSString *moduleName, NSDictionary *initProps)
  {
    return [weakSelf createRootViewWithBridge:bridge moduleName:moduleName initProps:initProps];
  };

  configuration.createBridgeWithDelegate = ^RCTBridge *(id<RCTBridgeDelegate> delegate, NSDictionary *launchOptions)
  {
    return [weakSelf createBridgeWithDelegate:delegate launchOptions:launchOptions];
  };

  return [[EXReactRootViewFactory alloc] initWithReactDelegate:self.reactDelegate configuration:configuration turboModuleManagerDelegate:self];
}

- (void)finishedLaunchingWithOptions:(UISceneConnectionOptions *)connectionOptions
{
  [_expoAppDelegate application:[UIApplication sharedApplication] didFinishLaunchingWithOptions:[self connectionOptionsToLaunchOptions:connectionOptions]];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  self.moduleName = @"main";

  // You can add your custom initial props in the dictionary below.
  // They will be passed down to the ViewController used by React Native.
  self.initialProps = @{};

  return YES;
}

- (NSURL *)sourceURLForBridge:(RCTBridge *)bridge
{
  return [self bundleURL];
}

- (NSURL *)bundleURL
{
#if DEBUG
  return [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@".expo/.virtual-metro-entry"];
#else
  return [[NSBundle mainBundle] URLForResource:@"main" withExtension:@"jsbundle"];
#endif
}

// Linking API
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
  return [super application:application openURL:url options:options] || [RCTLinkingManager application:application openURL:url options:options];
}

// Universal Links
- (BOOL)application:(UIApplication *)application continueUserActivity:(nonnull NSUserActivity *)userActivity restorationHandler:(nonnull void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler {
  BOOL result = [RCTLinkingManager application:application continueUserActivity:userActivity restorationHandler:restorationHandler];
  return [super application:application continueUserActivity:userActivity restorationHandler:restorationHandler] || result;
}

// Explicitly define remote notification delegates to ensure compatibility with some third-party libraries
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
  return [super application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

// Explicitly define remote notification delegates to ensure compatibility with some third-party libraries
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
  return [super application:application didFailToRegisterForRemoteNotificationsWithError:error];
}

// Explicitly define remote notification delegates to ensure compatibility with some third-party libraries
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
  return [super application:application didReceiveRemoteNotification:userInfo fetchCompletionHandler:completionHandler];
}

- (BOOL)initAppFromScene:(UISceneConnectionOptions *)connectionOptions {
    // If bridge has already been initiated by another scene, there's nothing to do here
    if (self.bridge != nil) {
        return NO;
    }

    if (self.bridge == nil) {
      // This is broken in React Native < 0.76, so we call the implementation of the method manually
      // https://github.com/facebook/react-native/issues/44329
      // RCTAppSetupPrepareApp([UIApplication sharedApplication], self.turboModuleEnabled);
      
      // # BEGIN OF RCTAppSetupPrepareApp
      RCTEnableTurboModule(self.turboModuleEnabled);

      #if DEBUG
        // Disable idle timer in dev builds to avoid putting application in background and complicating
        // Metro reconnection logic. Users only need this when running the application using our CLI tooling.
        [UIApplication sharedApplication].idleTimerDisabled = YES;
      #endif
      // # END OF RCTAppSetupPrepareApp
      
      self.rootViewFactory = [self createRCTRootViewFactory];
    }

    NSDictionary * initProps = [self prepareInitialProps];
    self.rootView = [self.rootViewFactory viewWithModuleName:self.moduleName initialProperties:initProps launchOptions:[self connectionOptionsToLaunchOptions:connectionOptions]];

    self.rootView.backgroundColor = [UIColor blackColor];

    return YES;
}

- (NSDictionary<NSString *, id> *)prepareInitialProps {
    NSMutableDictionary<NSString *, id> *initProps = [self.initialProps mutableCopy] ?: [NSMutableDictionary dictionary];
#if RCT_NEW_ARCH_ENABLED
    initProps[@"kRNConcurrentRoot"] = [self concurrentRootEnabled];
#endif
    return [initProps copy];
}

- (NSDictionary<UIApplicationLaunchOptionsKey, id> *)connectionOptionsToLaunchOptions:(UISceneConnectionOptions *)connectionOptions {
    NSMutableDictionary<UIApplicationLaunchOptionsKey, id> *launchOptions = [NSMutableDictionary dictionary];

    if (connectionOptions) {
        if (connectionOptions.notificationResponse) {
            launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey] = connectionOptions.notificationResponse.notification.request.content.userInfo;
        }

        if ([connectionOptions.userActivities count] > 0) {
            NSUserActivity* userActivity = [connectionOptions.userActivities anyObject];
            NSDictionary *userActivityDictionary = @{
                @"UIApplicationLaunchOptionsUserActivityTypeKey": [userActivity activityType] ? [userActivity activityType] : [NSNull null],
                @"UIApplicationLaunchOptionsUserActivityKey": userActivity ? userActivity : [NSNull null]
            };
            launchOptions[UIApplicationLaunchOptionsUserActivityDictionaryKey] = userActivityDictionary;
        }

        NSURL *url = connectionOptions.URLContexts.anyObject.URL;
        if (url != nil) {
          // Log the URL to the console
          NSLog(@"<<<FM>>> URL: %@", url.absoluteString);
          launchOptions[UIApplicationLaunchOptionsURLKey] = url;
        }
    }

    return launchOptions;
}
@end
