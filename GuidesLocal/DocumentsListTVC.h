//
//  GuideMasterViewController
//  Guide
//
//  Created by Susan Elias on 3/4/14.
//  Copyright (c) 2014 GriffTech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GuideDocument.h"

@class DocumentViewController;

@interface DocumentsListTVC : UITableViewController
#define kGenericFileName   @"NewGuide"

@property (strong, nonatomic) DocumentViewController *detailViewController;
@property (strong, nonatomic) NSMutableArray *fileList;
@property (nonatomic, strong) GuideDocument *selectedDocument;

- (IBAction)insertNewObject:(UIBarButtonItem *)sender;

@end
