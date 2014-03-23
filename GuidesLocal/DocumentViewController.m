//
//  guideDocumentViewController.m
//  GuidesLocal
//
//  Created by Susan Elias on 3/6/14.
//  Copyright (c) 2014 GriffTech. All rights reserved.
//

#import "DocumentViewController.h"
#import "GuideDocument.h"
#import "FileExtension.h"


@interface DocumentViewController () <UITextViewDelegate>

@property (strong, nonatomic) UIPopoverController *masterPopoverController;

@end

#pragma mark View LifeCyle

@implementation DocumentViewController

- (void) awakeFromNib
{
    [super awakeFromNib];
    self.splitViewController.delegate = self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.guideTextView.delegate = self;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.guideTextView.text = self.guideDocument.text;
    
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.guideDocument = nil;
}

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

#pragma mark Helpers


- (BOOL)checkFileName
{
    // check if document name needs to change
    BOOL nameChanged = NO;
    
    // document name is the first line of text truncated to 20 characters
    NSArray *lines = [self.guideTextView.text  componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSMutableString *firstLine = [[lines objectAtIndex:0]mutableCopy];   // get the first line
    if ( [firstLine length] > 20 ) {
        firstLine = [[firstLine substringToIndex:20]mutableCopy];
        // remove any trailing white space
        firstLine = [[firstLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]mutableCopy];
    }
    
    if (![firstLine isEqualToString:self.guideDocument.localizedName]) {
        self.guideDocument.guideTitle = firstLine;
        nameChanged = YES;
    }
    return nameChanged;
}


#pragma mark UITextViewDelegate Methods


-(void)textViewDidEndEditing:(UITextView *)textView
{
    if (self.guideDocument) {        
        // check if there is any text
        NSString *documentText = [self.guideTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([documentText isEqualToString:@""]) {
            // don't save documents without content, let the delegate know
            [self.delegate documentContentEmpty:self.guideDocument.fileURL];
        }
        else {
            // update the model
            self.guideDocument.text = self.guideTextView.text;
            
            // see if the name needs to change
            [self checkFileName];
            
            // let delegate know the document content has changed
            if (!self.guideDocument.documentState & UIDocumentStateNormal) {
         //       NSLog(@"documentState = %d", self.guideDocument.documentState);
            }
            else {
                [self.delegate documentContentChanged];
            }
        }
    }
}




@end
