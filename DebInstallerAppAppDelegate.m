#import "DebInstallerAppAppDelegate.h"
#import "RootViewController.h"

@implementation DebInstallerAppAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[[RootViewController alloc] init]];
	[self.window makeKeyAndVisible];
	return YES;
}

@end
