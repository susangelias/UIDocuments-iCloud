//
//  guideDocumentViewController.m
//  GuidesLocal
//
//  Created by Susan Elias on 3/6/14.
//  Copyright (c) 2014 GriffTech. All rights reserved.
//

#import "GuideDetailViewController.h"
#import "GuideDocument.h"
#import "FileExtension.h"




@interface GuideDetailViewController ()

@property (strong, nonatomic) UIPopoverController *masterPopoverController;

@end

@implementation GuideDetailViewController

- (void) awakeFromNib
{
    [super awakeFromNib];
    self.splitViewController.delegate = self;
}


- (void) setGuideDocument:(GuideDocument *)guideDocument
{
    _guideDocument = guideDocument;
    self.guideTextView.text = guideDocument.text;
    _guideDocument.delegate = self;
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

    if (self.guideDocument) {
        self.guideTextView.text = self.guideDocument.text;
    }
    
    self.guideTextView.delegate = self;
    
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self saveAndCloseDocument ];
    self.guideDocument = nil;
}

#pragma mark - Split view



#pragma mark SplitViewController Delegate

- (BOOL) splitViewController:(UISplitViewController *)svc
    shouldHideViewController:(UIViewController *)vc
               inOrientation:(UIInterfaceOrientation)orientation
{
   // return UIInterfaceOrientationIsPortrait(orientation);
      return NO;
}

- (void) splitViewController:(UISplitViewController *)sender
      willHideViewController:(UIViewController *)master
           withBarButtonItem:(UIBarButtonItem *)barButtonItem
        forPopoverController:(UIPopoverController *)popover
{
    
    barButtonItem.title = master.title;
    self.navigationItem.leftBarButtonItem = barButtonItem;
    
}

- (void) splitViewController:(UISplitViewController *)svc
      willShowViewController:(UIViewController *)aViewController
   invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    self.navigationItem.leftBarButtonItem = nil;
}


-(void)saveAndCloseDocument
{
    [self.guideTextView resignFirstResponder];
    
    // save document
    [self.guideDocument saveToURL: self.guideDocument.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
            // close document
            dispatch_async(dispatch_get_main_queue(), ^{
            [self.guideDocument closeWithCompletionHandler:^(BOOL success) {
                if (!success) {
                    NSLog(@"Failed to close %@", self.guideDocument.fileURL);
                }
             //   [self.delegate detailViewControllerDidClose:self];
            }];
            })
        ;
    }];
    
}

#pragma mark UITextViewDelegate Methods

-(void)textViewDidEndEditing:(UITextView *)textView
{
    self.guideDocument.text = self.guideTextView.text;
}

-(void)textViewDidBeginEditing:(UITextView *)textView
{
    NSLog(@"DID BEGIN EDITING");
}

#pragma mark GuideDocumentDelegate Methods

-(void) guideDocumentContentsUpdated:(GuideDocument *)guideDocument
{
    self.guideTextView.text = self.guideDocument.text;
}

@end
