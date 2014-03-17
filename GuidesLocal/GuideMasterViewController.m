//
//  GuideMasterViewController.m
//  GuidesLocal
//
//  Created by Susan Elias on 3/4/14.
//  Copyright (c) 2014 GriffTech. All rights reserved.
//

#import "GuideMasterViewController.h"
#import "GuideDetailViewController.h"
#import "FileExtension.h"

@interface GuideMasterViewController () <GuideDetailViewControllerDelegate>

@property (nonatomic, strong) NSString *documentsDirectoryPath;
@property (strong, nonatomic) NSMutableArray *fileList;
@property (nonatomic, strong) GuideDocument *selectedDocument;
@property  BOOL iCloudOn;

@end

@implementation GuideMasterViewController

- (NSMutableArray *)fileList
{
    if (!_fileList) {
        _fileList = [[NSMutableArray alloc]init];
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

    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
    self.navigationItem.rightBarButtonItem = addButton;
    self.detailViewController = (GuideDetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    
    [self refresh];
    
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
    
    guideName = [NSString stringWithFormat:@"Guide %@", [NSDate date]];
    
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
        }
    }
}


- (void)renameDirectory: (NSString *)newName
{
    // change the file name by moving the file
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
        NSLog(@"file move ok %@", newPath);
        NSURL *newURL = [NSURL fileURLWithPath:newPath isDirectory:YES];
        GuideDocument *newGuide = [[GuideDocument alloc]initWithFileURL:newURL];
        self.selectedDocument = newGuide;
    }
    
}


- (void)insertNewObject:(id)sender
{
    // Create a new instance of the appropriate class,
    NSURL *url = [self getDocURL];
    
    if (!url) {
        NSLog(@"ERROR:  File url = %@", url);
    }
    else {
        // create new file
        self.selectedDocument = [[GuideDocument alloc]initWithFileURL:url];
        
        // save new file
        if (self.selectedDocument) {
            [self.selectedDocument saveToURL:url
                       forSaveOperation:UIDocumentSaveForCreating
                      completionHandler:^(BOOL success) {
                          if (success) {
                              //  NSLog(@"created document %@", newGuide.localizedName);
                              // insert it into the array,
                              [self.fileList insertObject:self.selectedDocument.fileURL atIndex:0];
                              
                              // and add a new row to the table view.
                              // updating UI so make sure on main queue
                              dispatch_async(dispatch_get_main_queue(), ^{
                                  NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
                                  [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                                  id detail = self.splitViewController.viewControllers[1];
                                  if (!detail) {
                                     [self performSegueWithIdentifier:@"showGuide" sender:self];
                                  }
                                  else if ([detail isKindOfClass:[UINavigationController class]]) {
                                          // move past the UINavigation Controller
                                          detail = [((UINavigationController *)detail).viewControllers firstObject];

                                          if ([detail isKindOfClass:[GuideDetailViewController class]]) {
                                              // update the detail view
                                              [self prepareGuideDocumentVC:detail withURL:nil];
                                          }
                                    }
                              });
                          }
                          
                      }];
        }
    }
    
}


#pragma mark - Table View Data Source

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
        if ([self.detailViewController isKindOfClass:[GuideDetailViewController class]]) {
            GuideDetailViewController *guideDVC = self.detailViewController;
            guideDVC.guideDocument = nil;
            guideDVC.title = @"";
        }
        self.selectedDocument = nil;
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


- (void) prepareGuideDocumentVC:(GuideDetailViewController *)destinationVC
                        withURL: (NSURL *)url
{
    if (url) {
        self.selectedDocument = [[GuideDocument alloc]initWithFileURL:url];
    }
    if (self.selectedDocument) {
        if (self.selectedDocument.documentState & UIDocumentStateClosed) {
            [self.selectedDocument openWithCompletionHandler:^(BOOL success) {
                destinationVC.guideDocument = self.selectedDocument;
                destinationVC.title = [[self.selectedDocument.fileURL lastPathComponent] stringByDeletingPathExtension];
                destinationVC.delegate = self;
                // release hold on selected Document now that it's been passed to the document view controller
               // self.selectedDocument = nil;
               }];
        }
    }

}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // get the Detail view controller in our UISplitViewController (nil if not in one)
    id detail = self.splitViewController.viewControllers[1];
    if (detail) {
        // if Detail is a UINavigationController, look at its root view controller to find it
        if ([detail isKindOfClass:[UINavigationController class]]) {
            detail = [((UINavigationController *)detail).viewControllers firstObject];
        }
        // is the Detail is an GuideDetailViewController?
        if ([detail isKindOfClass:[GuideDetailViewController class]]) {
            // yes ... we know how to update that!
            GuideDetailViewController *destinationVC = (GuideDetailViewController *)detail;
            // on the iPad, need to terminate the previous editing session when the user taps on the left view controller's table cells
            [destinationVC.guideTextView resignFirstResponder];
            NSURL *url = self.fileList[indexPath.row];
            [self prepareGuideDocumentVC:destinationVC withURL:url];

        }
    }
}



#pragma mark    Navigation


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showGuide"]) {
        // open the selected document and pass it to the destination document view controller
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSURL *url = self.fileList[indexPath.row];
        [self prepareGuideDocumentVC:[segue destinationViewController] withURL:url ];
    }
}


#pragma mark GuideDetailViewControllerDelegate

- (void)deleteFileAtURL:(NSURL *)fileURL
{
    [self deleteGuide:fileURL];
    [self refresh];

}

- (void)renameFileAtURL:(NSURL *)fileURL withName:(NSString *)newName
{
    [self renameDirectory:newName];
    [self refresh];
}

@end
