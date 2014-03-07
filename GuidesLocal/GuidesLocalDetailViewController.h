//
//  GuidesLocalDetailViewController.h
//  GuidesLocal
//
//  Created by Susan Elias on 3/7/14.
//  Copyright (c) 2014 GriffTech. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GuidesLocalDetailViewController : UIViewController <UISplitViewControllerDelegate>

@property (strong, nonatomic) id detailItem;

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@end
