//
//  guideDocumentViewController.h
//  SpeakSteps
//
//  Created by Susan Elias on 3/6/14.
//  Copyright (c) 2014 GriffTech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GuideDocument.h"

@interface GuideDetailViewController : UIViewController <GuideDocumentDelegate, UISplitViewControllerDelegate>

@property (strong, nonatomic) GuideDocument *guideDocument;

@property (weak, nonatomic) IBOutlet UITextView *guideTextView;
@property (strong, nonatomic) id delegate;

@end


@protocol GuideDetailViewControllerDelegate <NSObject>

- (void)deleteFileAtURL: (NSURL *)fileURL;
- (void)renameFileAtURL: (NSURL *)fileURL withName: (NSString *)newName;

@end