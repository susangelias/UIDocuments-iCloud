//
//  GuidesLocalAppDelegate.m
//  GuidesLocal
//
//  Created by Susan Elias on 3/7/14.
//  Copyright (c) 2014 GriffTech. All rights reserved.
//

#import "GuidesLocalAppDelegate.h"
#import "DocumentsListTVC.h"
#import "DocumentViewController.h"

@implementation GuidesLocalAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        /*
        UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
        UINavigationController *leftNavController = [splitViewController.viewControllers objectAtIndex:0];
        DocumentsListTVC *leftViewController = (DocumentsListTVC *)[leftNavController topViewController];
        UINavigationController  * rightNavController = [splitViewController.viewControllers objectAtIndex:1];
        DocumentViewController *rightViewController = (DocumentViewController *)[rightNavController topViewController];
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
        [leftViewController.tableView selectRowAtIndexPath:indexPath
                                                  animated:YES
                                            scrollPosition:UITableViewScrollPositionTop];
        
        NSURL *fileURL = [leftViewController.fileList objectAtIndex:0];
        leftViewController.selectedDocument = [[GuideDocument alloc]initWithFileURL:fileURL];
        rightViewController.guideDocument = leftViewController.selectedDocument;
        splitViewController.delegate = rightViewController;
         */
    }
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
