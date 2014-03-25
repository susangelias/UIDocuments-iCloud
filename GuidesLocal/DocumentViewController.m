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


NSString * const editDoneButtonTitleEdit = @"Edit";
NSString * const editDoneButtonTitleDone = @"Done";

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
  
    self.guideTextView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    // sign up to catch any changes the user makes to the font settings
    [[NSNotificationCenter defaultCenter]
            addObserver:self
                selector:@selector(preferredContentSizeChanged:)
                    name:UIContentSizeCategoryDidChangeNotification
                object:nil ];
    self.guideTextView.delegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}


-(void)preferredContentSizeChanged:(NSNotification *)notification
{
    self.guideTextView.font  = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.guideTextView.text = self.guideDocument.text;
    
}


#pragma mark User Action

- (IBAction)EditDoneButtonPressed:(UIBarButtonItem *)sender {
    
    if ([sender.title isEqualToString:editDoneButtonTitleEdit]) {
        // toggle button to done
        sender.title = editDoneButtonTitleDone;
        
        // activate keyboard
        [self.guideTextView becomeFirstResponder];
    }
    else {
        // togggle button to edit
        sender.title = editDoneButtonTitleEdit;
        
        // deactivate keyboard
        [self.guideTextView resignFirstResponder];
    }
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

-(void)textViewDidBeginEditing:(UITextView *)textView
{
    // toggle the edit/done button in the navigation bar to match state
    UIBarButtonItem *editButton = [self.navigationItem rightBarButtonItem];
    editButton.title = editDoneButtonTitleDone;
}

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
    // toggle the edit/done button in the navigation bar to match state
    UIBarButtonItem *editButton = [self.navigationItem rightBarButtonItem];
    editButton.title = editDoneButtonTitleEdit;
    
}

-(void) keyboardWillShow:(NSNotification *)note
{
    // Get the keyboard size
    CGRect keyboardBounds;
    [[note.userInfo valueForKey:UIKeyboardFrameBeginUserInfoKey] getValue: &keyboardBounds];
    
    // Detect orientation
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    CGRect frame = self.guideTextView.frame;
    
    // Start animation
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3f];
    
    // Reduce size of the Table view
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
        frame.size.height -= keyboardBounds.size.height;
    else
        frame.size.height -= keyboardBounds.size.width;
    
    // Apply new size of table view
    self.guideTextView.frame = frame;
    
    // Scroll the table view to see the TextField just above the keyboard
    if (self.guideTextView)
    {
        CGRect textFieldRect = [self.guideTextView convertRect:self.guideTextView.superview.bounds fromView:self.guideTextView.superview];
        [self.guideTextView scrollRectToVisible:textFieldRect animated:NO];
    }
    
    [UIView commitAnimations];
}

-(void) keyboardWillHide:(NSNotification *)note
{
    // Get the keyboard size
    CGRect keyboardBounds;
    [[note.userInfo valueForKey:UIKeyboardFrameBeginUserInfoKey] getValue: &keyboardBounds];
    
    // Detect orientation
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    CGRect frame = self.guideTextView.frame;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3f];
    
    // Reduce size of the Table view
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
        frame.size.height += keyboardBounds.size.height;
    else
        frame.size.height += keyboardBounds.size.width;
    
    // Apply new size of table view
    self.guideTextView.frame = frame;
    
    [UIView commitAnimations];
}



@end
