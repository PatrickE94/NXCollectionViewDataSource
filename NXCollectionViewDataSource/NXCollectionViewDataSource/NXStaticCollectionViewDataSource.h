//
//  NXStaticCollectionViewDataSource.h
//  NXCollectionViewDataSource
//
//  Created by Tobias Kräntzer on 20.01.14.
//  Copyright (c) 2014 nxtbgthng GmbH. All rights reserved.
//

#import "NXCollectionViewDataSource.h"

@interface NXStaticCollectionViewDataSource : NXCollectionViewDataSource

#pragma mark Static Content
@property (nonatomic, readonly) NSArray *sectionItems;
@property (nonatomic, readonly) NSArray *sections;

#pragma mark Reload
- (void)reloadWithSections:(NSArray *)sections sectionItems:(NSArray *)sectionItems;

@end
