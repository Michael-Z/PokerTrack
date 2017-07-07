//
//  EditSegmentVC.m
//  PokerTracker
//
//  Created by Rick Medved on 7/6/17.
//
//

#import "EditSegmentVC.h"
#import "CoreDataLib.h"
#import "TextLineEnterVC.h"

@interface EditSegmentVC ()

@end

@implementation EditSegmentVC

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.entity = [[NSString alloc] init];
	self.listDict = [[NSMutableDictionary alloc] init];
	self.list = [[NSMutableArray alloc] init];
	
	self.navigationItem.leftBarButtonItem = [ProjectFunctions UIBarButtonItemWithIcon:[NSString fontAwesomeIconStringForEnum:FATimes] target:self action:@selector(cancel:)];
	
	self.selectButton = [ProjectFunctions UIBarButtonItemWithIcon:[NSString fontAwesomeIconStringForEnum:FACheck] target:self action:@selector(save:)];
	self.navigationItem.rightBarButtonItem = self.selectButton;

	NSArray *optionList = [NSArray arrayWithObjects:@"1", @"2", @"3", @"4", @"GameType", @"Stakes", @"Limit", @"Tournament", nil];
	NSString *optionStr = [NSString stringWithFormat:@"%@", [optionList objectAtIndex:self.option]];
	self.entity = [optionStr uppercaseString];
	[self setTitle:NSLocalizedString(optionStr, nil)];
	[ProjectFunctions makeFAButton:self.deleteButton type:0 size:24];
	[ProjectFunctions makeFAButton:self.addButton type:1 size:24];
	[ProjectFunctions makeFAButton:self.editButton type:2 size:24];

	[self refreshFromDatabase];

}

-(void)refreshFromDatabase {
	[self.list removeAllObjects];
	[self.list addObjectsFromArray:[CoreDataLib getEntityNameList:self.entity mOC:self.managedObjectContext]];
	NSArray *games = [CoreDataLib selectRowsFromTable:@"GAME" mOC:self.managedObjectContext];
	NSString *field = [self.entity lowercaseString];
	if([@"tournament" isEqualToString:field])
		field = @"tournamentType";
	NSArray *keys = [self.listDict allKeys];
	for (NSString *key in keys) {
		[self.listDict setValue:@"0" forKey:key];
	}
	for (NSManagedObject *mo in games) {
		NSString *gameType = [mo valueForKey:@"Type"];
		if ([@"gametype" isEqualToString:field] ||
			[@"limit" isEqualToString:field] ||
			([@"stakes" isEqualToString:field] && [@"Cash" isEqualToString:gameType]) ||
			([@"tournamentType" isEqualToString:field] && [@"Tournament" isEqualToString:gameType])) {
			NSString *type = [mo valueForKey:field];
			int count = [[self.listDict valueForKey:type] intValue];
			count++;
			[self.listDict setValue:[NSString stringWithFormat:@"%d", count] forKey:type];
		}
	}
	[self sortDict:self.listDict field:field];
	[self setupData];
}

-(void)sortDict:(NSMutableDictionary *)dict field:(NSString *)field {
	NSMutableArray *array = [[NSMutableArray alloc] init];
	NSArray *keys = [dict allKeys];
	for (NSString *key in keys) {
		int count = [[dict valueForKey:key] intValue];
		[array addObject:[NSString stringWithFormat:@"%d:%@", count+100, key]];
	}
	NSArray *sortedArray = [ProjectFunctions sortArrayDescending:array];
	NSString *finalList = [sortedArray componentsJoinedByString:@"|"];
	[ProjectFunctions setUserDefaultValue:finalList forKey:[NSString stringWithFormat:@"%@Segments", field]];
}

-(void)setupData {
	self.editButton.enabled=self.optionSelectedFlg;
	self.deleteButton.enabled=self.optionSelectedFlg;
	self.selectButton.enabled=self.optionSelectedFlg;
	[self.mainTableView reloadData];
}

-(void) setReturningValue:(NSString *) value {
	if (value.length==0) {
		[ProjectFunctions showAlertPopup:@"Error" message:@"Invalid entry!"];
		return;
	}
	for (NSString *item in self.list) {
		if ([item isEqualToString:value]) {
			[ProjectFunctions showAlertPopup:@"Error" message:@"That value already exists!"];
			return;
		}
	}
	[self.list addObject:value];
	self.optionSelectedFlg=YES;
	self.rowNum = (int)self.list.count-1;
	[self setupData];
}


- (IBAction)deleteButtonPressed:(id)sender {
	int numGames = [[self.listDict valueForKey:[self.list objectAtIndex:self.rowNum]] intValue];
	if (numGames>0) {
		[ProjectFunctions showAlertPopup:@"Sorry" message:@"There already exists games with this entry. You cannot edit or delete it."];
		return;
	}
	[ProjectFunctions showConfirmationPopup:@"Delete this entry?" message:@"" delegate:self tag:1];
	
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if(buttonIndex != alertView.cancelButtonIndex) {
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name = %@", [self.list objectAtIndex:self.rowNum]];
		NSArray *records = [CoreDataLib selectRowsFromEntity:self.entity predicate:predicate sortColumn:nil mOC:self.managedObjectContext ascendingFlg:NO];
		if(records.count>0) {
			NSManagedObject *mo = [records objectAtIndex:0];
			[self.managedObjectContext deleteObject:mo];
			[self.managedObjectContext save:nil];
			[ProjectFunctions showAlertPopup:@"Success!" message:@""];
			self.optionSelectedFlg=NO;
			[self refreshFromDatabase];
		}
	}
}

- (IBAction)editButtonPressed:(id)sender {
	int numGames = [[self.listDict valueForKey:[self.list objectAtIndex:self.rowNum]] intValue];
	if (numGames>0) {
		[ProjectFunctions showAlertPopup:@"Sorry" message:@"There already exists games with this entry. You cannot edit or delete it."];
		return;
	}
	
}

- (IBAction)addButtonPressed:(id)sender {
	TextLineEnterVC *detailViewController = [[TextLineEnterVC alloc] initWithNibName:@"TextLineEnterVC" bundle:nil];
	detailViewController.titleLabel = self.title;
	detailViewController.initialDateValue = @"";
	detailViewController.callBackViewController = self;
	[self.navigationController pushViewController:detailViewController animated:YES];
}

- (IBAction)cancel:(id)sender {
	[self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)save:(id)sender {
	[(ProjectFunctions *)self.callBackViewController setReturningValue:[self.list objectAtIndex:self.rowNum]];
	[self.navigationController popViewControllerAnimated:YES];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	NSString *cellIdentifier = [NSString stringWithFormat:@"cellIdentifierSection%dRow%d", (int)indexPath.section, (int)indexPath.row];
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
	if(cell==nil)
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
	int numGames = [[self.listDict valueForKey:[self.list objectAtIndex:indexPath.row]] intValue];
	cell.textLabel.text=[NSString stringWithFormat:@"%@ (%d games)", [self.list objectAtIndex:indexPath.row], numGames];
	cell.accessoryType= UITableViewCellAccessoryDisclosureIndicator;
	cell.backgroundColor = [UIColor whiteColor];
	if (self.optionSelectedFlg && self.rowNum == indexPath.row) {
		cell.accessoryType= UITableViewCellAccessoryCheckmark;
		cell.backgroundColor = [UIColor colorWithRed:.9 green:1 blue:.9 alpha:1];
	}
	
	cell.selectionStyle = UITableViewCellSelectionStyleDefault;
	return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.list.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	self.optionSelectedFlg = YES;
	self.rowNum = (int)indexPath.row;
	[self setupData];
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return CGFLOAT_MIN;
}


-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
	return CGFLOAT_MIN;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 44;
}

@end