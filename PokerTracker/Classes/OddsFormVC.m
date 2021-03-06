//
//  OddsFormVC.m
//  PokerTracker
//
//  Created by Rick Medved on 10/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OddsFormVC.h"
#import "SelectionCell.h"
#import "CardHandPicker.h"
#import "UIColor+ATTColor.h"
#import "MultiLineDetailCellWordWrap.h"
#import "ActionCell.h"
#import "PokerOddsFunctions.h"
#import "BigHandsFormVC.h"
#import "PokerCell.h"
#import "ProjectFunctions.h"


#define kTotalPreflop	1000

@implementation OddsFormVC
@synthesize labelValues, formDataArray, numPlayers, selectedRow, mainTableView, calculateButton, leftButton;
@synthesize isCalculating, preFlopStillWorking, turnStillWorking, highHandValue, activityView, preLoaedValues;
@synthesize playerTurnResults, playerWinResults, playerFlopResults, playerPreFlopResults, boardFilledOut;
@synthesize activityPopup, activityLabel, progressView, numberOfPreflopHandsProcessed, postFlopStillWorking;
@synthesize managedObjectContext, mo;


#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
	[super viewDidLoad];
	[self setTitle:@"Odds Calc"];
	[self changeNavToIncludeType:28];
	
	labelValues = [[NSMutableArray alloc] init];
	formDataArray = [[NSMutableArray alloc] init];
	playerTurnResults = [[NSMutableArray alloc] init];
	playerWinResults = [[NSMutableArray alloc] init];
	playerFlopResults = [[NSMutableArray alloc] init];
	playerPreFlopResults = [[NSMutableArray alloc] init];
	
	self.selectedRow=0;
	self.highHandValue=0;
	self.numberOfPreflopHandsProcessed=0;
	
	self.navigationItem.leftBarButtonItem = [ProjectFunctions UIBarButtonItemWithIcon:[NSString fontAwesomeIconStringForEnum:FAHome] target:self action:@selector(mainMenuButtonClicked:)];
	
	self.calculateButton = [[UIBarButtonItem alloc] initWithTitle:@"Calculate!" style:UIBarButtonItemStylePlain target:self action:@selector(calculateButtonClicked)];
	self.navigationItem.rightBarButtonItem = calculateButton;
	
	self.clearButton.enabled=preLoaedValues;
	self.randomButton.enabled=!preLoaedValues;
	self.calculateBotButton.enabled=preLoaedValues;

	self.calculateButton.enabled = preLoaedValues;
	
	activityPopup.alpha=0;
	activityLabel.alpha=0;
	progressView.alpha=0;

	
	[self setupdata];
}

-(void)calculatePreFlop
{
	@autoreleasepool {
	
		NSMutableArray *playerHands = [[NSMutableArray alloc] init];
		for(int i=0; i<numPlayers; i++) {
			[playerHands addObject:[formDataArray objectAtIndex:i]];
		}
		NSString *playerBurnedCards = [playerHands componentsJoinedByString:@"-"];
		self.numberOfPreflopHandsProcessed=0;
		int winninghands[10] = {0,0,0,0,0,0,0,0,0,0};
		int choppinghands[10] = {0,0,0,0,0,0,0,0,0,0};
		for(int i=1; i<=kTotalPreflop; i++) {
			NSString *burnedCards = playerBurnedCards;
			NSString *flop = [PokerOddsFunctions getRandomFlop:burnedCards];
			burnedCards = [NSString stringWithFormat:@"%@-%@", burnedCards, flop];
			NSString *turn = [PokerOddsFunctions getRandomCard:burnedCards];
			burnedCards = [NSString stringWithFormat:@"%@-%@", burnedCards, turn];
			NSString *river = [PokerOddsFunctions getRandomCard:burnedCards];
			NSArray *playerResults = [PokerOddsFunctions getPlayerResultsForHand:playerHands flop:flop turn:turn river:river includeHandString:NO];

			int x=0;
			for(NSString *resultText in playerResults) {
				if([resultText isEqualToString:@"Win"])
					winninghands[x]++;
				if([resultText isEqualToString:@"Chop"])
					choppinghands[x]++;
				x++;
			}

			numberOfPreflopHandsProcessed++;
		}
		
		NSString *totalsString = [NSString stringWithFormat:@"%d|%d,%d,%d,%d,%d,%d,%d,%d,%d,%d|%d,%d,%d,%d,%d,%d,%d,%d,%d,%d", kTotalPreflop,
		 winninghands[0],
		 winninghands[1],
		 winninghands[2],
		 winninghands[3],
		 winninghands[4],
		 winninghands[5],
		 winninghands[6],
		 winninghands[7],
		 winninghands[8],
		 winninghands[9],
		 choppinghands[0],
		 choppinghands[1],
		 choppinghands[2],
		 choppinghands[3],
		 choppinghands[4],
		 choppinghands[5],
		 choppinghands[6],
		 choppinghands[7],
		 choppinghands[8],
		 choppinghands[9]
		 ];
		
		NSArray *preflopResults = [PokerOddsFunctions calculateTotalsandReturnTheStrings:totalsString numPlayers:(int)[playerHands count]];
		int i=0;
		for(NSString *value in preflopResults)
			[playerPreFlopResults replaceObjectAtIndex:i++ withObject:value];
		
		if(mo != nil) {
			NSString *oddsStr = [playerPreFlopResults componentsJoinedByString:@"|"];
			oddsStr = [oddsStr stringByReplacingOccurrencesOfString:@"Win" withString:@"W"];
			oddsStr = [oddsStr stringByReplacingOccurrencesOfString:@"Chop" withString:@"C"];
			oddsStr = [oddsStr stringByReplacingOccurrencesOfString:@" " withString:@""];
			[mo setValue:oddsStr forKey:@"preFlopOdds"];
			[managedObjectContext save:nil];
		}
		preFlopStillWorking=NO;
		[self checkIfComplete];
	}
}

-(void)updateProgressBar {
	@autoreleasepool {
		float amountComplete = 0.0;
		if(kTotalPreflop>0)
			amountComplete = (float)numberOfPreflopHandsProcessed/kTotalPreflop;
		
    dispatch_async(dispatch_get_main_queue(), ^{
        [progressView setProgress:amountComplete];
    }
    );

		[NSThread sleepForTimeInterval:0.4];
		
		if(isCalculating)
			[self performSelectorInBackground:@selector(updateProgressBar) withObject:nil];
	}
}

-(void)checkIfComplete {
	NSLog(@"checkIfComplete!");
	if(preFlopStillWorking || self.postFlopStillWorking || turnStillWorking) {
		NSLog(@"Still working...");
	} else {
		NSLog(@"All Done!!");
		isCalculating = NO;
		self.doneCalculating=YES;
		calculateButton.enabled = YES;
		activityPopup.alpha=0;
		activityLabel.alpha=0;
		progressView.alpha=0;
		[activityView stopAnimating];
		[self enableCalcButton:YES];
		[mainTableView reloadData];
	}
	if(!preFlopStillWorking || !self.postFlopStillWorking || !turnStillWorking) {
		activityPopup.alpha=0;
		NSLog(@"PArtial Done");
	}
}

-(void)calculatePostFlop
{
	@autoreleasepool {
//		[NSThread sleepForTimeInterval:5];
		NSMutableArray *playerHands = [[NSMutableArray alloc] init];
		for(int i=0; i<numPlayers; i++) {
			[playerHands addObject:[formDataArray objectAtIndex:i]];
		}
		NSArray *flopResults = [PokerOddsFunctions getPlayerResultsForFlop:playerHands flop:[formDataArray objectAtIndex:numPlayers]];
		int i=0;
		for(NSString *value in flopResults)
			[playerFlopResults replaceObjectAtIndex:i++ withObject:value];

		if(mo != nil) {
			NSString *oddsStr = [playerFlopResults componentsJoinedByString:@"|"];
			oddsStr = [oddsStr stringByReplacingOccurrencesOfString:@"Win" withString:@"W"];
			oddsStr = [oddsStr stringByReplacingOccurrencesOfString:@"Chop" withString:@"C"];
			oddsStr = [oddsStr stringByReplacingOccurrencesOfString:@" " withString:@""];
			[mo setValue:oddsStr forKey:@"postFlopOdds"];
			[managedObjectContext save:nil];
		}
		self.postFlopStillWorking=NO;
		[self checkIfComplete];
	}
}


-(void)calculateTurn
{
	@autoreleasepool {
		NSMutableArray *playerHands = [[NSMutableArray alloc] init];
		for(int i=0; i<numPlayers; i++) {
			[playerHands addObject:[formDataArray objectAtIndex:i]];
		}
		
		NSArray *results = [PokerOddsFunctions getPlayerResultsForTurn:playerHands flop:[formDataArray objectAtIndex:numPlayers] turn:[formDataArray objectAtIndex:numPlayers+1]];
		int i=0;
		for(NSString *value in results)
			[playerTurnResults replaceObjectAtIndex:i++ withObject:value];
		
		if(mo != nil) {
			NSString *oddsStr = [playerTurnResults componentsJoinedByString:@"|"];
			oddsStr = [oddsStr stringByReplacingOccurrencesOfString:@"Win" withString:@"W"];
			oddsStr = [oddsStr stringByReplacingOccurrencesOfString:@"Chop" withString:@"C"];
			oddsStr = [oddsStr stringByReplacingOccurrencesOfString:@" " withString:@""];
			[mo setValue:oddsStr forKey:@"turnOdds"];
			[managedObjectContext save:nil];
		}
		self.turnStillWorking=NO;
		[self checkIfComplete];
	}
}

-(void)calculateFinalHand
{
	@autoreleasepool {
		NSMutableArray *playerHands = [[NSMutableArray alloc] init];
		for(int i=0; i<numPlayers; i++) {
			[playerHands addObject:[formDataArray objectAtIndex:i]];
		}
		
		NSArray *winResults = [PokerOddsFunctions getPlayerResultsForHand:playerHands flop:[formDataArray objectAtIndex:numPlayers] turn:[formDataArray objectAtIndex:numPlayers+1] river:[formDataArray objectAtIndex:numPlayers+2] includeHandString:YES];
		int i=0;
		for(NSString *value in winResults)
			[playerWinResults replaceObjectAtIndex:i++ withObject:value];

		if(mo != nil) {
			NSMutableArray *results = [[NSMutableArray alloc] init];
			for(NSString *line in playerWinResults) {
				if([line length]>3)
					[results addObject:[line substringToIndex:4]];
			}
			if(results.count>0) {
				NSString *yourResult = [results objectAtIndex:0];
				yourResult = [yourResult stringByReplacingOccurrencesOfString:@" " withString:@""];
				[mo setValue:yourResult forKey:@"winStatus"];
				NSLog(@"+++your result: [%@]", yourResult);
			}
			NSString *oddsStr = [results componentsJoinedByString:@"|"];
			oddsStr = [oddsStr stringByReplacingOccurrencesOfString:@"Win" withString:@"W"];
			oddsStr = [oddsStr stringByReplacingOccurrencesOfString:@"Chop" withString:@"C"];
			[mo setValue:oddsStr forKey:@"riverOdds"];
			[mo setValue:[playerWinResults componentsJoinedByString:@", "] forKey:@"finalHands"];
			[managedObjectContext save:nil];
		}
		[self checkIfComplete];
	}
}


- (IBAction) calculateButtonPressed: (UIButton *) button {
	[self calculateButtonClicked];
}

-(void)calculateButtonClicked {
	if(mo != nil) {
		if(self.doneCalculating) {
			NSLog(@"All done calculating!!!!");
			[self gotoBigHands];
			return;
		} else {
			[self.calculateButton setTitle:@"Done!"];
		}
	}
	[self completeWithRandomCards];
	[activityView startAnimating];
	activityPopup.alpha=1;
	activityLabel.alpha=1;
	progressView.progress=0;
	progressView.alpha=1;
	calculateButton.enabled = NO;
	self.clearButton.enabled = NO;
	self.randomButton.enabled = NO;
	self.calculateBotButton.enabled = NO;
	self.isCalculating=YES;
	self.preFlopStillWorking=YES;
	self.postFlopStillWorking=YES;
	self.turnStillWorking=YES;

	[self performSelectorInBackground:@selector(calculatePreFlop) withObject:nil];
	[self performSelectorInBackground:@selector(calculatePostFlop) withObject:nil];
	[self performSelectorInBackground:@selector(calculateTurn) withObject:nil];
	[self performSelectorInBackground:@selector(calculateFinalHand) withObject:nil];
	[self performSelectorInBackground:@selector(updateProgressBar) withObject:nil];
}

-(void)mainMenuButtonClicked:(id)sender {
	[self.navigationController popToViewController:[self.navigationController.viewControllers objectAtIndex:1] animated:YES];
}

-(void)setupdata
{
	for(int i=1; i<=numPlayers; i++) {
		[playerTurnResults addObject:@"*"];
		[playerWinResults addObject:@"*"];
		[playerFlopResults addObject:@"*"];
		[playerPreFlopResults addObject:@"*"];
	}

	[labelValues addObject:@"Your Hand"];
	[formDataArray addObject:(preLoaedValues)?[preLoaedValues objectAtIndex:1]:@"-select-"];

	for(int i=2; i<=numPlayers; i++) {
		[labelValues addObject:[NSString stringWithFormat:@"Player %i Hand", i]];
		[formDataArray addObject:(preLoaedValues)?[preLoaedValues objectAtIndex:i]:@"-select-"];
	}
	
	[labelValues addObject:@"Flop"];
	[labelValues addObject:@"Turn"];
	[labelValues addObject:@"River"];
	
	[formDataArray addObject:(preLoaedValues)?[preLoaedValues objectAtIndex:numPlayers+1]:@"-select-"];
	[formDataArray addObject:(preLoaedValues)?[preLoaedValues objectAtIndex:numPlayers+2]:@"-select-"];
	[formDataArray addObject:(preLoaedValues)?[preLoaedValues objectAtIndex:numPlayers+3]:@"-select-"];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
	if(section==0)
		return [labelValues count]+1;
	
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if(indexPath.section==0)
		return 44;
		
	return numPlayers*20+20;
}

-(NSString *)altTitleForRow:(int)row {
	if(!self.doneCalculating && !self.isCalculating)
		return @"Not Calculated";
	if(row==1)
		return (self.preFlopStillWorking)?@"Working...":@"Calculated";
	if(row==2)
		return (self.postFlopStillWorking)?@"Working...":@"Calculated";
	if(row==3)
		return (self.turnStillWorking)?@"Working...":@"Calculated";
	if(row==4)
		return (self.turnStillWorking)?@"Working...":@"Calculated";
	return @"Whoa!";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	NSString *cellIdentifier = [self cellId:indexPath];
	if(indexPath.section==0) {
		if(indexPath.row<[labelValues count]) {
			return [PokerCell pokerCell:tableView cellIdentifier:cellIdentifier cellLabel:[labelValues objectAtIndex:indexPath.row] cellValue:[formDataArray objectAtIndex:indexPath.row] viewEditable:YES];
		}
		ActionCell *cell = [[ActionCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];

		cell.backgroundColor = [ProjectFunctions themeBGColor];
		cell.textLabel.textColor = [ProjectFunctions primaryButtonColor];
		if(boardFilledOut)
			cell.textLabel.text = @"Clear The Board";
		else
			cell.textLabel.text = @"Complete With Random Cards";
		
		if(self.isCalculating)
			cell.textLabel.text = @"Working...";
		if(self.doneCalculating)
			cell.textLabel.text = @"Done!";
		return cell;
	}
	
	int NumberOfRows = numPlayers;
	
	MultiLineDetailCellWordWrap *cell = [[MultiLineDetailCellWordWrap alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier withRows:NumberOfRows labelProportion:0.4];
	NSArray *headers = [NSArray arrayWithObjects:@"Form", @"Preflop Odds", @"Postflop Odds", @"Turn odds", @"Final Result", nil];
	cell.mainTitle = [headers objectAtIndex:indexPath.section];
	cell.alternateTitle = [self altTitleForRow:(int)indexPath.section];
	
	NSMutableArray *titles = [[NSMutableArray alloc] init];
	[titles addObject:@"You:"];
	for(int i=1; i<numPlayers; i++)
		[titles addObject:[NSString stringWithFormat:@"Player %d:", i+1]];
	
	NSMutableArray *valueArray = [[NSMutableArray alloc] init];
	NSMutableArray *colorArray = [[NSMutableArray alloc] init];
	
	NSArray *playerResults = nil;
		
		if(indexPath.section==1)
			playerResults = playerPreFlopResults;
		if(indexPath.section==2)
			playerResults = playerFlopResults;
		if(indexPath.section==3)
			playerResults = playerTurnResults;
		if(indexPath.section==4)
			playerResults = playerWinResults;

	for(int i=0; i<numPlayers; i++) {
		NSString *result = @"-";
		if([playerResults count]>i)
			result = [playerResults objectAtIndex:i];
		[valueArray addObject:result];
		if([result isEqualToString:@"Win"])
			[colorArray addObject:[UIColor colorWithRed:0 green:.5 blue:0 alpha:1]];
		else if([result isEqualToString:@"Loss"])
			[colorArray addObject:[UIColor redColor]];
		else if([result isEqualToString:@"Chop"])
			[colorArray addObject:[UIColor orangeColor]];
		else
			[colorArray addObject:[UIColor blackColor]];

	}
	
	[colorArray addObject:[UIColor blackColor]];
	for(int i=1; i<numPlayers; i++)
	
	cell.titleTextArray = titles;
	cell.fieldTextArray = valueArray;
	cell.fieldColorArray = colorArray;
	
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
	
}

-(void)completeWithRandomCards
{
	self.boardFilledOut=YES;
	if(0) { //<-- for testing
		[formDataArray replaceObjectAtIndex:0 withObject:@"Ac-9d"];
		[formDataArray replaceObjectAtIndex:1 withObject:@"Ah-As"];
		[formDataArray replaceObjectAtIndex:2 withObject:@"9c-5h"];
		[formDataArray replaceObjectAtIndex:numPlayers withObject:@"5s-5c-5d"];
		[formDataArray replaceObjectAtIndex:numPlayers+1 withObject:@"Th"];
		[formDataArray replaceObjectAtIndex:numPlayers+2 withObject:@"7s"];
	} else {
		NSMutableArray *playerHands = [[NSMutableArray alloc] init];
		NSString *burnedCards = [NSString stringWithFormat:@"%@-%@-%@", [formDataArray objectAtIndex:numPlayers], [formDataArray objectAtIndex:numPlayers+1], [formDataArray objectAtIndex:numPlayers+2]];
		for(int i=0; i<numPlayers; i++) {
			NSString *currentValue = [formDataArray objectAtIndex:i];
			if([currentValue isEqualToString:@"-select-"] || [currentValue isEqualToString:@"?x-?x"]) {
				NSString *card1 = [PokerOddsFunctions getRandomCard:burnedCards];
				burnedCards = [NSString stringWithFormat:@"%@-%@", burnedCards, card1];
				NSString *card2 = [PokerOddsFunctions getRandomCard:burnedCards];
				burnedCards = [NSString stringWithFormat:@"%@-%@", burnedCards, card2];
				[playerHands addObject:[NSString stringWithFormat:@"%@-%@", card1, card2]];
				[formDataArray replaceObjectAtIndex:i withObject:[NSString stringWithFormat:@"%@-%@", card1, card2]];
			} else {
				[playerHands addObject:currentValue];
			}
		}
		NSString *flop = [formDataArray objectAtIndex:numPlayers];
		if([flop isEqualToString:@"-select-"] || [flop isEqualToString:@"?x-?x-?x"]) {
			NSString *burnedCards = [PokerOddsFunctions getBurnedCards:playerHands flop:@"" turn:[formDataArray objectAtIndex:numPlayers+1] river:[formDataArray objectAtIndex:numPlayers+2]];
			
			flop = [PokerOddsFunctions getRandomFlop:burnedCards];
			[formDataArray replaceObjectAtIndex:numPlayers withObject:flop];
		}
		burnedCards = [NSString stringWithFormat:@"%@-%@", burnedCards, flop];
		
		NSString *turn = [formDataArray objectAtIndex:numPlayers+1];
		if([turn isEqualToString:@"-select-"] || [turn isEqualToString:@"?x"]) {
			turn = [PokerOddsFunctions getRandomCard:burnedCards];
			[formDataArray replaceObjectAtIndex:numPlayers+1 withObject:turn];
		}
		NSString *river = [formDataArray objectAtIndex:numPlayers+2];
		if([river isEqualToString:@"-select-"] || [river isEqualToString:@"?x"]) {
			burnedCards = [NSString stringWithFormat:@"%@-%@", burnedCards, turn];
			[formDataArray replaceObjectAtIndex:numPlayers+2 withObject:[PokerOddsFunctions getRandomCard:burnedCards]];
		}
	}
	
	calculateButton.enabled=YES;
	self.doneCalculating=NO;
	for(int i=0; i<numPlayers; i++) {
		[playerTurnResults replaceObjectAtIndex:i withObject:@"*"];
		[playerWinResults replaceObjectAtIndex:i withObject:@"*"];
		[playerFlopResults replaceObjectAtIndex:i withObject:@"*"];
		[playerPreFlopResults replaceObjectAtIndex:i withObject:@"*"];
	}
	self.clearButton.enabled=YES;
	self.randomButton.enabled=NO;
	self.calculateBotButton.enabled=YES;
	[self.mainTableView reloadData];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if(indexPath.section>0)
		return;
	if(self.isCalculating)
		return;
	
	self.selectedRow = (int)indexPath.row;
	
	NSMutableArray *playerHands = [[NSMutableArray alloc] init];
	for(int i=0; i<numPlayers; i++)
		[playerHands addObject:[formDataArray objectAtIndex:i]];
	
	NSString *labelValue = @"";
	if(indexPath.row<[labelValues count])
		labelValue = [NSString stringWithFormat:@"%@", [labelValues objectAtIndex:indexPath.row]];
	NSString *dataValue = @"";
	if(indexPath.row<[formDataArray count])
		dataValue = [NSString stringWithFormat:@"%@", [formDataArray objectAtIndex:indexPath.row]];

	if(self.selectedRow<numPlayers) {
		CardHandPicker *detailViewController = [[CardHandPicker alloc] initWithNibName:@"CardHandPicker" bundle:nil];
		detailViewController.managedObjectContext=managedObjectContext;
		detailViewController.titleLabel = labelValue;
		detailViewController.callBackViewController=self;
		detailViewController.numberCards=2;
		detailViewController.initialDateValue = dataValue;
		detailViewController.burnedcards = [PokerOddsFunctions getBurnedCardsMinusThese:playerHands flop:[formDataArray objectAtIndex:numPlayers] turn:[formDataArray objectAtIndex:numPlayers+1] river:[formDataArray objectAtIndex:numPlayers+2] removeIndex:(int)indexPath.row];
		[self.navigationController pushViewController:detailViewController animated:YES];
	} else 	if(self.selectedRow==numPlayers) {
		CardHandPicker *detailViewController = [[CardHandPicker alloc] initWithNibName:@"CardHandPicker" bundle:nil];
		detailViewController.managedObjectContext=managedObjectContext;
		detailViewController.titleLabel = labelValue;
		detailViewController.callBackViewController=self;
		detailViewController.initialDateValue = dataValue;
		detailViewController.numberCards=3;
		detailViewController.burnedcards = [PokerOddsFunctions getBurnedCardsMinusThese:playerHands flop:[formDataArray objectAtIndex:numPlayers] turn:[formDataArray objectAtIndex:numPlayers+1] river:[formDataArray objectAtIndex:numPlayers+2] removeIndex:(int)indexPath.row];
		[self.navigationController pushViewController:detailViewController animated:YES];
	} else if(self.selectedRow<=numPlayers+2) {
		CardHandPicker *detailViewController = [[CardHandPicker alloc] initWithNibName:@"CardHandPicker" bundle:nil];
		detailViewController.managedObjectContext=managedObjectContext;
		detailViewController.titleLabel = labelValue;
		detailViewController.callBackViewController=self;
		detailViewController.initialDateValue = dataValue;
		detailViewController.numberCards=1;
		detailViewController.burnedcards = [PokerOddsFunctions getBurnedCardsMinusThese:playerHands flop:[formDataArray objectAtIndex:numPlayers] turn:[formDataArray objectAtIndex:numPlayers+1] river:[formDataArray objectAtIndex:numPlayers+2] removeIndex:(int)indexPath.row];
		[self.navigationController pushViewController:detailViewController animated:YES];
	} else {
		if(boardFilledOut) {
			[self clearBoard];
		} else {
			[self completeWithRandomCards];
		}
	}
}

-(void)clearBoard {
	NSLog(@"Clearing the board");
	calculateButton.enabled=NO;
	self.boardFilledOut=NO;
	for(int i=0; i<numPlayers; i++)
		[formDataArray replaceObjectAtIndex:i withObject:@"-select-"];
	[formDataArray replaceObjectAtIndex:numPlayers withObject:@"-select-"];
	[formDataArray replaceObjectAtIndex:numPlayers+1 withObject:@"-select-"];
	[formDataArray replaceObjectAtIndex:numPlayers+2 withObject:@"-select-"];
	for(int i=0; i<numPlayers; i++) {
		[playerTurnResults replaceObjectAtIndex:i withObject:@"*"];
		[playerWinResults replaceObjectAtIndex:i withObject:@"*"];
		[playerFlopResults replaceObjectAtIndex:i withObject:@"*"];
		[playerPreFlopResults replaceObjectAtIndex:i withObject:@"*"];
	}
	self.doneCalculating=NO;
	[self enableCalcButton:NO];
	[self.mainTableView reloadData];
}

-(void)enableCalcButton:(BOOL)enabled {
	self.clearButton.enabled=enabled;
	self.randomButton.enabled=!enabled;
	self.calculateBotButton.enabled=enabled;
}

- (IBAction) clearButtonPressed: (UIButton *) button {
	[self clearBoard];
}
- (IBAction) randomButtonPressed: (UIButton *) button {
	[self completeWithRandomCards];
}

-(void)gotoBigHands {
	BigHandsFormVC *detailViewController = [[BigHandsFormVC alloc] initWithNibName:@"BigHandsFormVC" bundle:nil];
	detailViewController.managedObjectContext = managedObjectContext;
	detailViewController.drilldown = YES;
	detailViewController.viewEditable = NO;
	detailViewController.mo = mo;
	[self.navigationController pushViewController:detailViewController animated:YES];
}

-(void) setReturningValue:(NSString *) value2 {
	NSString *value = [ProjectFunctions getUserDefaultValue:@"returnValue"];
	calculateButton.enabled = YES;
	self.boardFilledOut = YES;
	if(self.selectedRow<[formDataArray count] && value != nil)
		[formDataArray replaceObjectAtIndex:self.selectedRow withObject:value];
	int i=0;
	for(NSString *value in formDataArray) {
		if([value isEqualToString:@"-select-"]) {
			self.boardFilledOut = NO;
			if(i<numPlayers)
				calculateButton.enabled = NO;
		}
		i++;
	}
	self.doneCalculating=NO;
	[mainTableView reloadData];
}

@end

