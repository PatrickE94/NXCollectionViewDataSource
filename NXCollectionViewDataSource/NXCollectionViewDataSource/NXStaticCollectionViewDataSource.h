//
//  NXStaticCollectionViewDataSource.h
//  NXCollectionViewDataSource
//
//  Created by Tobias Kräntzer on 20.01.14.
//  Copyright (c) 2014 nxtbgthng GmbH. All rights reserved.
//

#import "NXCollectionViewDataSource.h"

@interface NXStaticCollectionViewDataSource : NXCollectionViewDataSource

#pragma mark Life-cycle
- (id)initWithSections:(NSArray *)sections sectionNames:(NSArray *)sectionNames forCollectionView:(UICollectionView *)collectionView;

#pragma mark Reload
- (BOOL)reloadWithSections:(NSArray *)sections sectionNames:(NSArray *)sectionNames;

@end
