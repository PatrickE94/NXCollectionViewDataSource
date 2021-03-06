//
//  NXStaticCollectionViewDataSource.m
//  NXCollectionViewDataSource
//
//  Created by Tobias Kräntzer on 20.01.14.
//  Copyright (c) 2014 nxtbgthng GmbH. All rights reserved.
//

#import "NXStaticCollectionViewDataSource.h"

@interface NXStaticCollectionViewDataSource ()
#pragma mark Static Content
@property (nonatomic, readwrite, strong) NSArray *sectionItems;
@property (nonatomic, readwrite, strong) NSArray *sections;
@property (nonatomic, readonly) NSMutableDictionary *items;
@end

@implementation NXStaticCollectionViewDataSource

#pragma mark Life-cycle

- (id)initWithCollectionView:(UICollectionView *)collectionView
{
    self = [super initWithCollectionView:collectionView];
    if (self) {
        _sections = @[];
        _sectionItems = @[];
        _items = [[NSMutableDictionary alloc] init];
    }
    return self;
}

#pragma mark Getting Item and Section Metrics

- (NSInteger)numberOfSections
{
    return [self.sections count];
}

- (NSInteger)numberOfItemsInSection:(NSInteger)section
{
    return [self.sections[section] count];
}

#pragma mark Getting Items and Index Paths

- (id)itemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.items objectForKey:indexPath];
}

- (NSArray *)indexPathsOfItem:(id)item;
{
    return [self.items allKeysForObject:item];
}

#pragma mark Getting Section Item

- (id)itemForSection:(NSInteger)section
{
    return self.sectionItems[section];
}

#pragma mark Reload

- (void)reloadWithSections:(NSArray *)sections sectionItems:(NSArray *)sectionNames
{
    self.sections = sections;
    self.sectionItems = sectionNames;
    
    [self.items removeAllObjects];
    
    [self.sections enumerateObjectsUsingBlock:^(NSArray *section, NSUInteger sectionIndex, BOOL *stop) {
        [section enumerateObjectsUsingBlock:^(id item, NSUInteger itemIndex, BOOL *stop) {
            [self.items setObject:item forKey:[NSIndexPath indexPathForItem:itemIndex inSection:sectionIndex]];
        }];
    }];
    
    [super reload];
}

- (void)reset
{
    [self reloadWithSections:nil sectionItems:nil];
}

@end
