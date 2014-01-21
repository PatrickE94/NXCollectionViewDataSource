//
//  NXFetchedCollectionViewDataSource.m
//  NXCollectionViewDataSource
//
//  Created by Tobias Kräntzer on 20.01.14.
//  Copyright (c) 2014 nxtbgthng GmbH. All rights reserved.
//

#import "NXFetchedCollectionViewDataSource.h"

@interface NXFetchedCollectionViewDataSource () <NSFetchedResultsControllerDelegate>
#pragma mark Core Data Properties
@property (nonatomic, readwrite, strong) NSFetchRequest *fetchRequest;
@property (nonatomic, readwrite, strong) NSString *sectionKeyPath;
@property (nonatomic, readwrite, strong) NSFetchedResultsController *fetchedResultsController;

#pragma mark Data Source Changes
@property (nonatomic, readonly) NSMutableIndexSet *insertedSections;
@property (nonatomic, readonly) NSMutableIndexSet *deletedSections;
@property (nonatomic, readonly) NSMutableArray *insertedItems;
@property (nonatomic, readonly) NSMutableArray *deletedItems;
@property (nonatomic, readonly) NSMutableArray *movedItems;
@end

@implementation NXFetchedCollectionViewDataSource

#pragma mark Life-cycle

- (id)initWithCollectionView:(UICollectionView *)collectionView managedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    self = [super initWithCollectionView:collectionView];
    if (self) {
        _managedObjectContext = managedObjectContext;
        
        _insertedSections = [[NSMutableIndexSet alloc] init];
        _deletedSections = [[NSMutableIndexSet alloc] init];
        
        _insertedItems = [[NSMutableArray alloc] init];
        _deletedItems = [[NSMutableArray alloc] init];
        _movedItems = [[NSMutableArray alloc] init];
    }
    return self;
}

#pragma mark Getting Item and Section Metrics

- (NSUInteger)numberOfSections
{
    return [[self.fetchedResultsController sections] count];
}

- (NSUInteger)numberOfItemsInSection:(NSUInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = self.fetchedResultsController.sections[section];
    return [sectionInfo numberOfObjects];
}

#pragma mark Getting Items and Index Paths

- (id)itemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.fetchedResultsController objectAtIndexPath:indexPath];
}

- (NSArray *)indexPathsOfItem:(id)item;
{
    return @[[self.fetchedResultsController indexPathForObject:item]];
}

#pragma mark Getting Section Name

- (NSString *)nameForSection:(NSUInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = self.fetchedResultsController.sections[section];
    return [sectionInfo name];
}


#pragma mark Reload

- (void)reloadWithFetchRequest:(NSFetchRequest *)fetchRequest sectionKeyPath:(NSString *)sectionKeyPath
{
    self.fetchRequest = fetchRequest;
    self.sectionKeyPath = sectionKeyPath;
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:self.fetchRequest
                                                                        managedObjectContext:self.managedObjectContext
                                                                          sectionNameKeyPath:self.sectionKeyPath
                                                                                   cacheName:nil];
    self.fetchedResultsController.delegate = self;
    
    NSError *error = nil;
    BOOL success = [self.fetchedResultsController performFetch:&error];
    
    NSAssert(success, [error localizedDescription]);
    
    [self reload];
}

#pragma mark NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.insertedSections removeAllIndexes];
    [self.deletedSections removeAllIndexes];
    [self.insertedItems removeAllObjects];
    [self.deletedItems removeAllObjects];
    [self.movedItems removeAllObjects];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.insertedSections addIndex:sectionIndex];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.deletedSections addIndex:sectionIndex];
            break;
            
        default:
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.insertedItems addObject:newIndexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [self.movedItems addObject:@[indexPath, newIndexPath]];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.deletedItems addObject:indexPath];
            break;
            
        case NSFetchedResultsChangeUpdate:
        default:
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    // Filter Changes
    // --------------
    
    NSIndexSet *insertedSections = [self.insertedSections copy];
    NSIndexSet *deletedSections = [self.deletedSections copy];
    
    NSPredicate *indexPathFilter = [NSPredicate predicateWithBlock:^BOOL(NSIndexPath *indexPath, NSDictionary *bindings) {
        
        if ([insertedSections containsIndex:indexPath.section]) {
            return NO;
        }
        
        if ([deletedSections containsIndex:indexPath.section]) {
            return NO;
        }
        
        return YES;
    }];
    
    NSArray *insertedItems = [self.insertedItems filteredArrayUsingPredicate:indexPathFilter];
    NSArray *deletedItems = [self.deletedItems filteredArrayUsingPredicate:indexPathFilter];
    
    NSArray *movedItems = [self.movedItems filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSArray *move, NSDictionary *bindings) {
        
        NSIndexPath *from = [move objectAtIndex:0];
        NSIndexPath *to = [move objectAtIndex:1];
        
        NSMutableIndexSet *sections = [[NSMutableIndexSet alloc] init];
        [sections addIndex:from.section];
        [sections addIndex:to.section];
        
        if ([insertedSections containsIndexes:sections]) {
            return NO;
        }
        
        if ([deletedSections containsIndexes:sections]) {
            return NO;
        }
        
        return YES;
    }]];
    
    BOOL hasChanges = [insertedSections count] > 0;
    hasChanges = hasChanges || [deletedSections count] > 0;
    hasChanges = hasChanges || [insertedItems count] > 0;
    hasChanges = hasChanges || [deletedItems count] > 0;
    hasChanges = hasChanges || [movedItems count] > 0;
    
    // Perform Changes
    // ---------------
    
    if (hasChanges) {
        [self.collectionView performBatchUpdates:^{
            [self.collectionView deleteSections:deletedSections];
            [self.collectionView insertSections:insertedSections];
            
            [self.collectionView insertItemsAtIndexPaths:insertedItems];
            [self.collectionView deleteItemsAtIndexPaths:deletedItems];
            
            [movedItems enumerateObjectsUsingBlock:^(NSArray *move, NSUInteger idx, BOOL *stop) {
                NSIndexPath *from = [move objectAtIndex:0];
                NSIndexPath *to = [move objectAtIndex:1];
                [self.collectionView moveItemAtIndexPath:from toIndexPath:to];
            }];
        } completion:^(BOOL finished) {
            
        }];
        
        if (self.postUpdateBlock) {
            self.postUpdateBlock(self);
        }
    }
}

@end
