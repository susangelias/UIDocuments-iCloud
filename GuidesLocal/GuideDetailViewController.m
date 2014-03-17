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




@interface GuideDetailViewController () <UITextViewDelegate>

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
    self.guideTextView.text = self.guideDocument.text;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.guideTextView.delegate = self;
    
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


- (void)checkFileName
{
    // check if document name needs to change
    // document name is the first line of text truncated to 20 characters
    NSArray *lines = [self.guideTextView.text  componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSMutableString *firstLine = [[lines objectAtIndex:0]mutableCopy];   // get the first line
    if ( [firstLine length] > 20 ) {
        firstLine = [[firstLine substringToIndex:20]mutableCopy];
        // remove any trailing white space
        firstLine = [[firstLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]mutableCopy];
    }

    if (![firstLine isEqualToString:self.guideDocument.localizedName]) {
        // let delegate change the file name
        [self.delegate renameFileAtURL:self.guideDocument.fileURL withName:firstLine];
      }
}

-(void)saveAndCloseDocument
{
    [self.guideTextView resignFirstResponder];
    
    // save document
    GuideDetailViewController *weakSelf = self;
    [self.guideDocument saveToURL: self.guideDocument.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
        // close document
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.guideDocument closeWithCompletionHandler:^(BOOL success) {
               if (success) {
                    BOOL emptyText = false;
                   NSString *documentText = [weakSelf.guideTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    if ([documentText length] <= 0) {
                        emptyText = true;
                    }
                    if (emptyText == false) {
                        // check if document name needs to change
                        [weakSelf checkFileName];
                    }
                    else {  // emptyText == true

                        // let master tableview know the file needs to be deleted
                        [weakSelf.delegate deleteFileAtURL:weakSelf.guideDocument.fileURL];
                    }
                    weakSelf.guideDocument = nil;
                }
            }];
        });
    }];
    
}

#pragma mark UITextViewDelegate Methods


-(void)textViewDidEndEditing:(UITextView *)textView
{

    if (self.guideDocument) {
        // update the model
        self.guideDocument.text = self.guideTextView.text;
        [self saveAndCloseDocument];
    }
}

-(void)textViewDidBeginEditing:(UITextView *)textView
{
    if (self.guideDocument) {
        self.guideTextView.text = self.guideDocument.text;
    }
}

#pragma mark GuideDocumentDelegate Methods

-(void) guideDocumentContentsUpdated:(GuideDocument *)guideDocument
{
  //  NSLog(@"CONTENTS UPDATED");
   self.guideTextView.text =  self.guideDocument.text;
}



@end
