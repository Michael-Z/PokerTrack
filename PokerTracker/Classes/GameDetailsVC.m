//
//  GameDetailsVC.m
//  PokerTracker
//
//  Created by Rick Medved on 10/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GameDetailsVC.h"
#import "UIColor+ATTColor.h"
#import "DatePickerViewController.h"
#import "SelectionCell.h"
#import "NSDate+ATTDate.h"
#import "NSString+ATTString.h"
#import "NSArray+ATTArray.h"
#import "MoneyPickerVC.h"
#import "ListPicker.h"
#import "CoreDataLib.h"
#import "GamesVC.h"
#import "ProjectFunctions.h"
#import "TextEnterVC.h"
#import "MinuteEnterVC.h"
#import "MultiLineDetailCellWordWrap.h"
#import "ActionCell.h"
#import "GameGraphVC.h"
#import "MainMenuVC.h"
#import "GameDetailObj.h"
#import "EditSegmentVC.h"
#import "HudTrackerVC.h"
#import "EditGameTypeVC.h"


@implementation GameDetailsVC
@synthesize managedObjectContext, gameObj, detailItems;
@synthesize formDataArray, selectedFieldIndex, mainTableView, labelValues, labelTypes, changesMade;
@synthesize doneButton, topProgressLabel, saveEditButton, viewEditable;
@synthesize mo, buttonForm;
@synthesize activityIndicatorServer, textViewBG, activityLabel;
@synthesize graphButton, dateLabel, amountLabel, timeLabel;


- (void)viewDidLoad {
	[super viewDidLoad];
	[self setTitle:NSLocalizedString(@"Details", nil)];
	[self changeNavToIncludeType:17];
	
	self.detailItems = [[NSMutableArray alloc] init];
	self.selectedFieldIndex=0;
	self.changesMade=NO;

	self.viewEditable = NO;
	
	self.navigationItem.rightBarButtonItem = [ProjectFunctions UIBarButtonItemWithIcon:[NSString fontAwesomeIconStringForEnum:FAPencil] target:self action:@selector(saveButtonClicked:)];

	self.textViewBG.alpha=0;
	self.activityLabel.alpha=0;
	[ProjectFunctions makeFAButton:self.hudButton type:5 size:18 text:@"HUD"];
	[self.hudButton assignMode:1];
	[ProjectFunctions makeFAButton:self.deleteButton type:0 size:18];
	[self.deleteButton assignMode:3];
	self.deleteButton.enabled=NO;
	self.hudButton.enabled=NO;
	
	self.multiCellObj = [MultiCellObj initWithTitle:@"" altTitle:@"" labelPercent:.5];
	
}

-(void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self setupData];
}

-(void)setupData {
	self.gameObj = [GameObj gameObjFromDBObj:mo];
	[self.multiCellObj populateObjWithGame:self.gameObj];
	
	NSString *stakesName = @"stakes"; // not NSLocalizedString!
	NSString *stakesValue = self.gameObj.stakes;
	if([self.gameObj.type isEqualToString:@"Tournament"]) {
		stakesName = @"tournamentType";
		stakesValue = self.gameObj.tournamentType;
	}
	// types 1=date, 2=money, 3=refdata, 4=int, 5=text, 6=Type
	[self.detailItems removeAllObjects];
	[self.detailItems addObject:[GameDetailObj detailObjWithName:@"Type" value:self.gameObj.type type:6]];
	[self.detailItems addObject:[GameDetailObj detailObjWithName:@"startTime" value:self.gameObj.startTimePTP type:1]];
	[self.detailItems addObject:[GameDetailObj detailObjWithName:@"endTime" value:self.gameObj.endTimePTP type:1]];
	[self.detailItems addObject:[GameDetailObj detailObjWithName:@"buyInAmount" value:self.gameObj.buyInAmountStr type:2]];
	[self.detailItems addObject:[GameDetailObj detailObjWithName:@"rebuyAmount" value:self.gameObj.reBuyAmountStr type:2]];
	[self.detailItems addObject:[GameDetailObj detailObjWithName:@"foodDrinks" value:self.gameObj.foodDrinkStr type:2]];
	[self.detailItems addObject:[GameDetailObj detailObjWithName:@"cashoutAmount" value:self.gameObj.cashoutAmountStr type:2]];
	[self.detailItems addObject:[GameDetailObj detailObjWithName:@"tokes" value:self.gameObj.tokesStr type:2]];
	[self.detailItems addObject:[GameDetailObj detailObjWithName:@"gametype" value:self.gameObj.gametype type:3]];
	[self.detailItems addObject:[GameDetailObj detailObjWithName:stakesName value:stakesValue type:3]];
	[self.detailItems addObject:[GameDetailObj detailObjWithName:@"limit" value:self.gameObj.limit type:3]];
	[self.detailItems addObject:[GameDetailObj detailObjWithName:@"location" value:self.gameObj.location type:3]];
	[self.detailItems addObject:[GameDetailObj detailObjWithName:@"bankroll" value:self.gameObj.bankroll type:3]];
	[self.detailItems addObject:[GameDetailObj detailObjWithName:@"numRebuys" value:self.gameObj.numRebuysStr type:4]];
	if([self.gameObj.type isEqualToString:@"Tournament"]) {
		[self.detailItems addObject:[GameDetailObj detailObjWithName:@"tournamentSpots" value:self.gameObj.tournamentSpotsStr type:4]];
		[self.detailItems addObject:[GameDetailObj detailObjWithName:@"tournamentSpotsPaid" value:self.gameObj.tournamentSpotsPaidStr type:4]];
		[self.detailItems addObject:[GameDetailObj detailObjWithName:@"tournamentFinish" value:self.gameObj.tournamentFinishStr type:4]];
		[self.detailItems addObject:[GameDetailObj detailObjWithName:@"startingChips" value:[NSString stringWithFormat:@"%d", (int)self.gameObj.startingChips] type:4]];
		[self.detailItems addObject:[GameDetailObj detailObjWithName:@"rebuyChips" value:[NSString stringWithFormat:@"%d", (int)self.gameObj.rebuyChips] type:4]];
	}
	[self.detailItems addObject:[GameDetailObj detailObjWithName:@"breakMinutes" value:self.gameObj.breakMinutesStr type:4]];
	[self.detailItems addObject:[GameDetailObj detailObjWithName:@"notes" value:self.gameObj.notes type:5]];
	
	[self.mainTableView reloadData];
}

- (IBAction) deleteButtonPressed: (id) sender {
	self.buttonForm=101;
	[ProjectFunctions showConfirmationPopup:@"Warning!" message:@"Are you sure you want to delete this game?" delegate:self tag:101];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if(buttonForm==99) {
		UIViewController *mainMenu = [self.navigationController.viewControllers objectAtIndex:1];
		[self.navigationController popToViewController:mainMenu animated:YES];
	} 
	if(buttonForm==0) {
		if(buttonIndex==1)
			[self.navigationController popViewControllerAnimated:YES];
	}
	if(buttonForm==101) {
		if(buttonIndex==1 && mo != nil) {
			double winnings = [[mo valueForKey:@"winnings"] doubleValue];
			
			NSString *bankrollName = [ProjectFunctions getUserDefaultValue:@"bankrollDefault"];
			if([bankrollName length]==0 || [bankrollName isEqualToString:@"Default"])
				bankrollName = @"Bankroll";
			
			int currentBankroll = [[ProjectFunctions getUserDefaultValue:@"defaultBankroll"] intValue];
			int newBankroll = currentBankroll +winnings*-1;
			[ProjectFunctions setUserDefaultValue:[NSString stringWithFormat:@"%d", newBankroll] forKey:@"defaultBankroll"];
			
			[managedObjectContext deleteObject:mo];
			[self saveDatabase];
			[ProjectFunctions updateGamesOnDevice:self.managedObjectContext];

			[self.navigationController popToViewController:[self.navigationController.viewControllers objectAtIndex:1] animated:YES];
		}
	}
}

- (void) cancelButtonClicked:(id)sender {
	[self.navigationController popViewControllerAnimated:YES];
}

-(void)refreshWebRequest
{
	@autoreleasepool {
    
		if([ProjectFunctions uploadUniverseStats:managedObjectContext])
			[ProjectFunctions showAlertPopupWithDelegate:@"Success" message:@"Server data synced" delegate:self];

		
		self.textViewBG.alpha=0;
		self.activityLabel.alpha=0;
		[activityIndicatorServer stopAnimating];
	}
}

-(void)executeThreadedJob:(SEL)aSelector
{
	[self performSelectorInBackground:aSelector withObject:nil];
	
}

- (void) saveButtonClicked:(id)sender {
	viewEditable = !viewEditable;
	self.deleteButton.enabled=viewEditable;
	self.hudButton.enabled=viewEditable;
	[mainTableView reloadData];
	[self setTitle:(viewEditable)?NSLocalizedString(@"Edit Mode", nil):NSLocalizedString(@"Details", nil)];
}


-(void)mainMenuButtonClicked:(id)sender {
	[self.navigationController popToViewController:[self.navigationController.viewControllers objectAtIndex:1] animated:YES];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if(indexPath.section==0 && mo != nil) {
		return [MultiLineDetailCellWordWrap heightForMultiCellObj:self.multiCellObj tableView:self.mainTableView];
	}
	
	return 44;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if(section==0)
		return 1;
	
    return self.detailItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	NSString *cellIdentifier = [NSString stringWithFormat:@"cellIdentifierSection%dRow%d", (int)indexPath.section, (int)indexPath.row];
	if(indexPath.section==0) {
		return [MultiLineDetailCellWordWrap multiCellForID:@"cell2" obj:self.multiCellObj tableView:tableView];
	}
	if(indexPath.row<self.detailItems.count) {
		SelectionCell *cell = (SelectionCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [[SelectionCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
		}
		GameDetailObj *obj = [self.detailItems objectAtIndex:indexPath.row];
		cell.textLabel.text = NSLocalizedString(obj.name, nil);
		cell.selection.text = obj.value;
		NSArray *backgroundColors = [NSArray arrayWithObjects:
									 [UIColor ATTSilver], //not editable
									 [UIColor colorWithRed:1 green:1 blue:.9 alpha:1], //date
									 [UIColor colorWithRed:.9 green:1 blue:.9 alpha:1], //money
									 [UIColor colorWithRed:.9 green:.9 blue:1 alpha:1], //list
									 [UIColor ATTFaintBlue], //number
									 [UIColor whiteColor], //text
									 [UIColor colorWithRed:.9 green:1 blue:1 alpha:1], //text
									 [UIColor yellowColor], //text
									 nil];
		cell.backgroundColor = [backgroundColors objectAtIndex:obj.type];
		
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
		cell.accessoryType = (viewEditable)?UITableViewCellAccessoryDisclosureIndicator:UITableViewCellAccessoryNone;
		if(obj.type==0) {
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			cell.accessoryType = UITableViewCellAccessoryNone;
		}
		return cell;
	} else {
		ActionCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [[ActionCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
		}
		cell.backgroundColor = [UIColor colorWithRed:1 green:0.2 blue:0 alpha:1];
		cell.textLabel.text = NSLocalizedString(@"Delete Game", nil);
		cell.textLabel.textColor = [UIColor whiteColor];
		return cell;
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if(indexPath.section==0)
		return;
	if(!viewEditable) {
		[ProjectFunctions showAlertPopup:NSLocalizedString(@"notice", nil) message:NSLocalizedString(@"EditWarning", nil)];
		return;
	}
	
	if(indexPath.row==self.detailItems.count) {
		self.buttonForm=101;
		[ProjectFunctions showConfirmationPopup:@"Warning!" message:@"Are you sure you want to delete this game?" delegate:self tag:101];
		return;
	}
	selectedFieldIndex = (int)indexPath.row;
	GameDetailObj *obj = [self.detailItems objectAtIndex:indexPath.row];
	
	if(obj.type==1) {
		DatePickerViewController *localViewController = [[DatePickerViewController alloc] init];
		localViewController.labelString = obj.name;
		[localViewController setCallBackViewController:self];
		localViewController.initialDateValue = nil;
		localViewController.allowClearField = NO;
		localViewController.dateOnlyMode = NO;
		localViewController.refusePastDates = NO;
		localViewController.initialValueString = obj.value;
		[self.navigationController pushViewController:localViewController animated:YES];
	} 
	if(obj.type==2) {
		MoneyPickerVC *localViewController = [[MoneyPickerVC alloc] initWithNibName:@"MoneyPickerVC" bundle:nil];
		localViewController.managedObjectContext=managedObjectContext;
		localViewController.callBackViewController = self;
		localViewController.initialDateValue = obj.value;
		localViewController.titleLabel = obj.name;
		[self.navigationController pushViewController:localViewController animated:YES];
	}
	if(obj.type==3) { // list
		EditSegmentVC *localViewController = [[EditSegmentVC alloc] initWithNibName:@"EditSegmentVC" bundle:nil];
		localViewController.callBackViewController=self;
		localViewController.managedObjectContext = managedObjectContext;
		localViewController.option = 4;
		localViewController.initialDateValue = obj.value;
		localViewController.databaseField = obj.name;
		[self.navigationController pushViewController:localViewController animated:YES];
	}
	if(obj.type==4) {
		MinuteEnterVC *localViewController = [[MinuteEnterVC alloc] initWithNibName:@"MinuteEnterVC" bundle:nil];
		[localViewController setCallBackViewController:self];
		localViewController.initialDateValue = obj.value;
		localViewController.sendTitle = obj.name;
		localViewController.managedObjectContext=self.managedObjectContext;
		[self.navigationController pushViewController:localViewController animated:YES];
	}
	if(obj.type==5) {
		TextEnterVC *localViewController = [[TextEnterVC alloc] initWithNibName:@"TextEnterVC" bundle:nil];
		[localViewController setCallBackViewController:self];
		localViewController.managedObjectContext=managedObjectContext;
		localViewController.initialDateValue = obj.value;
		localViewController.titleLabel = obj.name;
		[self.navigationController pushViewController:localViewController animated:YES];
	}
	if(obj.type==6) {
		EditGameTypeVC *localViewController = [[EditGameTypeVC alloc] initWithNibName:@"EditGameTypeVC" bundle:nil];
		[localViewController setCallBackViewController:self];
		localViewController.managedObjectContext=managedObjectContext;
		localViewController.initialDateValue = obj.value;
		[self.navigationController pushViewController:localViewController animated:YES];
	}
}

- (IBAction) hudButtonPressed: (id) sender {
	HudTrackerVC *localViewController = [[HudTrackerVC alloc] initWithNibName:@"HudTrackerVC" bundle:nil];
	localViewController.managedObjectContext=managedObjectContext;
	localViewController.gameMo = mo;
	[self.navigationController pushViewController:localViewController animated:YES];
}


-(void) setReturningValue:(NSString *) value {
	self.navigationItem.rightBarButtonItem = [ProjectFunctions UIBarButtonItemWithIcon:[NSString fontAwesomeIconStringForEnum:FAHome] target:self action:@selector(mainMenuButtonClicked:)];
	
	GameDetailObj *obj = [self.detailItems objectAtIndex:selectedFieldIndex];
	
	if(obj.type==1) { // date
		if([@"endTime" isEqualToString:obj.name] && [[(NSString *)value convertStringToDateWithFormat:nil] compare:self.gameObj.startTime] != NSOrderedDescending) {
			[ProjectFunctions showAlertPopup:@"Error" message:@"End time must be after start time!"];
			return;
		}
		
		if([@"startTime" isEqualToString:obj.name]  && [self.gameObj.endTime compare:[value convertStringToDateWithFormat:nil]] != NSOrderedDescending) {
			[ProjectFunctions showAlertPopup:@"Error" message:@"Start time must be before end time!"];
			return;
		}
		[mo setValue:[(NSString *)value convertStringToDateWithFormat:nil] forKey:obj.name];
	}
	if(obj.type==2) { // money
		double amount = [ProjectFunctions convertMoneyStringToDouble:value];
		[mo setValue:[NSNumber numberWithDouble:amount] forKey:obj.name];
	}
	if(obj.type==3 || obj.type==5) { // list & text
		[mo setValue:value forKey:obj.name];
	}
	if(obj.type==4) { // int
		//attrib05	//startingChips
		//hudHeroLine	//currentChips
		//hudVillianLine // rebuyChips
		if([@"startingChips" isEqualToString:obj.name])
			[mo setValue:value forKey:@"attrib05"];
		else if([@"rebuyChips" isEqualToString:obj.name])
			[mo setValue:value forKey:@"hudVillianLine"];
		else
			[mo setValue:[NSNumber numberWithInt:[value intValue]] forKey:obj.name];
	}
	if(obj.type==6) {
		NSArray *components = [value componentsSeparatedByString:@"|"];
		if(components.count>1) {
			NSString *type = [components objectAtIndex:0];
			NSString *newValue = [components objectAtIndex:1];
			[mo setValue:type forKey:@"Type"];
			if([@"Cash" isEqualToString:type]) {
				[mo setValue:newValue forKey:@"stakes"];
				[mo setValue:@"" forKey:@"tournamentType"];
			} else {
				[mo setValue:@"" forKey:@"stakes"];
				[mo setValue:newValue forKey:@"tournamentType"];
			}
		}
	}
	
	[ProjectFunctions scrubDataForObj:mo context:self.managedObjectContext];
	[self saveDatabase];
	[ProjectFunctions findMinAndMaxYear:self.managedObjectContext];
	[self setupData];
}





@end
