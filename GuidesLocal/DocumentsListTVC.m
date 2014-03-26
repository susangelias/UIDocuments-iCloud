//
//  GuideMasterViewController.m
//  GuidesLocal
//
//  Created by Susan Elias on 3/4/14.
//  Copyright (c) 2014 GriffTech. All rights reserved.
//

#import "DocumentsListTVC.h"
#import "DocumentViewController.h"
#import "FileExtension.h"

@interface DocumentsListTVC () <DocumentViewControllerDelegate, GuideDocumentDelegate>

@property (nonatomic, strong) NSString *documentsDirectoryPath;
@property  BOOL iCloudOn;

@end



@implementation DocumentsListTVC

- (NSMutableArray *)fileList
{
    if (!_fileList) {
        _fileList = [[NSMutableArray alloc]init];
        [self loadLocal];
    }
    return _fileList;
}

#pragma mark Refresh Methods
// these methods courtesy of http://www.raywenderlich.com/12779/icloud-and-uidocument-beyond-the-basics-part-1

- (void)loadLocal
{
    NSURL *fileDirectory = [[NSURL alloc]initFileURLWithPath:self.documentsDirectoryPath];
    NSArray * localDocuments = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:fileDirectory includingPropertiesForKeys:nil options:0 error:nil];

    [self.fileList removeAllObjects];
    for (int i=0; i < localDocuments.count; i++) {
        
        NSURL * fileURL = [localDocuments objectAtIndex:i];
        if ([[fileURL pathExtension] isEqualToString:FileExtension]) {
         //   NSLog(@"Found local file: %@", fileURL);
            [self.fileList addObject:fileURL];
        }
    }
    
    self.navigationItem.rightBarButtonItem.enabled = YES;
}

- (void)refresh
{
    self.navigationItem.rightBarButtonItem.enabled = NO;
    if (![self iCloudOn]) {
        [self loadLocal];
    }
    [self.tableView reloadData];
}

- (void)getListOfGuideDocuments {

    if ([self.fileList count] > 0) {
        [self.fileList removeAllObjects];
    }
    NSArray *localDocuments = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.documentsDirectoryPath error:nil];
    for (NSString * document in localDocuments) {
        [self.fileList addObject:document];
    }
 }


- (void)awakeFromNib
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.preferredContentSize = CGSizeMake(320.0, 600.0);
    }
    [super awakeFromNib];
    
    // get this app's documents directory path
    self.documentsDirectoryPath = [NSSearchPathForDirectoriesInDomains( NSDocumentDirectory,
                                                                       NSUserDomainMask, YES ) objectAtIndex:0];
    self.iCloudOn = NO;
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    self.detailViewController = (DocumentViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    
    // sign up to catch any changes the user makes to the font settings
    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(preferredContentSizeChanged:)
        name:UIContentSizeCategoryDidChangeNotification
        object:nil ];
    [self refresh];
    
}

-(void)preferredContentSizeChanged:(NSNotification *)notification
{
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];

}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    // make sure view is scrolled to the top
    self.tableView.scrollsToTop = YES;

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSURL *) getDocURL
{
    NSURL *url = nil;
    NSString *guideName = nil;
    
    guideName = kGenericFileName;
    
    NSString *textFileNameWithExtention = [NSString stringWithFormat:@"%@.%@", guideName, FileExtension];
    
    if (self.documentsDirectoryPath) {
        // set up file URL
        url = [NSURL fileURLWithPathComponents:@[self.documentsDirectoryPath, textFileNameWithExtention]];
    }
    else {
        NSLog(@"ERROR:  self.documentsDirectoryPath = nil");
    }
    return url;
}





#pragma mark   Guide  File Management Methods

- (void) deleteGuide:(NSURL *)guideURL
{
    NSFileManager *fileManager = [[NSFileManager alloc]init];
    NSError *error;
    NSString *filePath = [guideURL path];
    BOOL fileExists = [fileManager fileExistsAtPath:filePath];
    if (fileExists) {
        BOOL success = [fileManager removeItemAtURL:guideURL error:&error];
        if (!success) {
            NSLog(@"ERROR DELETING FILE %@", error);
        }
        else {
            NSLog(@"FILE DELETED %@", guideURL);
            self.selectedDocument = nil;
            self.detailViewController.guideDocument = nil;
        }
    }
}


- (NSURL *)renameDirectory: (NSString *)newName
{
    // change the file name by moving the file
    NSURL *renamedFileURL = [[NSURL alloc]init];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    
    NSString *oldPath = [self.selectedDocument.fileURL path];
    newName = [[newName stringByAppendingPathExtension:FileExtension]mutableCopy];
    NSMutableString *newPath = [[oldPath stringByDeletingLastPathComponent] mutableCopy];
    newPath = [[newPath stringByAppendingPathComponent:newName]mutableCopy];
    
    BOOL success = [fileManager moveItemAtPath:oldPath toPath:newPath error:&error];
    if (!success) {
        NSLog(@"Failed to move file %@", error.localizedDescription);
    }
    else {
        renamedFileURL = [NSURL fileURLWithPath:newPath];
    }
    return renamedFileURL;
    
}

- (IBAction)insertNewObject:(UIBarButtonItem *)sender {
    
    __block BOOL blockSuccess = YES;
    GuideDocument *newDocument;
    
    // Create a new instance of the appropriate class,
    NSURL *url = [self getDocURL];
    
    if (!url) {
        NSLog(@"ERROR:  File url = %@", url);
    }
    else {
        // create new file
        newDocument = [[GuideDocument alloc]initWithFileURL:url];
        
        // save new file
        if (newDocument) {
            self.selectedDocument = newDocument;
            [self.selectedDocument saveToURL:url
                       forSaveOperation:UIDocumentSaveForCreating
                      completionHandler:^(BOOL success) {
                          if (success) {
                              blockSuccess = success;
                              // insert it into the array,
                              [self.fileList insertObject:self.selectedDocument.fileURL atIndex:0];
                              // and add a new row to the table view.
                              // updating UI so make sure on main queue
                              dispatch_async(dispatch_get_main_queue(), ^{
                                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
                                [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                                if (!self.detailViewController) {
                                  [self performSegueWithIdentifier:@"showGuide" sender:self];
                                }
                                else {
                                    [self setupDestinationVC:self.detailViewController];
                                }
                        });
                    }
                          
                }];
        }
    }
  }

-(void)saveAndCloseDocument
{
    // save document
    GuideDocument *documentToClose;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        documentToClose = self.detailViewController.guideDocument;
    }
    else {
        documentToClose = self.selectedDocument;
    }

    // Check that document is not already closed
    if (documentToClose.documentState & UIDocumentStateClosed) {
        return;
    }
    else {
        DocumentsListTVC *weakSelf = self;
        // save the document
        [documentToClose saveToURL:documentToClose.fileURL
                  forSaveOperation:UIDocumentSaveForOverwriting
                 completionHandler:^(BOOL success) {
                     if (success) {
                         // close document
                         [documentToClose closeWithCompletionHandler:^(BOOL success) {
                             if (success) {
                                 // see if file name has changed
                                 if ( (![documentToClose.guideTitle isEqualToString:documentToClose.localizedName]) && (documentToClose.guideTitle) )
                                 {
                                     // get index into file list for this item
                                     NSInteger tableItemToRenameIndex = NSNotFound;
                                     tableItemToRenameIndex = [weakSelf.fileList indexOfObject:documentToClose.fileURL];
                                     // delete cell from file list
                                     if (tableItemToRenameIndex != NSNotFound) {
                                         [weakSelf.fileList removeObjectAtIndex:tableItemToRenameIndex];
                                         // get cell in table view for this item
                                         NSIndexPath *indexPath = [NSIndexPath indexPathForRow:tableItemToRenameIndex inSection:0];
                                         // delete item from table view
                                         [weakSelf.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:YES];
                                     }
                                     // rename the file
                                     NSURL *renamedFileURL = [weakSelf renameDirectory:documentToClose.guideTitle];
                                     
                                     if (renamedFileURL) {
                                         // add new url into file list at the end
                                         [weakSelf.fileList addObject:renamedFileURL];
                                         // resort file list alphabetically
                                         [weakSelf.fileList sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                                             NSString *f1 = [(NSURL *)obj1 absoluteString];
                                             NSString *f2 = [(NSURL *)obj2 absoluteString];
                                             return [f1 localizedStandardCompare:f2];
                                         }];
                                         // tell our table view to refresh
                                         [weakSelf.tableView reloadData];
                                    
                                         // instantiate renamed document
                                        GuideDocument *renamedDocument = [[GuideDocument alloc]initWithFileURL:renamedFileURL];
                                        weakSelf.selectedDocument = renamedDocument;
                                    }
                                 }
     
                             }
                         }];
                         
                     }
                     else {
                         NSLog(@"ERROR SAVING DOCUMENT %@", documentToClose.fileURL);
                     }
                 }];
    }

}

#pragma mark - Table View Data Source

// adjust the size of the table's rows depending on the user's font size setting from the
// system's Settings:General menu
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static UILabel *label;
    if (!label) {
        label = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, FLT_MAX, FLT_MAX)];
        label.text = @"test";
    }
    // set font to user's size
    label.font  = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    // size the frame to fit the font
    [label sizeToFit];
    // add a little white space around the text
    return label.frame.size.height * 1.7;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.fileList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

    NSString *fileName = [[self.fileList objectAtIndex:indexPath.row] lastPathComponent];
    cell.textLabel.text = [fileName stringByDeletingPathExtension];
    
    // set font to use the user's font settings
    cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // on the iPad, unlink this document from the detail view controller
        if ([self.detailViewController isKindOfClass:[DocumentViewController class]]) {
            DocumentViewController *guideDVC = self.detailViewController;
            guideDVC.guideDocument = nil;
            guideDVC.title = @"";
        }
        // delete the document file
        if ( self.documentsDirectoryPath && ([self.fileList count] > 0) ) {
            // copy name to delete
            NSURL *fileURLToDelete = [self.fileList objectAtIndex:indexPath.row];
            [self deleteGuide:fileURLToDelete];
            // remove url from file list
            [self.fileList removeObjectAtIndex:indexPath.row];
            // call tableView to remove row
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
         }
        else {
            NSLog(@"ERROR: file deletion documentsDirectoryPath = %@, self.fileList = %@", self.documentsDirectoryPath, self.fileList);
        }

    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        NSLog(@"INSERTION");
    }
}

#pragma mark    Navigation

- (void) prepareGuideDocumentVCWithURL: (NSURL *)url
{
    GuideDocument *guideDocument;
    if (url) {
        // release our current document
        guideDocument = [[GuideDocument alloc]initWithFileURL:url];
   //     NSLog(@"prepareGuideDocumentVCWithURL DOCSTATE = %d", guideDocument.documentState);
        guideDocument.delegate   = self;
    }
    if (guideDocument) {
        self.selectedDocument = guideDocument;
        if (self.selectedDocument.documentState & UIDocumentStateClosed) {
            [self.selectedDocument openWithCompletionHandler:^(BOOL success) {
                if (success) {
                    if ( (self.detailViewController) && ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) ) {
                        [self setupDestinationVC:self.detailViewController];
                    }
                    else {
                        [self performSegueWithIdentifier:@"showGuide" sender:self];
                    }
                }
                else {
      //              NSLog(@"document open error %@, %d", self.selectedDocument.fileURL, self.selectedDocument.documentState);
                }

            }];
        }
    }

}

- (void) setupDestinationVC:(DocumentViewController *)destinationVC
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [destinationVC.guideTextView resignFirstResponder];     // SAVE ANY CHANGES TO THE CURRENT EDITING SESSION BEFORE OVERWRITING TEXT
    }
    destinationVC.guideDocument = self.selectedDocument;
    destinationVC.title = [[self.selectedDocument.fileURL lastPathComponent] stringByDeletingPathExtension];
    destinationVC.delegate = self;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        destinationVC.guideTextView.text = self.selectedDocument.text;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSURL *url = self.fileList[indexPath.row];
    [self prepareGuideDocumentVCWithURL:url];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showGuide"]) {
        // open the selected document and pass it to the destination document view controller
        DocumentViewController *destinationVC;
        if ([[segue destinationViewController] isKindOfClass:[DocumentViewController class]])
        {
            destinationVC = (DocumentViewController *)[segue destinationViewController];
        }
        [self setupDestinationVC:destinationVC];
    }
}


#pragma mark DocumentViewControllerDelegate

- (void)documentContentChanged
{
    [self saveAndCloseDocument];
}

- (void)documentContentEmpty:(NSURL *)fileURL
{
    NSInteger tableItemToDeleteIndex = NSNotFound;
    // remove url from file list
    if ([self.fileList count] > 0) {
        tableItemToDeleteIndex = [self.fileList indexOfObject:fileURL];
        if (tableItemToDeleteIndex != NSNotFound) {
            [self.fileList removeObjectAtIndex:tableItemToDeleteIndex];   // call tableView to remove row
        }
    }
    
    if (tableItemToDeleteIndex != NSNotFound) {
        // remove document name from table view
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:tableItemToDeleteIndex inSection:0];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
    
    // delete document
    [self deleteGuide:fileURL];
    
}




#pragma mark GuideDocumentDelegate Methods

-(void) guideDocumentContentsUpdated:(GuideDocument *)guideDocument
{
    //  NSLog(@"CONTENTS UPDATED");
    self.selectedDocument.text =  guideDocument.text;
}


@end
