//
//  FilterListVC.m
//  PokerTracker
//
//  Created by Rick Medved on 11/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FilterListVC.h"
#import "CoreDataLib.h"
#import "FiltersVC.h"
#import "FilterNameEnterVC.h"
#import "ProjectFunctions.h"

@implementation FilterListVC
@synthesize managedObjectContext, filterList, callBackViewController, mainTableView, editMode, filterObj;
@synthesize editButton, filterSegment, selectedRowId, detailsButton, selectedButton, maxFilterId;


- (void)viewDidLoad {
	[super viewDidLoad];
	[self setTitle:@"Filters"];
	
	NSArray *filters = [CoreDataLib selectRowsFromEntity:@"FILTER" predicate:nil sortColumn:@"button" mOC:managedObjectContext ascendingFlg:YES];
	for(NSManagedObject *mo in filters) {
		int row_id = [[mo valueForKey:@"row_id"] intValue];
		if(row_id==0) {
			self.maxFilterId++;
			[mo setValue:[NSNumber numberWithInt:self.maxFilterId] forKey:@"row_id"];
			[self.managedObjectContext save:nil];
		}
	}
	self.filterList = [[NSMutableArray alloc] initWithArray:filters];
	
	[ProjectFunctions makeSegment:self.filterSegment color:[UIColor colorWithRed:0 green:.5 blue:0 alpha:1]];
	
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if([self respondsToSelector:@selector(edgesForExtendedLayout)])
        [self setEdgesForExtendedLayout:UIRectEdgeBottom];

	self.editButton.enabled=NO;
	self.detailsButton.enabled=NO;
	
	[self checkCustomSegment];
	
	[self reloadView];

}

-(void)checkCustomSegment
{
	for(int i=1; i<=3; i++) {
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"button = %d", i];
		NSArray *filters = [CoreDataLib selectRowsFromEntity:@"FILTER" predicate:predicate sortColumn:@"button" mOC:self.managedObjectContext ascendingFlg:YES];
		if([filters count]>0) {
			NSManagedObject *mo = [filters objectAtIndex:0];
			[self.filterSegment setTitle:[mo valueForKey:@"name"] forSegmentAtIndex:i];
		}
	}
	
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return CGFLOAT_MIN;
}

-(void)editMenuButtonClicked:(id)sender {
    self.editMode=!self.editMode;
    [self.mainTableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.filterList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *CellIdentifier = [NSString stringWithFormat:@"cellIdentifierSection%dRow%d", (int)indexPath.section, (int)indexPath.row];
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
	}
	
	cell.backgroundColor = [UIColor whiteColor];
	cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	NSManagedObject *mo = [self.filterList objectAtIndex:indexPath.row];
	int button = [[mo valueForKey:@"button"] intValue];
	int row_id = [[mo valueForKey:@"row_id"] intValue];

	if(button<=3)
		cell.textLabel.text = [NSString stringWithFormat:@"[%d] %@ (Tab %d)", row_id, [mo valueForKey:@"name"], button];
	else
		cell.textLabel.text = [NSString stringWithFormat:@"[%d] %@", row_id, [mo valueForKey:@"name"]];
    
    if(self.editMode) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
	
	return cell;
}

- (void)reloadView {
    [self.filterList removeAllObjects];
    [self.filterList addObjectsFromArray:[CoreDataLib selectRowsFromEntity:@"FILTER" predicate:nil sortColumn:@"button" mOC:managedObjectContext ascendingFlg:YES]];
    
    [self.mainTableView reloadData];
}

-(void) setReturningValue:(NSObject *) value2 {
    NSLog(@"+++%@", value2);
}

	
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	self.filterSegment.selectedSegmentIndex=0;
//	NSManagedObject *mo = [self.filterList objectAtIndex:indexPath.row];
//	self.selectedButton = [[mo valueForKey:@"button"] intValue];
	self.filterObj = [self.filterList objectAtIndex:indexPath.row];
	self.selectedRowId = (int)indexPath.row;
	self.editButton.enabled=YES;
	self.detailsButton.enabled=YES;
}

- (IBAction) detailsButtonPressed: (id) sender {
	[(FiltersVC *)callBackViewController chooseFilterObj:self.filterObj];
//	[(FiltersVC *)callBackViewController setFilterIndex:self.selectedRowId];
	[self.navigationController popViewControllerAnimated:YES];
}
- (IBAction) editButtonPressed: (id) sender {
	FilterNameEnterVC *detailViewController = [[FilterNameEnterVC alloc] initWithNibName:@"FilterNameEnterVC" bundle:nil];
	detailViewController.callBackViewController = self;
	detailViewController.managedObjectContext = managedObjectContext;
	detailViewController.filerObj=[self.filterList objectAtIndex:self.selectedRowId];
	[self.navigationController pushViewController:detailViewController animated:YES];
}




@end
