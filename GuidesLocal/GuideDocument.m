//
//  guideDocument.m
//  SpeakSteps
//
//  Created by Susan Elias on 3/4/14.
//  Copyright (c) 2014 GriffTech. All rights reserved.
//

#import "GuideDocument.h"
#import "FileExtension.h"


@interface GuideDocument()

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSFileWrapper *fileWrapper;
@property (nonatomic, strong) NSString *textFileName;
@property (nonatomic, strong) NSString *imageFileName;

@end



@implementation GuideDocument

#pragma mark Lazy Instantiations

- (NSString *)textFileName {
    if (!_textFileName) {
        
        _textFileName = @"text";
    }
    return _textFileName;
}
                        
 - (NSString *)imageFileName {
     if (!_imageFileName) {
         _imageFileName = @"image";
     }
     return _imageFileName;
 }



#pragma mark UIDocument method overrides
#pragma mark Loading Document Data

// method courtesy of http://www.raywenderlich.com/12779/icloud-and-uidocument-beyond-the-basics-part-1
- (id)decodeObjectFromWrapperWithPreferredFilename:(NSString *)preferredFilename {
    
    NSFileWrapper * fileWrapper = [self.fileWrapper.fileWrappers objectForKey:preferredFilename];
    if (!fileWrapper) {
        NSLog(@"Unexpected error: Couldn't find %@ in file wrapper!", preferredFilename);
        return nil;
    }
    
    NSData * data = [fileWrapper regularFileContents];
    NSKeyedUnarchiver * unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    
    return [unarchiver decodeObjectForKey:@"data"];
    
}

#pragma mark Lazy Loading
// method courtesy of http://www.raywenderlich.com/12779/icloud-and-uidocument-beyond-the-basics-part-1
- (UIImage *)image  {
    if (_image == nil) {
        if (self.fileWrapper != nil) {
            NSLog(@"Loading _image for %@...", self.fileURL);
            _image = [self decodeObjectFromWrapperWithPreferredFilename:self.imageFileName];
        } else {
            _image = [[UIImage alloc] init];
        }
    }
    return _image;
}

// method courtesy of http://www.raywenderlich.com/12779/icloud-and-uidocument-beyond-the-basics-part-1
- (NSString *)text {
    if (!_text) {
        if (self.fileWrapper != nil) {
            NSLog(@"Loading instruction for %@...", self.fileURL);
            _text = [self decodeObjectFromWrapperWithPreferredFilename:self.textFileName];
        } else {
            _text = [[NSString alloc] init];
        }
    }
    return _text;
}

- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError {
    
    self.fileWrapper = (NSFileWrapper *) contents;
    
    // The rest will be lazy loaded...
    self.text = nil;
    self.image = nil;
 
    if ([self.delegate respondsToSelector:@selector(guideDocumentContentsUpdated:)]) {
        [self.delegate guideDocumentContentsUpdated:self];
    }
    
    return YES;
    
}


#pragma mark Returning snapshot of document data

// method courtesy of http://www.raywenderlich.com/12779/icloud-and-uidocument-beyond-the-basics-part-1

- (void)encodeObject:(id<NSCoding>)object toWrappers:(NSMutableDictionary *)wrappers preferredFilename:(NSString *)preferredFilename {
    @autoreleasepool {
        NSMutableData * data = [NSMutableData data];
        NSKeyedArchiver * archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
        [archiver encodeObject:object forKey:@"data"];
        [archiver finishEncoding];
        NSFileWrapper * wrapper = [[NSFileWrapper alloc] initRegularFileWithContents:data];
        [wrappers setObject:wrapper forKey:preferredFilename];
    }
}

- (id)contentsForType:(NSString *)typeName error:(NSError *__autoreleasing *)outError {

    if (self.text == nil && self.image == nil) {
        return nil;
    }
    
    NSMutableDictionary * wrappers = [NSMutableDictionary dictionary];
    [self encodeObject:self.text toWrappers:wrappers preferredFilename:self.textFileName];
    [self encodeObject:self.image toWrappers:wrappers preferredFilename:self.imageFileName];
    NSFileWrapper * fileWrapper = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:wrappers];
    
    return fileWrapper;
    
}



@end
