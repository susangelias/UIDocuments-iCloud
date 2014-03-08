//
//  guideDocument.h
//  SpeakSteps
//
//  Created by Susan Elias on 3/4/14.
//  Copyright (c) 2014 GriffTech. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol GuideDocumentDelegate <NSObject>

-(void)guideDocumentContentsUpdated:(UIDocument *)guideDocument;

@end

@interface GuideDocument : UIDocument 

@property (nonatomic, strong) NSString *text;
@property (nonatomic, weak) id <GuideDocumentDelegate> delegate;

@end

