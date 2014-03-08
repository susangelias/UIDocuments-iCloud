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

@interface GuideMasterViewController ()

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

- (void)loadLocal {
    
    NSURL *fileDirectory = [[NSURL alloc]initFileURLWithPath:self.documentsDirectoryPath];
    NSArray * localDocuments = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:fileDirectory includingPropertiesForKeys:nil options:0 error:nil];
  //  NSLog(@"Found %d local files.", localDocuments.count);
    for (int i=0; i < localDocuments.count; i++) {
        
        NSURL * fileURL = [localDocuments objectAtIndex:i];
        if ([[fileURL pathExtension] isEqualToString:FileExtension]) {
         //   NSLog(@"Found local file: %@", fileURL);
            [self.fileList addObject:fileURL];
        }
    }
    
    self.navigationItem.rightBarButtonItem.enabled = YES;
}

- (void)refresh {
    
    [self.fileList removeAllObjects];
    [self.tableView reloadData];
    
    self.navigationItem.rightBarButtonItem.enabled = NO;
    if (![self iCloudOn]) {
        [self loadLocal];
    }
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
        // delete the document file
        if ( self.documentsDirectoryPath && ([self.fileList count] > 0) ) {
            // copy name to delete
            NSURL *fileURLToDelete = [self.fileList objectAtIndex:indexPath.row];
            // remove url from file list
            [self.fileList removeObjectAtIndex:indexPath.row];
            // call tableView to remove row
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            // set up file URL
             if (fileURLToDelete) {
                __block BOOL removeSuccess = NO;
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
                    [fileCoordinator coordinateWritingItemAtURL:fileURLToDelete options:NSFileCoordinatorWritingForDeleting
                                                          error:nil byAccessor:^(NSURL* writingURL) {
                                                              NSFileManager* fileManager = [[NSFileManager alloc] init];
                                                              NSError *error;
                                                              //removeSuccess = [fileManager removeItemAtURL:writingURL error:&error];
                                                              removeSuccess = [fileManager removeItemAtPath:[writingURL path] error:&error];
                                                          }];
                });
            }
            else {
                NSLog(@"ERROR:  file deletion fileURLToDelete %@", fileURLToDelete);
            }
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
                
            }];
        }
    }
    destinationVC.guideDocument = self.selectedDocument;
    destinationVC.title = [[self.selectedDocument.fileURL lastPathComponent] stringByDeletingPathExtension];
    // release hold on selected Document now that it's been passed to the document view controller
    self.selectedDocument = nil;

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
            NSURL *url = self.fileList[indexPath.row];
            [self prepareGuideDocumentVC:destinationVC withURL:url];

        }
    }
}

#pragma mark    Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showGuide"]) {
        if (!self.selectedDocument) {
            // open the selected document and pass it to the destination document view controller
            NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
            NSURL *url = self.fileList[indexPath.row];
             [self prepareGuideDocumentVC:[segue destinationViewController] withURL:url ];

            }
    }
}

@end
