//
//  DatabaseManage.m
//  PokerTracker
//
//  Created by Rick Medved on 10/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DatabaseManage.h"
#import "ProjectFunctions.h"
#import "UIColor+ATTColor.h"
#import "LoginVC.h"
#import "CoreDataLib.h"
#import "NSString+ATTString.h"
#import "NSDate+ATTDate.h"
#import "WebServicesFunctions.h"
#import "CreateOldGameVC.h"
#import "LocationsVC.h"
#import "EmailFile.h"
#import "CasinoTrackerVC.h"
#import "NSArray+ATTArray.h"
#import "ListPicker.h"
#import "SelectionCell.h"
#import "cleanupRefData.h"
#import "ProfileVC.h"
#import "TauntVC.h"
#import "MainMenuVC.h"
#import "LockAppVC.h"
#import "FriendAlertsVC.h"
#import "BankrollsVC.h"
#import "ExportCell.h"
#import "UpgradeVC.h"
#import "ChangeIconVC.h"
#import "Scrub2017VC.h"
#import "EditThemeVC.h"

#define kstartDate		0
#define kendDate		1
#define kbreakTime		2
#define kgameName		6
#define kgamestakes		7
#define klimitType		8
#define klocation		9
#define kbuyinAmount	11
#define kcashoutAmount	12
#define ktips			13
#define ktokes			14
#define kwinningAmount	15
#define knotes			17

#define kDeleteAllData	1
#define kExportData		2
#define kImportData		3
#define kImportPokerJounralData	4
#define kClearServerData	5
#define kLogout		101



//#define kFieldSeparator				@"\ue212"
#define kFieldSeparator				@"|"

@implementation DatabaseManage
@synthesize menuArray, gSelectedRow, activityIndicator, activityLabel, gamesImportedLabel, totalNumGamesImported;
@synthesize importInProgress, totalImportedLines, numImportedLinesRead, progressView, userLabel;
@synthesize managedObjectContext, mainTableView, secondMenuArray, messageString, activityLabelString;
@synthesize activityBG, activityPopup, emailLabel, coreDataLocked, importProgressLabel, exportTextLabel;
@synthesize importPopup, importTextView, laterButton, importButton, importType, callBackViewController;

#pragma mark -
#pragma mark View lifecycle

- (IBAction) laterPressed: (id) sender
{
	importPopup.alpha=0;
	importTextView.alpha=0;
	laterButton.alpha=0;
	importButton.alpha=0;
	activityBG.alpha=0;
}

- (IBAction) importPressed: (id) sender
{
	importPopup.alpha=0;
	importTextView.alpha=0;
	laterButton.alpha=0;
	importButton.alpha=0;
	activityBG.alpha=0;
	if(importType==1) {
		[self executeThreadedJob:@selector(ImportPokerJournalData)];
	}
	if(importType==2) {
		[self executeThreadedJob:@selector(ImportPokerIncomeData)];
	}
	
	
}

- (IBAction) loginPressed: (id) sender {
	[self loginButtonClicked:nil];
}

-(void)loginButtonClicked:(id)sender {
	if([ProjectFunctions getUserDefaultValue:@"userName"]) {
		[ProjectFunctions showConfirmationPopup:@"Log out?" message:@"You are already logged in. Did you want to log out?" delegate:self tag:kLogout];
	} else {
		LoginVC *detailViewController = [[LoginVC alloc] initWithNibName:@"LoginVC" bundle:nil];
		detailViewController.managedObjectContext = managedObjectContext;
		[self.navigationController pushViewController:detailViewController animated:YES];
	}
}

- (void)viewDidLoad {
    [super viewDidLoad];
	[self setTitle:NSLocalizedString(@"Options", nil)];
	[self changeNavToIncludeType:38];
	
	self.activityLabelString = [[NSString alloc] init];
	self.activityLabelString = @"Working...";
	self.exportTextLabel.text = NSLocalizedString(@"ExportText", nil);

    [self.mainTableView setBackgroundView:nil];
	menuArray = [[NSMutableArray alloc] init];

	[menuArray addObject:NSLocalizedString(@"Export", nil)];
	[menuArray addObject:NSLocalizedString(@"Import", nil)];
	[menuArray addObject:NSLocalizedString(@"Clear", nil)];
	[menuArray addObject:NSLocalizedString(@"ImportJournal", nil)];
	[menuArray addObject:NSLocalizedString(@"ImportIncome", nil)];
	[menuArray addObject:NSLocalizedString(@"Delete", nil)];
	[menuArray addObject:NSLocalizedString(@"Email", nil)];
	[menuArray addObject:NSLocalizedString(@"Cleanup", nil)];
	[menuArray addObject:NSLocalizedString(@"Resync", nil)];

	secondMenuArray = [[NSMutableArray alloc] init];
	[secondMenuArray addObject:@"Edit Theme"];
	[secondMenuArray addObject:@"Enter Old Game"];
	[secondMenuArray addObject:@"Lock App"];
	[secondMenuArray addObject:@"Locations"];
	[secondMenuArray addObject:@"Edit Profile"];
	[secondMenuArray addObject:@"Friend Alerts"];
	[secondMenuArray addObject:@"Edit Bankroll"];
	[secondMenuArray addObject:@"Email Developer"];
	[secondMenuArray addObject:@"Write App Review"];
	[secondMenuArray addObject:@"Sound"];
	[secondMenuArray addObject:@"Tournament Director"];
	[secondMenuArray addObject:@"Taunt"];
	[secondMenuArray addObject:@"Edit Icons"];

	self.gSelectedRow=0;
	self.totalNumGamesImported=0;
	self.totalImportedLines=0;
	self.numImportedLinesRead=0;
	self.importInProgress=NO;
	self.upgradeButton.hidden=![ProjectFunctions isLiteVersion];
	
	self.activityPopup.alpha=0;
	self.activityBG.alpha=0;
	self.activityLabel.alpha=0;
	self.gamesImportedLabel.alpha=0;
	self.progressView.alpha=0;
    self.importProgressLabel.alpha=0;
    importProgressLabel.text = @"-";

	importPopup.alpha=0;
	importTextView.alpha=0;
	laterButton.alpha=0;
	importButton.alpha=0;

	self.emailLabel.textColor = [ProjectFunctions primaryButtonColor];
	self.userLabel.textColor = [ProjectFunctions primaryButtonColor];
	if([ProjectFunctions getUserDefaultValue:@"userName"])
		self.emailLabel.text = [NSString stringWithFormat:@"%@", [ProjectFunctions getUserDefaultValue:@"userName"]];
	
	self.loginButton.hidden=[ProjectFunctions getUserDefaultValue:@"userName"].length>0;
	
	if([ProjectFunctions getUserDefaultValue:@"firstName"])
		self.userLabel.text = [NSString stringWithFormat:@"%@", [ProjectFunctions getUserDefaultValue:@"firstName"]];

	self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:
											   [ProjectFunctions UIBarButtonItemWithIcon:[NSString fontAwesomeIconStringForEnum:FASignIn] target:self action:@selector(loginButtonClicked:)],
											   [ProjectFunctions UIBarButtonItemWithIcon:[NSString fontAwesomeIconStringForEnum:FAInfoCircle] target:self action:@selector(popupButtonClicked)],
											   nil];
	
	self.popupView.titleLabel.text = @"Database Backup";
	self.popupView.textView.text = @"Using this screen you can back up all your games. This is very important in case you lose your phone or upgrade to a new phone.\n\nKeep in mind you must manually back up your games on this screen to have them saved on the server. As you play new games they do NOT automatically get backed up.\n\nIts a good idea to back up your games often to prevent data loss.\n\nClick the login button at the top to get started.";
	self.popupView.textView.hidden=NO;
}

-(void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	if([self respondsToSelector:@selector(edgesForExtendedLayout)])
		[self setEdgesForExtendedLayout:UIRectEdgeBottom];
	[self.mainTableView reloadData];
}



#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
	return (self.isPokerZilla)?1:2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
	if(section==0)
		return [menuArray count];
	else
		return [secondMenuArray count];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	NSArray *titles = [NSArray arrayWithObjects:@"Database Management", @"Other", nil];
	return [ProjectFunctions getViewForHeaderWithText:[titles objectAtIndex:section]];
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return 22;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	NSArray *titles = [NSArray arrayWithObjects:@"Database Management", @"Other", nil];
	return [NSString stringWithFormat:@"%@", [titles objectAtIndex:section]];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
 	NSString *CellIdentifier = [NSString stringWithFormat:@"cellIdentifierSection%dRow%d", (int)indexPath.section, (int)indexPath.row];
	
	int gamesOnDevice = [[ProjectFunctions getUserDefaultValue:@"gamesOnDevice"] intValue];
	int gamesOnServer = [[ProjectFunctions getUserDefaultValue:@"gamesOnServer"] intValue];
	int numGamesServer2 = [[ProjectFunctions getUserDefaultValue:@"numGamesServer2"] intValue];
	if(numGamesServer2>gamesOnServer)
		gamesOnServer=numGamesServer2;
	
	UIColor *bgColor = [ProjectFunctions primaryButtonColor];
	UIColor *textColor = [ProjectFunctions segmentThemeColor];
	//UIColor *bgColor = [ProjectFunctions gradientBGColorForWidth:320 height:44];

	if(indexPath.section==0 && [[menuArray stringAtIndex:(int)indexPath.row] isEqualToString:NSLocalizedString(@"Export", nil)]) {
		ExportCell *cell = (ExportCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (cell == nil) {
			cell = [[ExportCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
		}
		cell.backgroundColor = bgColor;
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
		if([ProjectFunctions getUserDefaultValue:@"userName"].length>0)
			cell.titleLabel.textColor = textColor;
		
		cell.titleLabel.font = [UIFont fontWithName:kFontAwesomeFamilyName size:20.f];
		cell.titleLabel.text=[NSString stringWithFormat:@"%@ %@", [NSString fontAwesomeIconStringForEnum:FAUpload], NSLocalizedString(@"Export", nil)];
		cell.gamesStoredLabel.text = [NSString stringWithFormat:@"Device Games: %d", gamesOnDevice];
		
		if(gamesOnDevice>gamesOnServer)
			cell.titleLabel.textColor = [UIColor redColor];
		
		cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
		
		return cell;
	}
	if(indexPath.section==0 && [[menuArray stringAtIndex:(int)indexPath.row] isEqualToString:NSLocalizedString(@"Import", nil)]) {
		ExportCell *cell = (ExportCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (cell == nil) {
			cell = [[ExportCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
		}
		cell.backgroundColor = bgColor;
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
		
		cell.titleLabel.font = [UIFont fontWithName:kFontAwesomeFamilyName size:20.f];
		cell.titleLabel.text=[NSString stringWithFormat:@"%@ %@", [NSString fontAwesomeIconStringForEnum:FADownload], NSLocalizedString(@"Import", nil)];
		if([ProjectFunctions getUserDefaultValue:@"userName"].length>0)
			cell.titleLabel.textColor = textColor;
		
		if(gamesOnServer>gamesOnDevice)
			cell.titleLabel.textColor = [UIColor redColor];

		cell.gamesStoredLabel.text = [NSString stringWithFormat:@"Server Games: %d", gamesOnServer];
		cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
		
		return cell;
	}
	
	if(indexPath.section==1 && [[secondMenuArray stringAtIndex:(int)indexPath.row] isEqualToString:@"Sound"]) {
		SelectionCell *cell = (SelectionCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (cell == nil) {
			cell = [[SelectionCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
		}
		cell.backgroundColor = bgColor;
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
		
		cell.textLabel.font = [UIFont fontWithName:kFontAwesomeFamilyName size:20.f];
		cell.textLabel.text=[NSString stringWithFormat:@"%@ Sound", [NSString fontAwesomeIconStringForEnum:FAVolumeUp]];
        NSString *soundOn = [ProjectFunctions getUserDefaultValue:@"soundOn"];
        if([soundOn length]==0)
            soundOn = @"On";
		cell.selection.text = soundOn;
		
		return cell;
	}
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
	
	cell.accessoryType = UITableViewCellAccessoryNone;
 
	if(indexPath.section==0 && indexPath.row<3) {
		cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
	}

	if(indexPath.section==0) {
		NSArray *icons = [NSArray arrayWithObjects:
						  [NSString fontAwesomeIconStringForEnum:FADownload],
						  [NSString fontAwesomeIconStringForEnum:FAUpload],
						  [NSString fontAwesomeIconStringForEnum:FAtrash],
						  [NSString fontAwesomeIconStringForEnum:FAArrowDown],
						  [NSString fontAwesomeIconStringForEnum:FAArrowDown],
						  [NSString fontAwesomeIconStringForEnum:FAtrash],
						  [NSString fontAwesomeIconStringForEnum:FAEnvelope],
						  [NSString fontAwesomeIconStringForEnum:FAtrash],
						  [NSString fontAwesomeIconStringForEnum:FAGlobe],
						  nil];
		NSString *icon = [NSString fontAwesomeIconStringForEnum:FAQuestionCircle];
		if(icons.count>indexPath.row)
			icon = [icons objectAtIndex:indexPath.row];
		cell.textLabel.font = [UIFont fontWithName:kFontAwesomeFamilyName size:20.f];
		cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", icon, [menuArray objectAtIndex:indexPath.row]];
		
		if([[menuArray stringAtIndex:(int)indexPath.row] isEqualToString:NSLocalizedString(@"Delete", nil)] || [ProjectFunctions getUserDefaultValue:@"userName"])
			cell.textLabel.textColor = textColor;
		else
			cell.textLabel.textColor = [UIColor grayColor];
		
		if([[menuArray stringAtIndex:(int)indexPath.row] isEqualToString:NSLocalizedString(@"Cleanup", nil)])
			cell.textLabel.textColor = textColor;
		if(indexPath.row==0)
			cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
	}

	if(indexPath.section==1) {
		NSArray *icons = [NSArray arrayWithObjects:
						  [NSString fontAwesomeIconStringForEnum:FAWrench],
						  [NSString fontAwesomeIconStringForEnum:FAPlus],
						  [NSString fontAwesomeIconStringForEnum:FALock],
						  [NSString fontAwesomeIconStringForEnum:FAGlobe],
						  [NSString fontAwesomeIconStringForEnum:FAUser],
						  [NSString fontAwesomeIconStringForEnum:FAUsers],
						  [NSString fontAwesomeIconStringForEnum:FAMoney],
						  [NSString fontAwesomeIconStringForEnum:FAEnvelope],
						  [NSString fontAwesomeIconStringForEnum:FAPencil],
						  [NSString fontAwesomeIconStringForEnum:FAVolumeUp],
						  [NSString fontAwesomeIconStringForEnum:FAMobile],
						  [NSString fontAwesomeIconStringForEnum:FAStar],
						  [NSString fontAwesomeIconStringForEnum:FAPictureO],
						  [NSString fontAwesomeIconStringForEnum:FACutlery],
						  nil];
		
		NSString *icon = [NSString fontAwesomeIconStringForEnum:FAQuestionCircle];
		if(icons.count>indexPath.row)
			icon = [icons objectAtIndex:indexPath.row];
		cell.textLabel.textColor = textColor;
		cell.textLabel.font = [UIFont fontWithName:kFontAwesomeFamilyName size:20.f];
		cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", icon, [secondMenuArray objectAtIndex:indexPath.row]];
	}
	cell.backgroundColor = bgColor;
	cell.selectionStyle = UITableViewCellSelectionStyleGray;
    
    return cell;
}

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
	if(indexPath.row==0)
		[ProjectFunctions showAlertPopup:NSLocalizedString(@"Export", nil) message:@"Store your games on a server. \n\nNote: If you are trying to delete games that have already been saved on the server, you must first manually delete the games on each of your devices. Then click 'Clear All Server Data' and finally click 'Export Data' BEFORE importing."];
	if(indexPath.row==1)
		[ProjectFunctions showAlertPopup:@"Import Feature" message:@"Import games stored on the server."];
	if(indexPath.row==2)
		[ProjectFunctions showAlertPopup:NSLocalizedString(@"Clear", nil) message:@"This feature will clear all the games from the server without affecting games on your device."];
}

#pragma mark -
#pragma mark Table view delegate
-(void)ImportNewIncomeGame:(NSArray *)components gameType:(NSString *)gameType
{
	if([gameType isEqualToString:@"Cash"]) {
		[ProjectFunctions setUserDefaultValue:@"0|1|5|17|6|7|8|9|15|15|10|7|7|7|11" forKey:@"pjCashColumns"];
	} else {
		[ProjectFunctions setUserDefaultValue:@"0|1|5|17|6|7|8|9|15|15|10|7|7|17|11" forKey:@"pjTournamentColumns"];
	}
	[self ImportNewPJGame:components gameType:gameType];
}

-(void)ImportNewPJGame:(NSArray *)components gameType:(NSString *)gameType
{
	//--------------- Poker Journal Import --------------------------
	int gameColumn = 0;
	int stakesColumn = 0;
	int limitColumn = 0;
	int locationColumn = 0;
	int buyinColumn = 0;
	int cashoutColumn = 0;
//	int tipsColumn = 0;
	int tokesColumn = 0;
	int winningColumn = 0;
	int tournamentTypeColumn = 0;
	int notesColumn = 0;

	NSString *columnLine = [ProjectFunctions getUserDefaultValue:@"pjTournamentColumns"];
	if([gameType isEqualToString:@"Cash"])
		columnLine = [ProjectFunctions getUserDefaultValue:@"pjCashColumns"];
	
	NSArray *columns = [columnLine componentsSeparatedByString:@"|"];
	if([columns count]>14) {
		gameColumn = [[columns objectAtIndex:2] intValue];
		stakesColumn = [[columns objectAtIndex:3] intValue];
		limitColumn = [[columns objectAtIndex:4] intValue];
		locationColumn = [[columns objectAtIndex:5] intValue];
		buyinColumn = [[columns objectAtIndex:6] intValue];
		cashoutColumn = [[columns objectAtIndex:7] intValue];
//		tipsColumn = [[columns objectAtIndex:8] intValue];
		tokesColumn = [[columns objectAtIndex:9] intValue];
		winningColumn = [[columns objectAtIndex:10] intValue];
		tournamentTypeColumn = [[columns objectAtIndex:13] intValue];
		notesColumn = [[columns objectAtIndex:14] intValue];
	}
	if([gameType isEqualToString:@"Cash"] && [components count]<notesColumn)
		return; // BAD DATA!!
	
	
	NSString *tournamentType=@"";
	if(tournamentTypeColumn>0)
		tournamentType = [components objectAtIndex:tournamentTypeColumn];
	
    
    NSDate *startDate = [ProjectFunctions getDateInCorrectFormat:[components objectAtIndex:0]];
    NSDate *endDate = [ProjectFunctions getDateInCorrectFormat:[components objectAtIndex:1]];
    
	
	if([[components objectAtIndex:0] isEqualToString:[components objectAtIndex:1]])
		endDate = [startDate dateByAddingTimeInterval:60*60*3];
	NSString *startTimeStr = [startDate convertDateToStringWithFormat:nil];
	NSString *endTimeStr = [endDate convertDateToStringWithFormat:nil];
	int seconds = [endDate timeIntervalSinceDate:startDate];
	int minutes = seconds/60;
	float hours = (float)seconds/3600;
	int buyinAmount = [[components objectAtIndex:buyinColumn] intValue];
	int winnings = [[components objectAtIndex:winningColumn] intValue];
	int cashout = [[components objectAtIndex:cashoutColumn] intValue];
	int tokes = [[components objectAtIndex:tokesColumn] intValue];
	int tips =0; // food and drinks not recorded for Poker Income
	int breakMinutes=0;
	int spots=0;
	int finish=0;
	if([gameType isEqualToString:@"Tournament"]) {
		breakMinutes = [[components stringAtIndex:14] intValue]; // spots paid
		spots = [[components stringAtIndex:13] intValue]; // 
		finish = [[components stringAtIndex:15] intValue]; // 
		notesColumn = 20;
		NSLog(@"What the?!? %d %d %d", breakMinutes, spots, finish);
	}
	
	winnings += tips;
	
	int rebuyAmount = cashout-buyinAmount-winnings;
	if(rebuyAmount<0)
		rebuyAmount=0;
	
	NSString *numRebuys = @"0";
	if(rebuyAmount>0)
		numRebuys = @"1";
	
	NSString *hoursStr = [NSString stringWithFormat:@"%.1f", hours];
	NSString *year = [startDate convertDateToStringWithFormat:@"yyyy"];
	
	NSString *limitString = [components objectAtIndex:limitColumn];
	limitString = [ProjectFunctions scrubRefData:limitString context:self.managedObjectContext];
	if([limitString isEqualToString:@"No Limit"] || [limitString isEqualToString:@""])
		limitString = @"No-Limit";
	limitString = [ProjectFunctions scrubRefData:limitString context:self.managedObjectContext];
	
	NSString *stakes = [components objectAtIndex:stakesColumn];
	if([stakes isEqualToString:@""])
		stakes = @"$1/$3";
	stakes = [ProjectFunctions scrubRefData:stakes context:self.managedObjectContext];
	if([gameType isEqualToString:@"Tournament"])
		stakes = @"";
	

	NSString *gameName = [components objectAtIndex:gameColumn];
	if([gameName length]==0)
		gameName = @"Hold'em";
	if([gameName isEqualToString:@"Texas Hold'em"])
		gameName = @"Hold'em";
	if([gameName isEqualToString:@"Texas Holdem"])
		gameName = @"Hold'em";
	gameName = [ProjectFunctions scrubRefData:gameName context:self.managedObjectContext];
	
	NSString *location = [components objectAtIndex:locationColumn];
	if([location isEqualToString:@""])
		location = @"Casino";
	location = [ProjectFunctions scrubRefData:location context:self.managedObjectContext];
	
    NSString *notes = [components stringAtIndex:notesColumn];
    if([notes length]>500)
        notes = [notes substringToIndex:500];
    
	
	NSMutableArray *formDataArray = [[NSMutableArray alloc] init];
	[formDataArray addObject:[NSString stringWithFormat:@"%@",  startTimeStr]];	// startTime
	[formDataArray addObject:[NSString stringWithFormat:@"%@",  endTimeStr]]; // end time
	[formDataArray addObject:[NSString stringWithFormat:@"%@",  hoursStr]];
	[formDataArray addObject:[NSString stringWithFormat:@"%d",  buyinAmount]];
	[formDataArray addObject:[NSString stringWithFormat:@"%d",  rebuyAmount]];
	[formDataArray addObject:[NSString stringWithFormat:@"%d",  tips]]; //food drink
	[formDataArray addObject:[NSString stringWithFormat:@"%d",  cashout]];
	[formDataArray addObject:[NSString stringWithFormat:@"%d",  winnings]];
	[formDataArray addObject:[NSString stringWithFormat:@"%@ %@ %@",  gameName, stakes, limitString]]; // gameMode
	[formDataArray addObject:[NSString stringWithFormat:@"%@",  gameName]];
	[formDataArray addObject:[NSString stringWithFormat:@"%@",  stakes]];
	[formDataArray addObject:[NSString stringWithFormat:@"%@",  limitString]];
	[formDataArray addObject:[NSString stringWithFormat:@"%@",  location]];
	[formDataArray addObject:[NSString stringWithFormat:@"%@", @"Default"]]; // bankroll
	[formDataArray addObject:[NSString stringWithFormat:@"%@",  numRebuys]];
	[formDataArray addObject:notes];
	[formDataArray addObject:[NSString stringWithFormat:@"%d",  breakMinutes]];
	[formDataArray addObject:[NSString stringWithFormat:@"%d",  tokes]];
	[formDataArray addObject:[NSString stringWithFormat:@"%d",  minutes]];
	[formDataArray addObject:[NSString stringWithFormat:@"%d",  [year intValue]]];
	[formDataArray addObject:[NSString stringWithFormat:@"%@",  gameType]];
	[formDataArray addObject:[NSString stringWithFormat:@"%@", @"Completed"]];
	[formDataArray addObject:[NSString stringWithFormat:@"%@",  tournamentType]];
	[formDataArray addObject:@"0"]; // user_id
	[formDataArray addObject:[ProjectFunctions getWeekDayFromDate:startDate]];
	[formDataArray addObject:[ProjectFunctions getMonthFromDate:startDate]];
	[formDataArray addObject:[ProjectFunctions getDayTimeFromDate:startDate]];
	[formDataArray addObject:@""]; // attrib01
	[formDataArray addObject:@""]; // attrib02
	[formDataArray addObject:[NSString stringWithFormat:@"%d",  spots]];
	[formDataArray addObject:[NSString stringWithFormat:@"%d",  finish]];

	NSManagedObject *mo = [NSEntityDescription insertNewObjectForEntityForName:@"GAME" inManagedObjectContext:self.managedObjectContext];
	[ProjectFunctions updateGameInDatabase:self.managedObjectContext mo:mo valueList:formDataArray];
	[ProjectFunctions scrubDataForObj:mo context:self.managedObjectContext];
}

-(BOOL)checkForDupe:(NSDate *)startTime buyInAmount:(int)buyInAmount
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"user_id = 0 AND buyInAmount = %d AND startTime = %@", buyInAmount, startTime];
	NSArray *games = [CoreDataLib selectRowsFromEntity:@"GAME" predicate:predicate sortColumn:@"startTime" mOC:self.managedObjectContext ascendingFlg:YES];
	if([games count]>0) {
//		NSManagedObject *mo = [games objectAtIndex:0];
//		NSLog(@"Game exists: %@ %d!", [mo valueForKey:@"name"], [[mo valueForKey:@"game_id"] intValue]);
		return YES;
	} else
		return NO;
}

-(void)savePJcollumns:(NSArray *)collumns type:(NSString *)type
{
	int startColumn = 0;
	int endColumn = 0;
	int gameColumn = 0;
	int stakesColumn = 0;
	int limitColumn = 0;
	int locationColumn = 0;
	int buyinColumn = 0;
	int cashoutColumn = 0;
	int tipsColumn = 0;
	int tokesColumn = 0;
	int winningColumn = 0;
	int notesColumn = 0;
	int rebuyCountColumn=0;
	int rebuyAmountColumn=0;
	int tournamentTypeColumn = 0;
	

		
		int i=0;
		for (NSString *name in collumns) {
			if([name isEqualToString:@"Date Start"])
				startColumn=i;
			if([name isEqualToString:@"Date End"])
				endColumn=i;
			if([name isEqualToString:@"Game"])
				gameColumn=i;
			if([name isEqualToString:@"Stakes"])
				stakesColumn=i;
			if([name isEqualToString:@"Limit Type"])
				limitColumn=i;
			if([name isEqualToString:@"Location"])
				locationColumn=i;
			if([name isEqualToString:@"Total Buyin"]) {
				buyinColumn=i;
				[ProjectFunctions setUserDefaultValue:[NSString stringWithFormat:@"%d", i] forKey:@"PJBuyin"];
			}
			if([name isEqualToString:@"Cashed Out"])
				cashoutColumn=i;
			if([name isEqualToString:@"Tips"])
				tipsColumn=i;
			if([name isEqualToString:@"Tokes"])
				tokesColumn=i;
			if([name isEqualToString:@"Net Profit"])
				winningColumn=i;
			if([name isEqualToString:@"Note"])
				notesColumn=i;
			if([name isEqualToString:@"Tournament Type"])
				tournamentTypeColumn=i;
			if([name isEqualToString:@"Rebuy Count"])
				rebuyCountColumn=i;
			if([name isEqualToString:@"Total Rebuys"])
				rebuyAmountColumn=i;
			if([name isEqualToString:@"Amount Won"])
				cashoutColumn=i;
			i++;
		}
		NSString *final = [NSString stringWithFormat:@"%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d", startColumn,
						   endColumn, gameColumn, stakesColumn, limitColumn, locationColumn, buyinColumn, cashoutColumn,
						   tipsColumn, tokesColumn, winningColumn, rebuyCountColumn, rebuyAmountColumn,tournamentTypeColumn, notesColumn];
	if([type isEqualToString:@"Cash"])
		[ProjectFunctions setUserDefaultValue:final forKey:@"pjCashColumns"];
	else		
		[ProjectFunctions setUserDefaultValue:final forKey:@"pjTournamentColumns"];
	
}

-(void)ImportPokerIncomeData
{
	@autoreleasepool {
	
		NSString *Username = [ProjectFunctions getUserDefaultValue:@"userName"];
		NSString *Password = [ProjectFunctions getUserDefaultValue:@"password"];
		
		NSArray *nameList = [NSArray arrayWithObjects:@"Username", @"Password", nil];
		NSArray *valueList = [NSArray arrayWithObjects:Username, Password, nil];
		NSString *webAddr = @"http://www.appdigity.com/poker/RetrievePokerIncome.php";
		NSString *responseStr = [WebServicesFunctions getResponseFromServerUsingPost:webAddr fieldList:nameList valueList:valueList];
		
    
    
		if([WebServicesFunctions validateStandardResponse:responseStr delegate:nil]) {
			NSArray *contents = [responseStr componentsSeparatedByString:@"<br>"];
			self.totalImportedLines = (int)[contents count];
			self.numImportedLinesRead=0;
			NSString *gameType = nil;
			int gameCount=0;
			int dupGameCount=0;
			for(NSString *line in contents) {
//			NSLog(@"+++%@", line);
				self.numImportedLinesRead++;
				if([line length]>9 && [[line substringToIndex:10] isEqualToString:@"Cash Games"])
					gameType = @"Cash";
				if([line length]>7 && [[line substringToIndex:8] isEqualToString:@"Tourneys"])
					gameType = @"Tournament";
				
//			NSLog(@"+++gameType %@", gameType);
				if([gameType length]>0) {
					
					NSArray *components = [line componentsSeparatedByString:@"\t"];
					if([[components stringAtIndex:0] isEqualToString:NSLocalizedString(@"startTime", nil)]) {
//					[self savePJcollumns:components:gameType];
					}
					if([components count]>10) {
//					int buyInCol = [[ProjectFunctions getUserDefaultValue:@"PJBuyin"] intValue];
						int buyIn = [[components stringAtIndex:8] intValue];
//						int cashout = [[components stringAtIndex:11] intValue];
//					NSLog(@"buyin %d", buyIn);
						if(buyIn>0) {
							NSDate *startTime = [ProjectFunctions getDateInCorrectFormat:[components stringAtIndex:0]];
							if([self checkForDupe:startTime buyInAmount:buyIn])
								dupGameCount++;
							else {
//							[self ImportNewPJGame:components:gameType];
								[self ImportNewIncomeGame:components gameType:gameType];
								gameCount++;
								self.totalNumGamesImported++;
							}
						}
					}
				}
			} // for
			[ProjectFunctions updateGamesOnDevice:self.managedObjectContext];
			[self.mainTableView reloadData];
			
			if(gameCount>0)
				[ProjectFunctions showAlertPopup:@"Success!" message:[NSString stringWithFormat:@"%d games imported.", gameCount]];
			else if(dupGameCount>0)
				[ProjectFunctions showAlertPopup:@"No Games Found" message:[NSString stringWithFormat:@"No new games found. %d duplicate games (not inserted).", dupGameCount]];
			else 
				[ProjectFunctions showAlertPopup:@"No Games Found" message:@"Sorry, no new games found. You must upload your file first at pokertrackpro.com/import"];
		}
		
    [self completeThreadedjob];

	}
}

-(void)updateProgressBar
{
    NSString *type = (importType<=3)?@"Importing":@"Exporting";
    float progress=0;
    if(totalImportedLines>0)
        progress = (float)numImportedLinesRead/totalImportedLines;

    int percent = 100*progress;

    NSString *progressLabelText = @"";
    if(importType==4)
        progressLabelText = self.messageString;
    else
        progressLabelText = [NSString stringWithFormat:@"%@ %d of %d (%d%%)", type, numImportedLinesRead, totalImportedLines, percent];
	
	[importProgressLabel performSelectorOnMainThread:@selector(setText: ) withObject:progressLabelText waitUntilDone:YES];
	[self.activityLabel performSelectorOnMainThread:@selector(setText: ) withObject:self.activityLabelString waitUntilDone:YES];

    dispatch_async(dispatch_get_main_queue(), ^{
        [progressView setProgress:progress];
    }
                   );
}

-(void)updateProgressView
{
 	@autoreleasepool {
  
                [self updateProgressBar];
                
    [NSThread sleepForTimeInterval:.4];
    if(importInProgress)
                [self performSelectorInBackground:@selector(updateProgressView) withObject:nil];

	}
}

-(void)ImportPokerJournalDataMainThread
{
 	NSString *Username = [ProjectFunctions getUserDefaultValue:@"userName"];
	NSString *Password = [ProjectFunctions getUserDefaultValue:@"password"];
	
	NSArray *nameList = [NSArray arrayWithObjects:@"Username", @"Password", nil];
	NSArray *valueList = [NSArray arrayWithObjects:Username, Password, nil];
	NSString *webAddr = @"http://www.appdigity.com/poker/RetrievePokerJournal.php";
	NSString *responseStr = [WebServicesFunctions getResponseFromServerUsingPost:webAddr fieldList:nameList valueList:valueList];
//    NSLog(@"%@", responseStr);
	if([WebServicesFunctions validateStandardResponse:responseStr delegate:nil]) {
		NSArray *contents = [responseStr componentsSeparatedByString:@"<br>"];
		self.totalImportedLines = (int)[contents count];
		self.numImportedLinesRead=0;
		NSString *gameType = nil;
		int gameCount=0;
		int dupGameCount=0;
		for(__strong NSString *line in contents) {
			self.numImportedLinesRead++;
			if([line length]>20 && [[line substringToIndex:14] isEqualToString:@"----CASH GAMES"])
				gameType = @"Cash";
			if([line length]>20 && [[line substringToIndex:15] isEqualToString:@"----TOURNAMENTS"])
				gameType = @"Tournament";
			
			line = [line stringByReplacingOccurrencesOfString:@"[comma]" withString:@","];
			
			if([gameType length]>0) {
				
				NSArray *components = [line componentsSeparatedByString:@","];
				if([[components objectAtIndex:0] isEqualToString:@"Date Start"]) {
					[self savePJcollumns:components type:gameType];
				}
				if([components count]>16) {
 					int buyInCol = [[ProjectFunctions getUserDefaultValue:@"PJBuyin"] intValue];
					int buyIn = [[components objectAtIndex:buyInCol] intValue];
					if(buyIn>0) {
 						NSDate *startTime = [ProjectFunctions getDateInCorrectFormat:[components objectAtIndex:kstartDate]];
						if([self checkForDupe:startTime buyInAmount:buyIn])
							dupGameCount++;
						else {
                            NSLog(@"%@", line);
							[self ImportNewPJGame:components gameType:gameType];
							gameCount++;
							self.totalNumGamesImported++;
						}
					}
				}
			}
		} // for
		[ProjectFunctions updateGamesOnDevice:self.managedObjectContext];
		[self.mainTableView reloadData];
		if(gameCount>0)
			[ProjectFunctions showAlertPopup:@"Success!" message:[NSString stringWithFormat:@"%d games imported.", gameCount]];
		else if(dupGameCount>0)
			[ProjectFunctions showAlertPopup:@"No Games Found" message:[NSString stringWithFormat:@"No new games found. %d duplicate games (not inserted).", dupGameCount]];
		else
			[ProjectFunctions showAlertPopup:@"No Games Found" message:@"Sorry, no new games found. You must upload your file first at pokertrackpro.com/import"];
	}
    
}

-(void)ImportPokerJournalData
{
	@autoreleasepool {
	
                [self ImportPokerJournalDataMainThread];
                [self completeThreadedjob];

	}
}

-(NSString *)makeThisWebSafe:(NSString *)value {
	if([value length]==0)
		return value;
	
	value = [value stringByReplacingOccurrencesOfString:@"|" withString:@"[pipe]"];
	value = [value stringByReplacingOccurrencesOfString:@"&" withString:@"and"];
	value = [value stringByReplacingOccurrencesOfString:@"<" withString:@"[lt]"];
	value = [value stringByReplacingOccurrencesOfString:@">" withString:@"[gt]"];
	value = [value stringByReplacingOccurrencesOfString:@"\"" withString:@""];
	value = [value stringByReplacingOccurrencesOfString:@"'" withString:@""];
	value = [value stringByReplacingOccurrencesOfString:@"`" withString:@""];
	return value;
}

-(NSMutableString *)getDataForTheseRecords:(NSArray *)items keyList:(NSArray *)keyList isGames:(BOOL)isGames
{
	NSMutableString *page = [NSMutableString stringWithCapacity:100000];

	for(NSManagedObject *mo in items) {
        if(isGames)
            self.numImportedLinesRead++;
		NSMutableString *line = [NSMutableString stringWithCapacity:100000];
		for(NSString *key in keyList) {
			NSString *value = [mo valueForKey:key];
			if([key isEqualToString:@"startTime"] || [key isEqualToString:@"endTime"] || [key isEqualToString:@"gameDate"] || [key isEqualToString:@"created"]) {
				value = [[mo valueForKey:key] convertDateToStringWithFormat:nil];
			}
			value = [self makeThisWebSafe:[NSString stringWithFormat:@"%@", value]];
			[line appendFormat:@"%@%@", value, kFieldSeparator];
		}
		NSString *finalLine = [line stringByReplacingOccurrencesOfString:@"\n" withString:@"[nl]"];
		[page appendString:finalLine];
		[page appendString:@"\n"];
	} // <-- for
	return page;
}

-(void)exportPlayerTrackPics
{
	NSMutableString *data = [NSMutableString stringWithCapacity:1000000];
	for(int i=1; i<=10; i++) {
		NSString *jpgPath = [ProjectFunctions getPicPath:i];
		
		NSFileHandle *fh = [NSFileHandle fileHandleForReadingAtPath:jpgPath];
		if(fh!=nil) {
			UIImage *img = [UIImage imageWithContentsOfFile:jpgPath];
			NSString *imgStr = [ProjectFunctions convertImgToBase64String:img height:100];
            [data appendString:[NSString stringWithFormat:@"%d|%@:", i, imgStr]];
//			[data appendFormat:[NSString stringWithFormat:@"%d|%@:", i, imgStr]];
		}
		[fh closeFile];
	}
	NSArray *nameList = [NSArray arrayWithObjects:@"Username", @"Password", @"data", nil];
	NSArray *valueList = [NSArray arrayWithObjects:[ProjectFunctions getUserDefaultValue:@"userName"], [ProjectFunctions getUserDefaultValue:@"password"], data, nil];
	NSString *webAddr = @"http://www.appdigity.com/poker/pokerExportPlayerPics.php";
	[WebServicesFunctions getResponseFromServerUsingPost:webAddr fieldList:nameList valueList:valueList];
}

-(NSString *)packageNonGameData {
	self.messageString = @"Packaging Data...";
	NSMutableString *data = [[NSMutableString alloc] init];
	NSArray *entityList = [NSArray arrayWithObjects:@"BIGHAND", @"FILTER", @"FRIEND", @"SEARCH", @"EXTRA", @"BANKROLL", @"EXTRA2", nil];
	for(NSString *entityName in entityList) {
		[data appendString:[NSString stringWithFormat:@"-----%@-----\n", entityName]];
		NSArray *keyList = [ProjectFunctions getColumnListForEntity:entityName type:@"column"];
		NSPredicate *predicate = nil;
		self.messageString = [NSString stringWithFormat:@"Packaging data: %@", entityName];
//		BOOL isGames=NO;
//		if([entityName isEqualToString:@"GAME"]) {
//			predicate = [NSPredicate predicateWithFormat:@"user_id = %d", 0];
//			isGames=YES;
//		}
		NSArray *items = [CoreDataLib selectRowsFromEntity:entityName predicate:predicate sortColumn:nil mOC:managedObjectContext ascendingFlg:YES];
		
		if([@"BIGHAND" isEqualToString:entityName]) {
			//remove dupes
//			NSMutableArray *bigHands = [[NSMutableArray alloc] init];
//			NSMutableArray *loadedbigHands = [[NSMutableArray alloc] init];
//			[bigHands addObject:[items objectAtIndex:0]];
		}
//		if(isGames)
//			self.totalImportedLines = (int)[items count];
		NSString *line = [self getDataForTheseRecords:items keyList:keyList isGames:NO];
		[data appendString:line];
	}
	[data appendString:[NSString stringWithFormat:@"-----BANKROLL_STUFF-----\n%@|%@|%@|\n",
						[ProjectFunctions getUserDefaultValue:@"defaultBankroll"],
						[ProjectFunctions getUserDefaultValue:@"bankrollDefault"],
						[ProjectFunctions getUserDefaultValue:@"bankrollSwitch"]
						]];
	
	return data;
}

-(NSArray *)getAllGames {
	NSString *entityName = @"GAME";
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"user_id = %d", 0];
	NSArray *items = [CoreDataLib selectRowsFromEntity:entityName predicate:predicate sortColumn:nil mOC:managedObjectContext ascendingFlg:YES];
	return items;
}

-(NSString *)packageGameDataGames:(NSArray *)items {
	self.activityLabelString = @"Packaging Games...";
	NSMutableString *data = [[NSMutableString alloc] init];
	NSString *entityName = @"GAME";
	NSArray *keyList = [ProjectFunctions getColumnListForEntity:entityName type:@"column"];
	[data appendString:[NSString stringWithFormat:@"-----%@-----\n", entityName]];
	NSString *line = [self getDataForTheseRecords:items keyList:keyList isGames:NO];
	[data appendString:line];
	return data;
}

-(BOOL)exportPTPData:(NSString *)data GameDataFlg:(BOOL)gameDataFlg blockNum:(NSString *)blockNum {
	NSArray *nameList = [NSArray arrayWithObjects:@"Username", @"Password", @"data", @"numGames", @"blockNum", nil];
	NSArray *valueList = [NSArray arrayWithObjects:[ProjectFunctions getUserDefaultValue:@"userName"], [ProjectFunctions getUserDefaultValue:@"password"], data, [ProjectFunctions getUserDefaultValue:@"gamesOnDevice"], blockNum, nil];
	NSString *webAddr = @"http://www.appdigity.com/poker/ExportData.php";
	if(gameDataFlg)
		webAddr = @"http://www.appdigity.com/poker/ExportData2.php";
	NSString *responseStr = [WebServicesFunctions getResponseFromServerUsingPost:webAddr fieldList:nameList valueList:valueList];
	if([@"Success" isEqualToString:responseStr])
		return YES;
	else {
		if([responseStr length]>100)
			responseStr = @"Possible server issues. Please try again later.";
		if([responseStr length]<3)
			responseStr = @"No response received.";
		[ProjectFunctions showAlertPopup:@"Error on Export" message:responseStr];
		return NO;
	}
}

-(void)ExportPockerTrackData
{
	@autoreleasepool {
        self.importType=4;
        self.numImportedLinesRead=0;
        self.totalImportedLines=0;


		NSString *data = [self packageNonGameData];
		[NSThread sleepForTimeInterval:1];
		self.messageString = @"Sending data...";
		NSLog(@"%@", data);
		BOOL successFlg = [self exportPTPData:data GameDataFlg:NO blockNum:@"0"];
		if(successFlg) {
			NSMutableArray *games = [NSMutableArray arrayWithArray:[self getAllGames]];
			float maxGames = 1000;
			NSMutableArray *gamesForBlock = [[NSMutableArray alloc] init];
			int totalBlocks = ceil((float)games.count/maxGames);
			for(int i=1; i<=totalBlocks; i++) {
				NSLog(@"uploading block %d of %d", i, totalBlocks);
				[gamesForBlock removeAllObjects];
				for(int x=0; x<maxGames; x++) {
					if(games.count>0) {
						NSManagedObject *mo = [games objectAtIndex:0];
						[games removeObjectAtIndex:0];
						[gamesForBlock addObject:mo];
					}
				}
				NSString *data = [self packageGameDataGames:gamesForBlock];
				successFlg = [self exportPTPData:data GameDataFlg:YES blockNum:[NSString stringWithFormat:@"%d", i]];
			}
		}
		
		self.activityLabelString = @"Exporting Player pics...";
		[self exportPlayerTrackPics];
		self.activityLabelString = @"Done";
		
		if(successFlg) {
			[ProjectFunctions updateGamesOnServer:self.managedObjectContext];
			[self.mainTableView reloadData];
			
			if(gSelectedRow==0)
				[ProjectFunctions showAlertPopup:@"Device Synced" message:@"All data has been synced"];
			else
				[ProjectFunctions showAlertPopup:@"Database Exported" message:@"All data has been exported"];
		}
		
		[self completeThreadedjob];
		[ProjectFunctions updateGamesOnDevice:self.managedObjectContext];
		[self.mainTableView reloadData];
	}
}

-(void)ImportNewPTGame:(NSArray *)components
{
	if([components count]>13) {
		NSManagedObject *mo = [NSEntityDescription insertNewObjectForEntityForName:@"GAME" inManagedObjectContext:managedObjectContext];
		[ProjectFunctions updateGameInDatabase:managedObjectContext mo:mo valueList:components];
		[ProjectFunctions scrubDataForObj:mo context:self.managedObjectContext];
	}
}



-(int)LoadGames:(NSArray *)components
{
	int numRecords=0;
	if([components count]>20) {
		int buyIn = [[components objectAtIndex:3] intValue];
		int cashOut = [[components objectAtIndex:6] intValue];
		if(buyIn>0 || cashOut>0) {
			NSString *istartTime = [components objectAtIndex:0];
			NSDate *ist = [istartTime convertStringToDateFinalSolution];
			if(![self checkForDupe:ist buyInAmount:buyIn]) {
				numRecords++;
				NSLog(@"\t\timporting: $%d %@ %@", buyIn, istartTime, ist);
				[self ImportNewPTGame:components];
			}
		} else
			NSLog(@"\t\t-----BUYIN ZERO------");
		
	} // <-- count
	return numRecords;
}

-(BOOL)checkEntityForDupe:(NSString *)EntityName key1:(NSString *)key1 value1:(NSString *)value1 key2:(NSString *)key2 value2:(NSString *)value2
{
	NSPredicate *predicate = nil;
	if([EntityName isEqualToString:@"GAME"])
		predicate = [NSPredicate predicateWithFormat:@"user_id = %d", 0];
	NSArray *items = [CoreDataLib selectRowsFromEntity:EntityName predicate:predicate sortColumn:nil mOC:managedObjectContext ascendingFlg:YES];
	
//	NSLog(@"checking dupe: %@ %@ %@ %@ %d", key1, value1, key2, value2, (int)items.count);
	for(NSManagedObject *mo in items) {
		NSString *dataItem1 = [mo valueForKey:key1];
		NSString *dataItem2 = [mo valueForKey:key2];
		
		if([key1 isEqualToString:@"gameDate"]) {
			dataItem1 = [[mo valueForKey:key1] convertDateToStringWithFormat:nil];
		}
		if([@"BIGHAND" isEqualToString:EntityName] && [dataItem2 isEqualToString:value2]) {
			NSLog(@"BIGHAND Dupe found!!!!! [%@] [%@]", dataItem1, value1);
			return YES;
		}
		
		if([dataItem1 isEqualToString:value1] && [dataItem2 isEqualToString:value2])
			return YES;
	}
	
	return NO;
}

-(void)ImportNewPTEntity:(NSString *)entityName components:(NSArray *)components {
	NSManagedObject *mo = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:managedObjectContext];
	[ProjectFunctions updateEntityInDatabase:managedObjectContext mo:mo valueList:components entityName:entityName];
}

-(void)LoadPTDataForEntity:(NSString *)entityName components:(NSArray *)components field1:(NSString *)field1 loc1:(int)loc1 field2:(NSString *)field2 loc2:(int)loc2
{
	if([components count]>loc1 && [components count]>loc2) {
		NSString *value1 = [components objectAtIndex:loc1];
		NSString *value2 = [components objectAtIndex:loc2];
		if([field1 isEqualToString:@"gameDate"]) {
			NSDate *tempDate = [value1 convertStringToDateFinalSolution];
			value1 = [tempDate convertDateToStringWithFormat:nil];
		}
		if(![self checkEntityForDupe:entityName key1:field1 value1:value1 key2:field2 value2:value2])
			[self ImportNewPTEntity:entityName components:components];
	} // <-- count
}

-(void)ImportPlayerPics
{
	self.messageString = @"Importing Player pics...";
	NSArray *nameList = [NSArray arrayWithObjects:@"Username", @"Password", nil];
	NSArray *valueList = [NSArray arrayWithObjects:[ProjectFunctions getUserDefaultValue:@"userName"], [ProjectFunctions getUserDefaultValue:@"password"], nil];
	NSString *webAddr = @"http://www.appdigity.com/poker/pokerImportPlayerPics.php";
	NSString *responseStr = [WebServicesFunctions getResponseFromServerUsingPost:webAddr fieldList:nameList valueList:valueList];
	NSArray *pics = [responseStr componentsSeparatedByString:@":"];
	for (NSString *pic in pics) {
		NSArray *items = [pic componentsSeparatedByString:@"|"];
		int user_id = [[items stringAtIndex:0] intValue];
		NSString *imgData = [items stringAtIndex:1];
		UIImage *newImg = [ProjectFunctions convertBase64StringToImage:imgData];
		NSString *jpgPath = [ProjectFunctions getPicPath:user_id];
		[UIImageJPEGRepresentation(newImg, 1.0) writeToFile:jpgPath atomically:YES];
	}
}

-(int)newImportForBlockNum:(int)blockNum {
	self.activityLabelString = [NSString stringWithFormat:@"Importing game block: %d", blockNum];
	NSArray *nameList = [NSArray arrayWithObjects:@"Username", @"Password", @"blockNum", nil];
	NSArray *valueList = [NSArray arrayWithObjects:[ProjectFunctions getUserDefaultValue:@"userName"], [ProjectFunctions getUserDefaultValue:@"password"], [NSString stringWithFormat:@"%d", blockNum], nil];
	NSString *webAddr = @"http://www.appdigity.com/poker/ImportData2.php";
	NSString *contents = [WebServicesFunctions getResponseFromServerUsingPost:webAddr fieldList:nameList valueList:valueList];
	NSLog(@"---------------");
	NSLog(@"%@", contents);
	NSArray *lines = [contents componentsSeparatedByString:@"<br>"];
	NSLog(@"blockNum: %d (%d lines)", blockNum, (int)lines.count);
	self.totalImportedLines=(int)[lines count];
	self.numImportedLinesRead=0;
	int numRows=0;
	NSString *type = @"";
	for(__strong NSString *line in lines) {
		self.numImportedLinesRead++;
		if([line length]>4 && [[line substringToIndex:5] isEqualToString:@"-----"]) {
			type = line;
			NSLog(@"Loading: %@", type);
		}
		line = [line stringByReplacingOccurrencesOfString:@"[nl]" withString:@"\n"];
		NSArray *components = [line componentsSeparatedByString:kFieldSeparator];
		if([type isEqualToString:@"-----GAME-----"]) {
//			NSLog(@"+++[%d] %@", self.numImportedLinesRead, [components objectAtIndex:0]);
			int newGame = [self LoadGames:components];
			numRows+=newGame;
		}
	}
	return (int)lines.count-2;
}

-(void)ImportPokerTrackData
{
	@autoreleasepool {
    
        self.importType=3;

		self.messageString = @"Importing data";
	NSArray *nameList = [NSArray arrayWithObjects:@"Username", @"Password", nil];
	NSArray *valueList = [NSArray arrayWithObjects:[ProjectFunctions getUserDefaultValue:@"userName"], [ProjectFunctions getUserDefaultValue:@"password"], nil];
	NSString *webAddr = @"http://www.appdigity.com/poker/ImportData.php";
	NSString *contents = [WebServicesFunctions getResponseFromServerUsingPost:webAddr fieldList:nameList valueList:valueList];
	NSArray *lines = [contents componentsSeparatedByString:@"<br>"];
        self.totalImportedLines=(int)[lines count];
        self.numImportedLinesRead=0;
	int numRows=0;
	NSString *type = @"";
	for(__strong NSString *line in lines) {
            self.numImportedLinesRead++;
		if([line length]>4 && [[line substringToIndex:5] isEqualToString:@"-----"]) {
			type = line;
			NSLog(@"Loading: %@", type);
		}
		line = [line stringByReplacingOccurrencesOfString:@"[nl]" withString:@"\n"];
//		NSLog(@"line: %@", line);
		NSArray *components = [line componentsSeparatedByString:kFieldSeparator];
		if([type isEqualToString:@"-----GAME-----"]) {
//			NSLog(@"+++[%d] %@", self.numImportedLinesRead, [components objectAtIndex:0]);
			int newGame = [self LoadGames:components];
			numRows+=newGame;
		}
		if([type isEqualToString:@"-----BIGHAND-----"])
			[self LoadPTDataForEntity:@"BIGHAND" components:components field1:@"gameDate" loc1:1 field2:@"name" loc2:13];
		if([type isEqualToString:@"-----FILTER-----"])
			[self LoadPTDataForEntity:@"FILTER" components:components field1:@"name" loc1:9 field2:@"tournamentType" loc2:7];
		if([type isEqualToString:@"-----EXTRA-----"])
			[self LoadPTDataForEntity:@"EXTRA" components:components field1:@"name" loc1:1 field2:@"type" loc2:0];
        
            
		if([type isEqualToString:@"-----BANKROLL-----"])
			[self LoadPTDataForEntity:@"BANKROLL" components:components field1:@"name" loc1:0 field2:@"name" loc2:0];
		if([type isEqualToString:@"-----EXTRA2-----"])
			[self LoadPTDataForEntity:@"EXTRA2" components:components field1:@"name" loc1:1 field2:@"type" loc2:0];
		if([type isEqualToString:@"-----BANKROLL_STUFF-----"]) {
			NSArray *components = [line componentsSeparatedByString:@"|"];
			if(components.count>2) {
				[ProjectFunctions setUserDefaultValue:[components objectAtIndex:0] forKey:@"defaultBankroll"];
				[ProjectFunctions setUserDefaultValue:[components objectAtIndex:1] forKey:@"bankrollDefault"];
				NSString *switchVal = [@"Y" isEqualToString:[components objectAtIndex:2]]?@"Y":@"";
				[ProjectFunctions setUserDefaultValue:switchVal forKey:@"bankrollSwitch"];
			}
		}
			
            
            
	} //<-- for
		
		
		NSLog(@"%d games loaded", numRows);
		
		int numGames = 11;
		int blockNum=1;
		while (numGames>10) {
			numGames = [self newImportForBlockNum:blockNum];
			NSLog(@"Importing games for block: %d (%d)", blockNum, numGames);
			numRows+=numGames;
			blockNum++;
		}
		[self ImportPlayerPics];
		[ProjectFunctions updateGamesOnDevice:self.managedObjectContext];
		int numGamesServer2 = [[ProjectFunctions getUserDefaultValue:@"numGamesServer2"] intValue];
		[ProjectFunctions setUserDefaultValue:[NSString stringWithFormat:@"%d", numGamesServer2] forKey:@"gamesLastImport"];
		[self.mainTableView reloadData];
		
		if(gSelectedRow==0) {
			[self executeThreadedJob:@selector(ExportPockerTrackData)];
		} else {
			if(numRows>0)
				[ProjectFunctions showAlertPopup:@"Database Imported" message:[NSString stringWithFormat:@"%d games have been imported.", numRows]];
			else
				[ProjectFunctions showAlertPopup:@"Import Completed" message:@"No new games found."];
			
			[self completeThreadedjob];
		}
		
	}
}

-(int)deleteItems:(NSArray *)items
{
	int i=0;
	for(NSManagedObject *mo in items) {
		i++;
		[managedObjectContext deleteObject:mo];
		[managedObjectContext save:nil];
	}
	return i;
}	

-(void)poolDrainingFunction:(UIActivityIndicatorView *)activityInd
{
}




- (void)executeThreadedJob:(SEL)aSelector
{
	[activityIndicator startAnimating];
	self.activityBG.alpha=.5;
	self.activityPopup.alpha=1;
	self.activityLabel.alpha=1;
	self.progressView.alpha=1;
    self.importProgressLabel.alpha=1;
	self.gamesImportedLabel.alpha=1;
	self.importInProgress=YES;
    [self performSelectorInBackground:@selector(updateProgressView) withObject:nil];
	[self performSelectorInBackground:aSelector withObject:nil];
}

- (void)completeThreadedjob
{
	[activityIndicator stopAnimating];
	self.activityBG.alpha=0;
	self.activityPopup.alpha=0;
	self.activityLabel.alpha=0;
	self.progressView.alpha=0;
    self.importProgressLabel.alpha=0;
	self.gamesImportedLabel.alpha=0;
	self.importInProgress=NO;
	[(MainMenuVC *)callBackViewController calculateStats];
}

-(void)clearServerData
{
	@autoreleasepool {
		NSString *Username = [ProjectFunctions getUserDefaultValue:@"userName"];
		NSString *Password = [ProjectFunctions getUserDefaultValue:@"password"];
		
		NSArray *nameList = [NSArray arrayWithObjects:@"Username", @"Password", nil];
		NSArray *valueList = [NSArray arrayWithObjects:Username, Password, nil];
		NSString *webAddr = @"http://www.appdigity.com/poker/clearServerData.php";
		NSString *responseStr = [WebServicesFunctions getResponseFromServerUsingPost:webAddr fieldList:nameList valueList:valueList];
		
		if([WebServicesFunctions validateStandardResponse:responseStr delegate:nil]) {
			[ProjectFunctions setUserDefaultValue:@"0" forKey:@"gamesOnServer"];
			[self.mainTableView reloadData];
			[ProjectFunctions showAlertPopup:@"Success" message:@"Server games have been deleted."];
		}
		
		[self completeThreadedjob];
		
	}
}


-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if(buttonIndex==alertView.cancelButtonIndex)
		return; // cancel
 
    if(alertView.tag==0) // Sync Devices
		[self executeThreadedJob:@selector(ImportPokerTrackData)];

	if(alertView.tag==kExportData) // Export Data
		[self executeThreadedJob:@selector(ExportPockerTrackData)];
	if(alertView.tag==kImportData) // Import Data
		[self executeThreadedJob:@selector(ImportPokerTrackData)];
	
	if(alertView.tag==kImportPokerJounralData) { // Import Poker Journal Data
		[self executeThreadedJob:@selector(ImportPokerJournalData)];
	}
	if(alertView.tag==kClearServerData) { // kClearServerData
		[self executeThreadedJob:@selector(clearServerData)];
	}
	if(alertView.tag==kLogout) {
		[ProjectFunctions setUserDefaultValue:nil forKey:@"emailAddress"];
		[ProjectFunctions setUserDefaultValue:nil forKey:@"userName"];
		[ProjectFunctions setUserDefaultValue:nil forKey:@"firstName"];
		[ProjectFunctions setUserDefaultValue:nil forKey:@"password"];
		[self.navigationController popToViewController:[self.navigationController.viewControllers objectAtIndex:1] animated:YES];
	}
	
	
	
	if(alertView.tag==kDeleteAllData) { // Delete All Data
		[self deleteItems:[CoreDataLib selectRowsFromEntity:@"BIGHAND" predicate:nil sortColumn:@"gameDate" mOC:managedObjectContext ascendingFlg:YES]];
		[self deleteItems:[CoreDataLib selectRowsFromEntity:@"FILTER" predicate:nil sortColumn:@"button" mOC:managedObjectContext ascendingFlg:YES]];
		[self deleteItems:[CoreDataLib selectRowsFromEntity:@"FRIEND" predicate:nil sortColumn:@"created" mOC:managedObjectContext ascendingFlg:YES]];
		int i=[self deleteItems:[CoreDataLib selectRowsFromEntity:@"GAME" predicate:nil sortColumn:@"startTime" mOC:managedObjectContext ascendingFlg:YES]];
		[ProjectFunctions showAlertPopup:@"Database Deleted" message:[NSString stringWithFormat:@"%d games have been deleted.", i]];
		[ProjectFunctions updateGamesOnDevice:self.managedObjectContext];
		[self.mainTableView reloadData];
		[(MainMenuVC*)callBackViewController calculateStats];
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	self.gSelectedRow = (int)indexPath.row;

	if(indexPath.section==0) {
		NSString *menuItem = [menuArray stringAtIndex:(int)indexPath.row];

		if([menuItem isEqualToString:NSLocalizedString(@"Delete", nil)]) {
			NSArray *games = [CoreDataLib selectRowsFromEntity:@"GAME" predicate:nil sortColumn:@"startTime" mOC:managedObjectContext ascendingFlg:YES];
			if([games count]==0) {
				[ProjectFunctions showAlertPopup:@"Error!" message:@"No data found on this device!"];
				return;
			}
			UIDevice *device = [UIDevice currentDevice];
			//    NSString *systemName = [device systemName];
			//    NSString *systemVersion = [device systemVersion];
			NSString *model = [device model];
			if (games.count>100 && ![@"iPhone Simulator" isEqualToString:model]) {
				NSManagedObject *mo = [games objectAtIndex:0];
				int cashoutAmount = [[mo valueForKey:@"cashoutAmount"] intValue];
				NSString *startTime = [ProjectFunctions displayLocalFormatDate:[mo valueForKey:@"startTime"] showDay:YES showTime:NO];
				NSString *message = NSLocalizedString(@"deleteSafeguard", nil);
				if([ProjectFunctions getProductionMode] && cashoutAmount != 999) {
					[ProjectFunctions showAlertPopup:NSLocalizedString(@"notice", nil) message:[NSString stringWithFormat:@"%@ (%@ currently: %@)", message, startTime, [ProjectFunctions convertNumberToMoneyString:cashoutAmount]]];
					return;
				}
			}
			
			[ProjectFunctions showConfirmationPopup:NSLocalizedString(@"notice", nil) message:NSLocalizedString(@"deleteMessage", nil) delegate:self tag:kDeleteAllData];
			return;
		}

		if([menuItem isEqualToString:NSLocalizedString(@"Cleanup", nil)]) {
			cleanupRefData *detailViewController = [[cleanupRefData alloc] initWithNibName:@"cleanupRefData" bundle:nil];
			detailViewController.managedObjectContext = managedObjectContext;
			[self.navigationController pushViewController:detailViewController animated:YES];
			return;
		}
		
		
		//----------------------- username required -----------------
		
		if([ProjectFunctions getUserDefaultValue:@"userName"].length==0) {
			[ProjectFunctions displayLoginMessage];
			return;
		}

		if([menuItem isEqualToString:NSLocalizedString(@"Resync", nil)]) {
			[self refreshButtonClicked];
			return;
		}

		if([menuItem isEqualToString:NSLocalizedString(@"Clear", nil)]) {
			if([[ProjectFunctions getUserDefaultValue:@"gamesOnDevice"] intValue]==0)
				[ProjectFunctions showAlertPopup:@"Error" message:@"You cannot clear the server games if there are no games on this device."];
			else if ([[ProjectFunctions getUserDefaultValue:@"gamesOnServer"] intValue]==0)
				[ProjectFunctions showAlertPopup:@"Error" message:@"There are no games on the server."];
			else
				[ProjectFunctions showConfirmationPopup:@"Warning!" message:@"Do you wish to clear all games stored on the server?" delegate:self tag:kClearServerData];
			return;
		}
		

		if([menuItem isEqualToString:NSLocalizedString(@"Email", nil)]) {
			EmailFile *detailViewController = [[EmailFile alloc] initWithNibName:@"EmailFile" bundle:nil];
			detailViewController.managedObjectContext = managedObjectContext;
			[self.navigationController pushViewController:detailViewController animated:YES];
		}
		
		if([menuItem isEqualToString:@"Sync Device With Cloud"]) {
			[ProjectFunctions showConfirmationPopup:@"Sync Device" message:@"Do you wish to sync your device with the cloud? Useful if you play games using more than one device." delegate:self tag:0];
        }
        
		if([menuItem isEqualToString:NSLocalizedString(@"Export", nil)]) {
			NSArray *games = [CoreDataLib selectRowsFromEntity:@"GAME" predicate:nil sortColumn:@"startTime" mOC:managedObjectContext ascendingFlg:YES];
			if([games count]==0) {
				[ProjectFunctions showAlertPopup:@"Error!" message:@"No data found on this device!"];
				return;
			}
			if([games count] < [[ProjectFunctions getUserDefaultValue:@"gamesOnServer"] intValue]) {
				[ProjectFunctions showAlertPopup:@"Error!" message:@"You have fewer games on this device than you have on the server. Click 'Clear all Server Data' first if you wish to proceed."];
				return;
			}
			
			[ProjectFunctions showConfirmationPopup:NSLocalizedString(@"Export", nil) message:@"Do you wish to Export all of the poker data on this device?" delegate:self tag:kExportData];
		}
		if([menuItem isEqualToString:NSLocalizedString(@"Import", nil)]) {
			[ProjectFunctions showConfirmationPopup:NSLocalizedString(@"Import", nil) message:@"Do you wish to Import your saved data to this device?" delegate:self tag:kImportData];
		}
		if([menuItem isEqualToString:NSLocalizedString(@"ImportJournal", nil)]) {
			self.importType=1;
			activityBG.alpha=.75;
			importPopup.alpha=1;
			importTextView.alpha=1;
			laterButton.alpha=1;
			importButton.alpha=1;
			
		}
		if([menuItem isEqualToString:NSLocalizedString(@"ImportIncome", nil)]) {
			self.importType=2;
			activityBG.alpha=.75;
			importPopup.alpha=1;
			importTextView.alpha=1;
			laterButton.alpha=1;
			importButton.alpha=1;
		}
	} // <== 0
	if(indexPath.section==1) {
		NSString *menuItem = [secondMenuArray stringAtIndex:(int)indexPath.row];
		if([menuItem isEqualToString:@"Edit Theme"]) {
			EditThemeVC *detailViewController = [[EditThemeVC alloc] initWithNibName:@"EditThemeVC" bundle:nil];
			detailViewController.managedObjectContext = managedObjectContext;
			[self.navigationController pushViewController:detailViewController animated:YES];
		}
		if([menuItem isEqualToString:@"Enter Old Game"]) {
			CreateOldGameVC *detailViewController = [[CreateOldGameVC alloc] initWithNibName:@"CreateOldGameVC" bundle:nil];
			detailViewController.managedObjectContext = managedObjectContext;
			[self.navigationController pushViewController:detailViewController animated:YES];
		}
		if([menuItem isEqualToString:@"Lock App"]) {
			LockAppVC *detailViewController = [[LockAppVC alloc] initWithNibName:@"LockAppVC" bundle:nil];
			[self.navigationController pushViewController:detailViewController animated:YES];
		}
		if([menuItem isEqualToString:@"Locations"]) {
			LocationsVC *detailViewController = [[LocationsVC alloc] initWithNibName:@"LocationsVC" bundle:nil];
			detailViewController.managedObjectContext = managedObjectContext;
			[self.navigationController pushViewController:detailViewController animated:YES];
		}
		if([menuItem isEqualToString:@"Edit Profile"]) {
			if([[ProjectFunctions getUserDefaultValue:@"userName"] length]==0)
				[ProjectFunctions displayLoginMessage];
			else {
				ProfileVC *detailViewController = [[ProfileVC alloc] initWithNibName:@"ProfileVC" bundle:nil];
				detailViewController.managedObjectContext = managedObjectContext;
				[self.navigationController pushViewController:detailViewController animated:YES];
			}
		}
		if([menuItem isEqualToString:@"Friend Alerts"]) {
			FriendAlertsVC *detailViewController = [[FriendAlertsVC alloc] initWithNibName:@"FriendAlertsVC" bundle:nil];
			[self.navigationController pushViewController:detailViewController animated:YES];
		}
		if([menuItem isEqualToString:@"Edit Bankroll"]) {
            BankrollsVC *detailViewController = [[BankrollsVC alloc] initWithNibName:@"BankrollsVC" bundle:nil];
            detailViewController.managedObjectContext = managedObjectContext;
            detailViewController.callBackViewController = self;
            [self.navigationController pushViewController:detailViewController animated:YES];
		}
		if([menuItem isEqualToString:@"Email Developer"]) {
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"mailto:%@", @"rickmedved@hotmail.com"]]];
		}
		if([menuItem isEqualToString:@"Write App Review"]) {
			[ProjectFunctions writeAppReview];
		}
		if([menuItem isEqualToString:@"Sound"]) {
			NSString *soundOn = [ProjectFunctions getUserDefaultValue:@"soundOn"];
			soundOn = ([soundOn length]==0)?@"Off":@"";
			[ProjectFunctions setUserDefaultValue:soundOn forKey:@"soundOn"];
			[mainTableView reloadData];
		}
		if([menuItem isEqualToString:@"Casino Locator"]) {
			CasinoTrackerVC *detailViewController = [[CasinoTrackerVC alloc] initWithNibName:@"CasinoTrackerVC" bundle:nil];
			detailViewController.managedObjectContext = managedObjectContext;
			[self.navigationController pushViewController:detailViewController animated:YES];
		}
		if([menuItem isEqualToString:@"Tournament Director"]) {
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/apple-store/id504430732?mt=8"]];
		}
		if([menuItem isEqualToString:@"BuyPokerChips.com"]) {
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.buypokerchips.com"]];
		}
		if([menuItem isEqualToString:@"Taunt"]) {
			TauntVC *detailViewController = [[TauntVC alloc] initWithNibName:@"TauntVC" bundle:nil];
			[self.navigationController pushViewController:detailViewController animated:YES];
		}
		if([menuItem isEqualToString:@"Login"]) {
			LoginVC *detailViewController = [[LoginVC alloc] initWithNibName:@"LoginVC" bundle:nil];
			detailViewController.managedObjectContext = managedObjectContext;
			[self.navigationController pushViewController:detailViewController animated:YES];
		}
		if([menuItem isEqualToString:@"Edit Icons"]) {
			ChangeIconVC *detailViewController = [[ChangeIconVC alloc] initWithNibName:@"ChangeIconVC" bundle:nil];
			[self.navigationController pushViewController:detailViewController animated:YES];
		}
		if([menuItem isEqualToString:@"Food Scrub"]) {
			Scrub2017VC *detailViewController = [[Scrub2017VC alloc] initWithNibName:@"Scrub2017VC" bundle:nil];
			detailViewController.managedObjectContext = managedObjectContext;
			[self.navigationController pushViewController:detailViewController animated:YES];
		}

	} // section==1
	
	
	
}

- (IBAction) upgradePressed: (id) sender {
	UpgradeVC *detailViewController = [[UpgradeVC alloc] initWithNibName:@"UpgradeVC" bundle:nil];
	detailViewController.managedObjectContext = managedObjectContext;
	[self.navigationController pushViewController:detailViewController animated:YES];
}

-(void)refreshButtonClicked {
	[activityIndicator startAnimating];
	activityLabel.alpha=1;
	self.activityPopup.alpha=1;
	
	[self performSelectorInBackground:@selector(uploadStatsFunction) withObject:nil];
}


-(void)uploadStatsFunction
{
	@autoreleasepool {
        [ProjectFunctions uploadUniverseStats:self.managedObjectContext];
		[activityIndicator stopAnimating];
		activityLabel.alpha=0;
		self.activityPopup.alpha=0;
		[ProjectFunctions showAlertPopup:@"Success" message:@"data synced."];
	}
}


-(void) setReturningValue:(NSString *) value {
	[ProjectFunctions setUserDefaultValue:value forKey:@"moneySymbol"];
	[mainTableView reloadData];
}


#pragma mark -
#pragma mark Memory management



@end

