//
//  GuidesLocalTests.m
//  GuidesLocalTests
//
//  Created by Susan Elias on 3/7/14.
//  Copyright (c) 2014 GriffTech. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "GuideDocument.h"
#import "FileExtension.h"

@interface parsedGuideDocumentTest : XCTestCase

@property (nonatomic, strong) NSString *documentsDirectoryPath;
@property (nonatomic, strong) NSString *documentName;
@property (nonatomic, strong) NSURL *documentURL;
@property (nonatomic, strong) GuideDocument *testDocument;
@property (nonatomic, strong) NSFileManager *fileManager;

@end

#define kUnitTestFileName   @"TestGuide.spkn"
#define kDocumentTestText   @"Something there is that doesn't love a wall"

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
    
    self.documentName = [self.documentsDirectoryPath stringByAppendingPathComponent:kUnitTestFileName];
    self.documentURL = [NSURL fileURLWithPath:self.documentName];
    
    self.fileManager = [NSFileManager defaultManager];
    [self.fileManager removeItemAtURL:self.documentURL error:NULL];
    
    _blockCalled = NO;
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


// CREATING AND SAVING FILE
-(void)testSavingCreatesFile
{
    GuideDocument *documentUnderTest = [[GuideDocument alloc]initWithFileURL:self.documentURL];
    
    __block BOOL blockSuccess;
    [documentUnderTest saveToURL:self.documentURL
                forSaveOperation:UIDocumentSaveForCreating
               completionHandler:^(BOOL success) {
                   blockSuccess = success;
                   [self blockCalled];
               }];
    
    XCTAssertTrue([self blockCalledWithin:10], @"");
    
    // Save operation should succeed
    XCTAssertTrue( blockSuccess, @"");
    XCTAssertTrue([self.fileManager fileExistsAtPath:self.documentName], @"" );
}

// READING FILE DATA
- (void) testLoadingRetrievesData
{
    // create the document with text
    GuideDocument *document = [[GuideDocument alloc]initWithFileURL:self.documentURL];
    document.text = kDocumentTestText;
    
    __block BOOL blockSuccess = NO;
    
    // Save the document
    [document saveToURL:self.documentURL
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
    GuideDocument *loadedDocument = [[GuideDocument alloc]initWithFileURL:self.documentURL];
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
- (void) testLoadingWhenThereIsNoFile
{
    // given that the file does not exist
    // when we load a new document from that file
    __block BOOL blockSuccess;
    
    GuideDocument *document = [[GuideDocument alloc]initWithFileURL:self.documentURL];
    [document openWithCompletionHandler:^(BOOL success) {
        blockSuccess = success;
        [self blockCalled];
    }];
    
    // then the completion block should be called but without success
    XCTAssertTrue([self blockCalledWithin:10], @"");
    XCTAssertFalse(blockSuccess, @"");
    
}

// LOAD FILE IS EMPTY
- (void)testLoadingEmptyFile
{
    // file is present but empty
    // create the document with text
    GuideDocument *document = [[GuideDocument alloc]initWithFileURL:self.documentURL];
    document.text = @"";
    NSLog(@"fileURL %@", self.documentURL);
    
    __block BOOL blockSuccess;
    
    // Save the document
    [document saveToURL:self.documentURL
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
    GuideDocument *loadedDocument = [[GuideDocument alloc]initWithFileURL:self.documentURL];
    [loadedDocument openWithCompletionHandler:^(BOOL success) {
        blockSuccess = success;
        [self blockCalled];
    }];
    
    // then the completion block should be called but with a failure indication
    XCTAssertTrue([self blockCalledWithin:10], @"");
    XCTAssertFalse(blockSuccess, @"");
    
}
@end
