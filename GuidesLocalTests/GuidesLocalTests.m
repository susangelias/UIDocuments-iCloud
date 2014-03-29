//
//  GuidesLocalTests.m
//  GuidesLocalTests
//
//  Created by Susan Elias on 3/7/14.
//  Copyright (c) 2014 GriffTech. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "GuideDocument.h"
#import "DocumentsListTVC.h"
#import "DocumentViewController.h"
#import "FileExtension.h"

@interface parsedGuideDocumentTest : XCTestCase

@property (nonatomic, strong) NSString *documentsDirectoryPath;
@property (nonatomic, strong) NSString *documentName;
@property (nonatomic, strong) NSString *documentNameWithExtn;
@property (nonatomic, strong) NSURL *documentFileURL;
@property (nonatomic, strong) GuideDocument *testDocument;
@property (nonatomic, strong) NSFileManager *fileManager;
@property (nonatomic, strong) UIApplication *myApp;
@property (nonatomic, strong) UINavigationController *masterNavC;
@property (nonatomic, strong) UISplitViewController *masterSplitVC;

@end

//#define kUnitTestFileName   @"TestGuide.spkn"
//#define kDocumentTestText   @"Something there is that doesn't love a wall"
#define kDocumentTestText   @"Something there"

#define POLL_INTERVAL 0.05 //50ms
#define N_SEC_TO_POLL 1.0 //poll for 1s
#define MAX_POLL_COUNT N_SEC_TO_POLL / POLL_INTERVAL

@implementation parsedGuideDocumentTest
{
    BOOL _blockCalled;
}

- (void)setUp
{
    [super setUp];
    // get this app's documents directory path
    self.documentsDirectoryPath = [NSSearchPathForDirectoriesInDomains( NSDocumentDirectory,
                                                                       NSUserDomainMask, YES ) objectAtIndex:0];
    
    self.documentName = [self.documentsDirectoryPath stringByAppendingPathComponent:kGenericFileName];
    self.documentNameWithExtn = [self.documentName stringByAppendingPathExtension:FileExtension];
    self.documentFileURL = [NSURL fileURLWithPath:self.documentNameWithExtn];
    
    self.fileManager = [NSFileManager defaultManager];
    [self.fileManager removeItemAtURL:self.documentFileURL error:NULL];
    self.myApp = [UIApplication sharedApplication];

    if ([[self.myApp.keyWindow rootViewController] isKindOfClass:[UISplitViewController class]]) {
        self.masterSplitVC = (UISplitViewController *)[self.myApp.keyWindow rootViewController];
        self.masterNavC = (UINavigationController *)[self.masterSplitVC.viewControllers objectAtIndex:0];
    }
    else {
        self.masterNavC = (UINavigationController *)[self.myApp.keyWindow rootViewController];
    }
    _blockCalled = NO;
}

- (void)tearDown
{
    [super tearDown];
  //  [self.fileManager removeItemAtURL:self.documentFileURL error:NULL];
  //  self.documentFileURL = [NSURL fileURLWithPath:self.documentNameWithExtn];
  //  [self.fileManager removeItemAtURL:self.documentFileURL error:NULL];
}

- (void)blockCalled
{
    _blockCalled = YES;
}

// create a run loop here to handle asynchronous delay of file handling methods
- (BOOL) blockCalledWithin:(NSTimeInterval)timeout
{
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:timeout];
    while (!_blockCalled && [loopUntil timeIntervalSinceNow] > 0)
    {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }
    
    BOOL retval = _blockCalled;
    _blockCalled = NO;     // so ready for next time
    return retval;
}


- (void)testinsertNewObject
{
    
  //  if ([[self.myApp.keyWindow rootViewController] isKindOfClass:[UISplitViewController class]]) {
  //      UINavigationController  * rightNavController = [self.masterSplitVC.viewControllers objectAtIndex:1];
  //  }
    DocumentsListTVC *masterTVC = (DocumentsListTVC *)[self.masterNavC topViewController];
    __block BOOL done = NO;
    
    // get initial number of files
    NSUInteger initialNumberOfFiles = [masterTVC.fileList count];
    // call the button press to be tested - this is asynchronous
    [masterTVC insertNewObject:nil];
  
    float delayInSeconds = 0.5;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
        // check if the file was created and in the correct state
        XCTAssertEqual(initialNumberOfFiles+1, [masterTVC.fileList count], @"");
//        XCTAssertTrue([self.fileManager fileExistsAtPath:self.documentNameWithExtn], @"" );
        NSString *newFilePath = [masterTVC.selectedDocument.fileURL path];
        XCTAssertTrue([self.fileManager fileExistsAtPath:newFilePath], @"" );
        done = YES;
    });
 
    NSUInteger pollCount = 0;
    
    while (done == NO && pollCount < MAX_POLL_COUNT) {
        NSLog(@"polling... %i", pollCount);
        NSDate* untilDate = [NSDate dateWithTimeIntervalSinceNow:POLL_INTERVAL];
        [[NSRunLoop currentRunLoop] runUntilDate:untilDate];
        pollCount++;
    }
    if (pollCount == MAX_POLL_COUNT) {
        XCTFail(@"polling timed out");
    }
    
}

-(void) testRenameFile
{
    DocumentViewController *documentVC;

    // Get a pointer to the documentVC if running on the iPhone
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        UINavigationController *navController = (UINavigationController *)[self.myApp.keyWindow rootViewController];
        documentVC = (DocumentViewController *)[navController topViewController];
    }
    else {
        // running on iPad
        UINavigationController  * rightNavController = [self.masterSplitVC.viewControllers objectAtIndex:1];
        documentVC = (DocumentViewController *)[rightNavController topViewController];
    }
    
 //   DocumentsListTVC *masterTVC = (DocumentsListTVC *)[self.masterNavC topViewController];
     __block BOOL done = NO;
    
    // Open editing mode
    [documentVC.guideTextView becomeFirstResponder];
    // Insert a line of text into the new file
    documentVC.guideTextView.text = kDocumentTestText;
    // Signal end of text editing
    [documentVC.guideTextView resignFirstResponder];    // this will kick off the asynchronous saving of the document, closing the file and renaming it
    
    float delayInSeconds = .5;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
        // check if old file is gone
        XCTAssertFalse([self.fileManager fileExistsAtPath:self.documentNameWithExtn], @"");
        
        // check if the file is renamed
        self.documentNameWithExtn = [self.documentNameWithExtn stringByDeletingLastPathComponent];
        self.documentNameWithExtn = [self.documentNameWithExtn stringByAppendingPathComponent:kDocumentTestText];
        self.documentNameWithExtn = [self.documentNameWithExtn stringByAppendingPathExtension:FileExtension];
        XCTAssertTrue([self.fileManager fileExistsAtPath:self.documentNameWithExtn], @"" );
        
        // check if the new file is closed
        XCTAssertTrue(documentVC.guideDocument.documentState & UIDocumentStateClosed, @"");
        
        // check if text was saved in the new file
        XCTAssertEqualObjects(documentVC.guideDocument.text, kDocumentTestText, @"");
        
        // Remove created file
        if ([self.fileManager fileExistsAtPath:self.documentNameWithExtn]) {
            [self.fileManager removeItemAtPath:self.documentNameWithExtn error:NULL];
        }
    
        done = YES;
    });
    
    NSUInteger pollCount = 0;
    
    while (done == NO && pollCount < MAX_POLL_COUNT) {
        NSLog(@"polling... %i", pollCount);
        NSDate* untilDate = [NSDate dateWithTimeIntervalSinceNow:POLL_INTERVAL];
        [[NSRunLoop currentRunLoop] runUntilDate:untilDate];
        pollCount++;
    }
    if (pollCount == MAX_POLL_COUNT) {
        XCTFail(@"polling timed out");
    }
  

}



// READING FILE DATA
- (void) LoadingRetrievesData
{
    // create the document with text
    GuideDocument *document = [[GuideDocument alloc]initWithFileURL:self.documentFileURL];
    document.text = kDocumentTestText;
    
    __block BOOL blockSuccess = NO;
    
    // Save the document
    [document saveToURL:self.documentFileURL
       forSaveOperation:UIDocumentSaveForCreating
      completionHandler:^(BOOL success) {
          blockSuccess = success;
          [self blockCalled];
      }];
    
    XCTAssertTrue([self blockCalledWithin:10], @"");
    XCTAssertTrue(blockSuccess, @"");
    
    // close the document
    [document closeWithCompletionHandler:^(BOOL success) {
        blockSuccess = success;
        [self blockCalled];
    }];
    
    XCTAssertTrue([self blockCalledWithin:10], @"");
    XCTAssertTrue(blockSuccess, @"");

    // Load the document back in
    GuideDocument *loadedDocument = [[GuideDocument alloc]initWithFileURL:self.documentFileURL];
    [loadedDocument openWithCompletionHandler:^(BOOL success) {
        blockSuccess = success;
        [self blockCalled];
    }];
    
    // The data should load successfully
    XCTAssertTrue([self blockCalledWithin:10], @"");
    XCTAssertTrue(blockSuccess, @"");
    
    // and text read in should match what was written out
    XCTAssertEqualObjects(document.text, loadedDocument.text, @"");
}

// NO SUCH FILE TEST
- (void) LoadingWhenThereIsNoFile
{
    // given that the file does not exist
    // when we load a new document from that file
    __block BOOL blockSuccess;
    
    GuideDocument *document = [[GuideDocument alloc]initWithFileURL:self.documentFileURL];
    [document openWithCompletionHandler:^(BOOL success) {
        blockSuccess = success;
        [self blockCalled];
    }];
    
    // then the completion block should be called but without success
    XCTAssertTrue([self blockCalledWithin:10], @"");
    XCTAssertFalse(blockSuccess, @"");
    
}

// LOAD FILE IS EMPTY
- (void)LoadingEmptyFile
{
    // file is present but empty
    // create the document with text
    GuideDocument *document = [[GuideDocument alloc]initWithFileURL:self.documentFileURL];
    document.text = @"";
    NSLog(@"fileURL %@", self.documentFileURL);
    
    __block BOOL blockSuccess;
    
    // Save the document
    [document saveToURL:self.documentFileURL
       forSaveOperation:UIDocumentSaveForCreating
      completionHandler:^(BOOL success) {
          blockSuccess = success;
          [self blockCalled];
      }];
    
    XCTAssertTrue([self blockCalledWithin:10], @"");
    XCTAssertTrue(blockSuccess, @"");
    
    // close the document
    [document closeWithCompletionHandler:^(BOOL success) {
        blockSuccess = success;
        [self blockCalled];
    }];
    
    XCTAssertTrue([self blockCalledWithin:10], @"");
    XCTAssertTrue(blockSuccess, @"");
    
    // Load the document back in
    GuideDocument *loadedDocument = [[GuideDocument alloc]initWithFileURL:self.documentFileURL];
    [loadedDocument openWithCompletionHandler:^(BOOL success) {
        blockSuccess = success;
        [self blockCalled];
    }];
    
    // then the completion block should be called but with a failure indication
    XCTAssertTrue([self blockCalledWithin:10], @"");
    XCTAssertFalse(blockSuccess, @"");
    
}

// Load file has bad data
- (void)LoadingBadDataFile
{
    // file is present but has bad data
    // create the document with an image saved in the text file
    GuideDocument *document = [[GuideDocument alloc]initWithFileURL:self.documentFileURL];
    document.text = (NSString *)[UIImage imageNamed:@"stop.png"];
    
    __block BOOL blockSuccess;
    
    // Save the document
    [document saveToURL:self.documentFileURL
       forSaveOperation:UIDocumentSaveForCreating
      completionHandler:^(BOOL success) {
          blockSuccess = success;
          [self blockCalled];
      }];
    
    XCTAssertTrue([self blockCalledWithin:10], @"");
    XCTAssertTrue(blockSuccess, @"");
    
    // close the document
    [document closeWithCompletionHandler:^(BOOL success) {
        blockSuccess = success;
        [self blockCalled];
    }];
    
    XCTAssertTrue([self blockCalledWithin:10], @"");
    XCTAssertTrue(blockSuccess, @"");
    
    // Load the document back in
    GuideDocument *loadedDocument = [[GuideDocument alloc]initWithFileURL:self.documentFileURL];
    [loadedDocument openWithCompletionHandler:^(BOOL success) {
        blockSuccess = success;
        [self blockCalled];
    }];
    
    // then the completion block should be called but with a failure indication
    XCTAssertTrue([self blockCalledWithin:10], @"");
    XCTAssertFalse(blockSuccess, @"");
   
}

// Load file has bad data
- (void)ExceptionDuringUnarchiveShouldFailGracefully {
    // file is present but has  data that will throw an exception during Unarchiving
    // create the document with an array of images
     UIImage *explodingObject = [[UIImage alloc]init];
     explodingObject = [UIImage imageNamed:@"stop.png"];
     NSArray *array = [NSArray arrayWithObjects:explodingObject, nil];
     NSMutableData *data = [[NSMutableData alloc]init];
     NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc]initForWritingWithMutableData:data];
    [archiver encodeObject:array forKey:@"array"];
    [archiver finishEncoding];
    
    GuideDocument *document = [[GuideDocument alloc]initWithFileURL:self.documentFileURL];
    [data writeToFile:self.documentName atomically:YES];
    
    __block BOOL blockSuccess;
    
    // Save the document
    [document saveToURL:self.documentFileURL
       forSaveOperation:UIDocumentSaveForCreating
      completionHandler:^(BOOL success) {
          blockSuccess = success;
          [self blockCalled];
      }];
    
    XCTAssertTrue([self blockCalledWithin:10], @"");
    XCTAssertTrue(blockSuccess, @"");
    
    // close the document
    [document closeWithCompletionHandler:^(BOOL success) {
        blockSuccess = success;
        [self blockCalled];
    }];
    
    XCTAssertTrue([self blockCalledWithin:10], @"");
    XCTAssertTrue(blockSuccess, @"");
    
    // Load the document back in
    GuideDocument *loadedDocument = [[GuideDocument alloc]initWithFileURL:self.documentFileURL];
    [loadedDocument openWithCompletionHandler:^(BOOL success) {
        blockSuccess = success;
        [self blockCalled];
    }];
    
    // then the completion block should be called but with a failure indication
    XCTAssertTrue([self blockCalledWithin:10], @"");
    XCTAssertFalse(blockSuccess, @"");
    
}



@end
