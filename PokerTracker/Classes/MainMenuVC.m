//
//  MainMenuVC.m
//  PokerTracker
//
//  Created by Rick Medved on 10/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MainMenuVC.h"
#import "StatsPage.h"
#import "GamesVC.h"
#import "UniverseTrackerVC.h"
#import "CoreDataLib.h"
#import "NSDate+ATTDate.h"
#import "ProjectFunctions.h"
#import "OddsCalculatorVC.h"
#import "ForumVC.h"
#import "DatabaseManage.h"
#import "CreateOldGameVC.h"
#import "GameInProgressVC.h"
#import "MoneyPickerVC.h"
#import "StartNewGameVC.h"
#import "MoreTrackersVC.h"
#import "CasinoTrackerVC.h"
#import "MapKitTut.h"
#import "AnalysisVC.h"
#import "AppInitialVC.h"
#import "WebServicesFunctions.h"
#import "NSArray+ATTArray.h"
#import "BankrollsVC.h"
#import "UnLockAppVC.h"
#import "PlayerTrackerVC.h"
#import "DatePickerViewController.h"
#import "UpgradeVC.h"
#import "ReviewsVC.h"


@implementation MainMenuVC
@synthesize managedObjectContext, friendsNumLabel, friendsNumCircle, largeGraph, rotateLock, editButton;
@synthesize statsButton, gamesButton, tournamentButton, netTrackerButton, oddsButton, forumButton, moreTrackersButton, displayYear, displayBySession;
@synthesize yearLabel, moneyLabel, aboutImage, aboutShowing, aboutText, logoImage, upgradeButton, toggleMode;
@synthesize openGamesCircle, openGamesLabel, refreshButton, versionLabel, reviewButton, bankrollLabel, startNewGameButton;
@synthesize alertViewNum, emailButton, analysisButton, graphChart, logoAlpha, yearTotalLabel, smallYearLabel;
@synthesize showDisolve, screenLock, avoidPopup, casinoButton, casinoLabel, analysisBG, bankrollNameLabel;
@synthesize aboutButton, playerTypeLabel, forumNumLabel, forumNumCircle, activityIndicatorNet, activityIndicatorData;

- (void)viewDidLoad {
	[super viewDidLoad];
	[self setupData];
	
	if([ProjectFunctions getProductionMode])
		[self setTitle:NSLocalizedString(@"Main Menu", nil)];
	else {
		[self setTitle:@"Test Mode"];
		self.graphChart.alpha=.5;
	}
	
	[self findMinAndMaxYear];
	self.aboutView.titleLabel.text = @"Poker Track Pro";

	self.casinoLabel.text = NSLocalizedString(@"Casino Locator", nil);
	self.playerTypeLabel.text = NSLocalizedString(@"Analysis", nil);
	self.playerTypeLabel.layer.cornerRadius = 7;
	self.playerTypeLabel.layer.masksToBounds = YES;				// clips background images to rounded corners
	self.playerTypeLabel.layer.borderColor = [UIColor blackColor].CGColor;
	self.playerTypeLabel.layer.borderWidth = 2.;
	self.last10Label.text = NSLocalizedString(@"Last 10", nil);
	self.analysisLabel.text = NSLocalizedString(@"Analysis", nil);
	
	self.topView.hidden=self.isPokerZilla;
	self.last10Label.hidden=self.isPokerZilla;
	self.forumButton.hidden=self.isPokerZilla;
	self.netTrackerButton.hidden=self.isPokerZilla;
	self.botView.hidden=self.isPokerZilla;
	self.pokerZillaImageView.hidden=!self.isPokerZilla;
	
	self.aboutView.hidden=YES;
	if(self.isPokerZilla)
		self.aboutTextView.text = @"Congratulations!! you are using the 2nd best Poker Stats Tracking app ever! Features include: \n\nReal-time game entry\nWidest array of stats and graphs\nPlayer Tracker\nHand Tracker\nOdds Calculator.\n\nBy the way, the only tracker better is Poker Track Pro, which has all these features plus more. Please check out Poker Track Pro for even more features including tracking your friends!!";
	
	int xPos=15;
	int yPos=270;
	int width=290;
	int height=113;
	if([[UIScreen mainScreen] bounds].size.height >= 568) { // iPhone 5
		height+=75;
		yPos=275;
	}
	if([[UIScreen mainScreen] bounds].size.width >= 700) { // iPad
		xPos=90;
		width=600;
		height=350;
	}
	if(self.isPokerZilla)
		yPos-=50;
	
	self.graphChart.frame = CGRectMake(xPos, yPos, width, height);
	
	if ([self.navigationController.navigationBar respondsToSelector:@selector(setBackgroundImage:forBarMetrics:)] ) {
		UIImage *image = [UIImage imageNamed:@"greenGradient.png"];
		[self.navigationController.navigationBar setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
		self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:.8 green:.7 blue:0 alpha:1];
	}
	
	
	
	
	self.toggleMode = [[ProjectFunctions getUserDefaultValue:@"toggleMode"] intValue];
	self.versionLabel.text = [NSString stringWithFormat:@"%@", [ProjectFunctions getProjectDisplayVersion]];;
	
	if([ProjectFunctions isLiteVersion]) {
		self.navigationItem.leftBarButtonItem = [ProjectFunctions navigationButtonWithTitle:@"Upgrade" selector:@selector(aboutButtonClicked:) target:self];
	} else {
		self.navigationItem.leftBarButtonItem = [ProjectFunctions UIBarButtonItemWithIcon:[NSString fontAwesomeIconStringForEnum:FAInfoCircle] target:self action:@selector(aboutButtonClicked:)];
	}
	self.navigationItem.rightBarButtonItem = [ProjectFunctions UIBarButtonItemWithIcon:[NSString fontAwesomeIconStringForEnum:FACog] target:self action:@selector(moreButtonClicked:)];
	
	[[[[UIApplication sharedApplication] delegate] window] addSubview:self.largeGraph];

	self.largeGraph.alpha=0;
	
	[self.navigationController.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName,nil]];
	
	yearLabel.alpha=0;
	friendsNumLabel.alpha=0;
	friendsNumCircle.alpha=0;
	self.forumNumLabel.alpha=0;
	self.forumNumCircle.alpha=0;
	
	upgradeButton.alpha=0;
	
	openGamesLabel.alpha=0;
	openGamesCircle.alpha=0;
	analysisButton.alpha=1;
	
	self.graphChart.layer.cornerRadius = 8.0;
	self.graphChart.layer.masksToBounds = YES;
	self.graphChart.layer.borderColor = [UIColor blackColor].CGColor;
	
	//---- This code added to prevent flicker----
	NSString *basicPred = [ProjectFunctions getBasicPredicateString:0 type:@"All"];
	NSPredicate *predicate2 = [NSPredicate predicateWithFormat:basicPred];
	double amountRisked = [[CoreDataLib getGameStatWithLimit:managedObjectContext dataField:@"amountRisked" predicate:predicate2 limit:10] doubleValue];
	double netIncome = [[CoreDataLib getGameStatWithLimit:managedObjectContext dataField:@"winnings" predicate:predicate2 limit:10] doubleValue];
	[analysisButton setBackgroundImage:[ProjectFunctions getPlayerTypeImage:amountRisked winnings:netIncome] forState:UIControlStateNormal];
	
	if([ProjectFunctions isLiteVersion]) {
		upgradeButton.alpha=1;
	}

	[self setupButtons];
	self.editButton.titleLabel.font = [UIFont fontWithName:kFontAwesomeFamilyName size:16];
	[self.editButton setTitle:[NSString fontAwesomeIconStringForEnum:FAPencil] forState:UIControlStateNormal];

	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"user_id = 0 AND status = %@", @"In Progress"];
	NSArray *items = [CoreDataLib selectRowsFromEntity:@"GAME" predicate:predicate sortColumn:@"startTime" mOC:self.managedObjectContext ascendingFlg:NO];
	if([items count]>0 && !avoidPopup) {
		self.alertViewNum=1;
		GameInProgressVC *detailViewController = [[GameInProgressVC alloc] initWithNibName:@"GameInProgressVC" bundle:nil];
		detailViewController.managedObjectContext = managedObjectContext;
		detailViewController.mo = [items objectAtIndex:0];
		detailViewController.newGameStated=NO;
		[self.navigationController pushViewController:detailViewController animated:YES];
	} else if(showDisolve) {
		NSString *passwordCode = [ProjectFunctions getUserDefaultValue:@"passwordCode"];
		if([passwordCode length]>0) {
			UnLockAppVC *detailViewController = [[UnLockAppVC alloc] initWithNibName:@"UnLockAppVC" bundle:nil];
			[self.navigationController pushViewController:detailViewController animated:NO];
		}
	}
}

-(void)setupButtons {
	[ProjectFunctions makeFAButton:self.startNewGameButton type:1 size:24];
	[self createMainMenuButton:self.gamesButton name:NSLocalizedString(@"Games", nil) type:34 size:24];
	[self createMainMenuButton:self.statsButton name:NSLocalizedString(@"Stats", nil) type:11 size:24];
	[self createMainMenuButton:self.oddsButton name:NSLocalizedString(@"Odds", nil) type:28 size:18];
	[self createMainMenuButton:self.moreTrackersButton name:NSLocalizedString(@"More", nil) type:5 size:18];
	[self createMainMenuButton:self.forumButton name:NSLocalizedString(@"Forum", nil) type:30 size:18];
	[self createMainMenuButton:self.netTrackerButton name:NSLocalizedString(@"Net Tracker", nil) type:31 size:18];
}

-(void)createMainMenuButton:(UIButton *)button name:(NSString *)name type:(int)type size:(float)size {
	if(size==24 && name.length>6)
		name = [name substringToIndex:6];
	if(name.length>11)
		name = [name substringToIndex:11];
	[ProjectFunctions makeFAButton:button type:type size:size text:name];
}

-(void)createLabelForButton:(UIButton *)button size:(float)size name:(NSString *)name icon:(NSString *)icon {
	if (name.length>6 && size>26)
		size = 26;
	if (name.length>12)
		size = 16;
	button.titleLabel.font = [UIFont fontWithName:kFontAwesomeFamilyName size:size];
	[button setTitle:[NSString stringWithFormat:@"%@ %@", icon,name] forState:UIControlStateNormal];
}

-(BOOL)isPokerZilla {
	return [ProjectFunctions isPokerZilla];
}

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	if([self respondsToSelector:@selector(edgesForExtendedLayout)])
		[self setEdgesForExtendedLayout:UIRectEdgeBottom];
	
	self.reviewView.hidden=YES;
	[self calculateStats];

	int bankroll = [[ProjectFunctions getUserDefaultValue:@"defaultBankroll"] intValue];
	if(bankroll==0) {
		NSArray *items = [CoreDataLib selectRowsFromEntity:@"GAME" predicate:nil sortColumn:nil mOC:self.managedObjectContext ascendingFlg:NO];
		if([items count]==0) {
			self.alertViewNum=99;
			[ProjectFunctions showAlertPopupWithDelegate:@"Welcome" message:[NSString stringWithFormat:@"%@ %@!", NSLocalizedString(@"Welcome", nil), ([self isPokerZilla])?@"PokerZilla":@"Poker Track Pro"] delegate:self];
		}
	} else if([ProjectFunctions isLiteVersion] && [ProjectFunctions getUserDefaultValue:@"UpgradeCheck"].length==0) {
		self.alertViewNum=199;
		[ProjectFunctions showAlertPopupWithDelegate:@"Notice" message:@"Poker Track Lite is not the full version of this app. Check out the details." delegate:self];
	}
	self.loggedInFlg = ([ProjectFunctions getUserDefaultValue:@"userName"].length>0);
	self.statusImageView.hidden=!self.loggedInFlg;
	if(self.loggedInFlg)
		[self countFriendsPlaying];

}


- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    UIDevice *device = [UIDevice currentDevice];
    NSString *model = [device model];
	
    if([model length]>3 && [[model substringToIndex:4] isEqualToString:@"iPad"])
        return;

    if(fromInterfaceOrientation == UIInterfaceOrientationPortrait) {
        self.largeGraph.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height);

        statsButton.alpha=0;
        gamesButton.alpha=0;
        tournamentButton.alpha=0;
        netTrackerButton.alpha=0;
        oddsButton.alpha=0;
        forumButton.alpha=0;
        casinoButton.alpha=0;
        moreTrackersButton.alpha=0;
        
//        [self.view bringSubviewToFront:self.largeGraph];
        self.largeGraph.alpha=1;
        self.rotateLock=YES;
    }
    else {
		self.largeGraph.alpha=0;
        statsButton.alpha=1;
        gamesButton.alpha=1;
        tournamentButton.alpha=1;
        netTrackerButton.alpha=1;
        oddsButton.alpha=1;
        forumButton.alpha=1;
        casinoButton.alpha=1;
        moreTrackersButton.alpha=1;
//        [self.view sendSubviewToBack:self.largeGraph];
        self.rotateLock=NO;
    }
}



- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSLog(@"didReceiveResponse");
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"didReceiveData: %@", responseString);
	int gamesOnDevice=0;
    NSArray *parts = [responseString componentsSeparatedByString:@"|"];
    if([parts count]>2) {
		self.statusImageView.image = [UIImage imageNamed:@"green.png"];
        int friendsPlayingCount = [[parts objectAtIndex:0] intValue];
        if(friendsPlayingCount>0) {
            friendsNumLabel.alpha=1;
            friendsNumCircle.alpha=1;
            [friendsNumLabel performSelectorOnMainThread:@selector(setText: ) withObject:[NSString stringWithFormat:@"%d", friendsPlayingCount] waitUntilDone:YES];
        }
        int forumCount = [[parts objectAtIndex:1] intValue];
        if(forumCount>0) {
            self.forumNumLabel.alpha=1;
            self.forumNumCircle.alpha=1;
            [self.forumNumLabel performSelectorOnMainThread:@selector(setText: ) withObject:[NSString stringWithFormat:@"%d", forumCount] waitUntilDone:YES];
        }
		gamesOnDevice = [[ProjectFunctions getUserDefaultValue:@"gamesOnDevice"] intValue];
		int numGamesServer = [[parts objectAtIndex:2] intValue];
		[ProjectFunctions setUserDefaultValue:[NSString stringWithFormat:@"%d", numGamesServer] forKey:@"numGamesServer2"];
		int gamesLastImport = [[ProjectFunctions getUserDefaultValue:@"gamesLastImport"] intValue];
		NSLog(@"+++gamesOnDevice: %d, gamesLastImport: %d", gamesOnDevice, gamesLastImport);

		if(self.loggedInFlg && numGamesServer>0 && numGamesServer>gamesOnDevice && numGamesServer>gamesLastImport) {
			[ProjectFunctions showAlertPopup:@"New Games!" message:@"You have new games on the server. Click the Gear button to import them. If you get this message after importing, simply export to re-sync."];
		}
    }
	self.currentVersion=10.8;
	self.numReviews=5;
	if([parts count]>4) {
		self.currentVersion=[[parts objectAtIndex:3] floatValue];
		self.numReviews=[[parts objectAtIndex:4] intValue];
	}
	self.reviewCountLabel.text = @"Reviews";
	self.reviewView.hidden = (gamesOnDevice<40 || [ProjectFunctions getUserDefaultValue:[ProjectFunctions getProjectDisplayVersion]].length>0);
	
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"didFailWithError");
	self.statusImageView.image = [UIImage imageNamed:@"red.png"];
 	[self.activityIndicatorNet stopAnimating];
  
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"connectionDidFinishLoading");
 	[self.activityIndicatorNet stopAnimating];
 
}

-(void)countFriendsPlaying
{
	NSString *str = @"";
	if(self.loggedInFlg) {
		[self.activityIndicatorNet startAnimating];
		self.statusImageView.image = [UIImage imageNamed:@"yellow.png"];
		str = [NSString stringWithFormat:@"http://www.appdigity.com/poker/pokerCountFriendsPlaying2.php?user=%@&token=%@", [ProjectFunctions getUserDefaultValue:@"userName"], [ProjectFunctions getUserDefaultValue:@"deviceToken"]];
	} else {
		str = @"http://www.appdigity.com/poker/pokerCountFriendsPlaying2.php?user=rickmedved@hotmail.com";
	}
	
	NSLog(@"%@", str);

    NSURL *url = [NSURL URLWithString:str];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];

    NSURLConnection *theConnection=[[NSURLConnection alloc] initWithRequest:request delegate:self];
	if (!theConnection) {
		self.statusImageView.image = [UIImage imageNamed:@"red.png"];
		NSLog(@"No connection");
		// Inform the user that the connection failed.
	}

	
    
}



- (IBAction) refreshPressed: (id) sender
{
	self.showDisolve=NO;
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"user_id = 0 AND status = %@", @"In Progress"];
	NSArray *items = [CoreDataLib selectRowsFromEntity:@"GAME" predicate:predicate sortColumn:@"name" mOC:managedObjectContext ascendingFlg:YES];
	[UIApplication sharedApplication].applicationIconBadgeNumber=[items count];	
	self.logoAlpha=101;
	self.screenLock=YES;
	
	
 	[self calculateStats];
}



-(void)aboutButtonClicked:(id)sender {
	
	if(rotateLock)
		return;
	if(screenLock) {
		[self startDisolveNow];
		return;
	}
	
	if([ProjectFunctions isLiteVersion]) {
		UpgradeVC *detailViewController = [[UpgradeVC alloc] initWithNibName:@"UpgradeVC" bundle:nil];
		detailViewController.managedObjectContext = managedObjectContext;
		[self.navigationController pushViewController:detailViewController animated:YES];
		return;
	}
	
	self.aboutView.hidden=!self.aboutView.hidden;

}

-(void)startDisolveNow
{
	self.screenLock=NO;
	[self performSelectorInBackground:@selector(logoDisolve2) withObject:nil];
}

-(BOOL)isTouchingImageView:(UIImageView *)imageView point:(CGPoint)point {
	int left = imageView.center.x - imageView.frame.size.width/2;
	int right = imageView.center.x + imageView.frame.size.width/2;
	int top = imageView.center.y - imageView.frame.size.height/2;
	int bottom = imageView.center.y + imageView.frame.size.height/2;
	
	if(point.x >= left && point.x <= right && point.y>=top && point.y<=bottom)
		return YES;
	else
		return NO;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	
	UITouch *touch = [[event allTouches] anyObject];
//	CGPoint startTouchPosition = [touch locationInView:touch.view];
	CGPoint startTouchPosition = [touch locationInView:self.view];
	
	if(CGRectContainsPoint(self.reviewView.frame, startTouchPosition)) {
		ReviewsVC *detailViewController = [[ReviewsVC alloc] initWithNibName:@"ReviewsVC" bundle:nil];
		detailViewController.managedObjectContext = managedObjectContext;
		detailViewController.currentVersion=self.currentVersion;
		detailViewController.numReviews=self.numReviews;
		[self.navigationController pushViewController:detailViewController animated:YES];
		return;
	}

	if(screenLock) {
		[self startDisolveNow];
		return;
	}

	self.displayBySession=!self.displayBySession;
	
	if(self.rotateLock || [self isTouchingImageView:self.graphChart point:startTouchPosition]) {
		self.toggleMode++;
		if(toggleMode>1)
			self.toggleMode=0;
		
		[ProjectFunctions setUserDefaultValue:[NSString stringWithFormat:@"%d", toggleMode] forKey:@"toggleMode"];

		[self calculateStats];
	}		
}




-(IBAction)upgradeButtonClicked:(id)sender {
	if(screenLock) {
		[self startDisolveNow];
		return;
	}
	if(rotateLock)
		return;

	UpgradeVC *detailViewController = [[UpgradeVC alloc] initWithNibName:@"UpgradeVC" bundle:nil];
	detailViewController.managedObjectContext = managedObjectContext;
	[self.navigationController pushViewController:detailViewController animated:YES];
	
}




-(IBAction)reviewButtonClicks:(id)sender {
	[ProjectFunctions writeAppReview];
}

-(IBAction)ptpButtonClicked:(id)sender {
	int appId = 475160109;
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://itunes.apple.com/us/app/apple-store/id%d?mt=8", appId]]];
}

-(IBAction)emailButtonClicked:(id)sender
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"mailto:%@", @"rickmedved@hotmail.com"]]];
}

-(IBAction)analysisButtonClicked:(id)sender
{
	if(screenLock) {
		[self startDisolveNow];
		return;
	}
	if(rotateLock)
		return;
	AnalysisVC *detailViewController = [[AnalysisVC alloc] initWithNibName:@"AnalysisVC" bundle:nil];
	detailViewController.managedObjectContext = managedObjectContext;
	detailViewController.last10Flg=YES;
	[self.navigationController pushViewController:detailViewController animated:YES];
}

-(void)editButtonClicked:(id)sender
{
	if(screenLock) {
		[self startDisolveNow];
		return;
	}
	if(rotateLock)
		return;
	BankrollsVC *detailViewController = [[BankrollsVC alloc] initWithNibName:@"BankrollsVC" bundle:nil];
	detailViewController.managedObjectContext = managedObjectContext;
	detailViewController.callBackViewController = self;
	[self.navigationController pushViewController:detailViewController animated:YES];
}

-(IBAction)startGameButtonClicked:(id)sender
{
	if(screenLock) {
		[self startDisolveNow];
		return;
	}
	if(rotateLock)
		return;
	
	if([ProjectFunctions isOkToProceed:self.managedObjectContext delegate:self]) {
		StartNewGameVC *detailViewController = [[StartNewGameVC alloc] initWithNibName:@"StartNewGameVC" bundle:nil];
		detailViewController.managedObjectContext = managedObjectContext;
		[self.navigationController pushViewController:detailViewController animated:YES];
	}
}



-(IBAction)casinoTrackerClicked:(id)sender
{
	if(screenLock) {
		[self startDisolveNow];
		return;
	}
	if(rotateLock)
		return;
	CasinoTrackerVC *detailViewController = [[CasinoTrackerVC alloc] initWithNibName:@"CasinoTrackerVC" bundle:nil];
	detailViewController.managedObjectContext = managedObjectContext;
	[self.navigationController pushViewController:detailViewController animated:YES];
}	


-(void)moreButtonClicked:(id)sender {
	if(screenLock) {
		[self startDisolveNow];
		return;
	}
	if(rotateLock)
		return;
	self.largeGraph.alpha=0;

	DatabaseManage *detailViewController = [[DatabaseManage alloc] initWithNibName:@"DatabaseManage" bundle:nil];
	detailViewController.managedObjectContext = managedObjectContext;
	detailViewController.callBackViewController = self;
	[self.navigationController pushViewController:detailViewController animated:YES];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if(alertView.tag==104 && buttonIndex != alertView.cancelButtonIndex) {
		UpgradeVC *detailViewController = [[UpgradeVC alloc] initWithNibName:@"UpgradeVC" bundle:nil];
		detailViewController.managedObjectContext = managedObjectContext;
		[self.navigationController pushViewController:detailViewController animated:YES];
	}
	if(buttonIndex==1 && alertViewNum==1) {
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"user_id = 0 AND status = %@", @"In Progress"];
		NSArray *items = [CoreDataLib selectRowsFromEntity:@"GAME" predicate:predicate sortColumn:@"startTime" mOC:self.managedObjectContext ascendingFlg:NO];
		GameInProgressVC *detailViewController = [[GameInProgressVC alloc] initWithNibName:@"GameInProgressVC" bundle:nil];
		detailViewController.managedObjectContext = managedObjectContext;
		detailViewController.mo = [items objectAtIndex:0];
		detailViewController.newGameStated=NO;
		[self.navigationController pushViewController:detailViewController animated:YES];
	}
	if(alertViewNum==2) {
		// upgrade to pro!
		NSString *address = @"http://itunes.apple.com/app/poker-track-pro/id475160109?mt=8";
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:address]];
	}
	if(alertViewNum==99) {
		AppInitialVC *detailViewController = [[AppInitialVC alloc] initWithNibName:@"AppInitialVC" bundle:nil];
		detailViewController.managedObjectContext = managedObjectContext;
		[self.navigationController pushViewController:detailViewController animated:YES];
	}
	if(alertViewNum==199) {
		[ProjectFunctions setUserDefaultValue:@"Y" forKey:@"UpgradeCheck"];
		UpgradeVC *detailViewController = [[UpgradeVC alloc] initWithNibName:@"UpgradeVC" bundle:nil];
		detailViewController.managedObjectContext = managedObjectContext;
		[self.navigationController pushViewController:detailViewController animated:YES];
	}
	if(alertViewNum==2017) {
		GamesVC *detailViewController = [[GamesVC alloc] initWithNibName:@"GamesVC" bundle:nil];
		detailViewController.managedObjectContext = managedObjectContext;
		[self.navigationController pushViewController:detailViewController animated:YES];
	}
}


-(void)enterNewFilterValue:(NSString *)filterName buttonNumber:(int)buttonNumber
{
	NSArray *filterList = [NSArray arrayWithObjects:
						   filterName,
						   NSLocalizedString(@"All", nil), //@"All Game Types",
						   NSLocalizedString(@"All", nil), // games
						   NSLocalizedString(@"All", nil), //@"All Limits",
						   NSLocalizedString(@"All", nil), //@"All Stakes",
						   NSLocalizedString(@"All", nil), //@"All Locations",
						   NSLocalizedString(@"All", nil), //@"All Bankrolls",
						   NSLocalizedString(@"All", nil), //@"All Types",
						   [NSString stringWithFormat:@"%d", buttonNumber],
						   filterName,
						   nil];
	[ProjectFunctions insertRecordIntoEntity:managedObjectContext EntityName:@"FILTER" valueList:filterList];
}

-(void)populateRefDataForTable:(NSString *)table segment:(int)segment {
	NSArray *values = [ProjectFunctions getArrayForSegment:segment];
	for(NSString *value in values) {
		[CoreDataLib insertAttributeManagedObject:table valueList:[NSArray arrayWithObjects:value, nil] mOC:self.managedObjectContext];
	}
}

-(void)setupData
{
	NSArray *items = [CoreDataLib selectRowsFromTable:@"GAMETYPE" mOC:managedObjectContext];
	if([items count]==0) {
		NSLog(@"Setting up Data!");
		[CoreDataLib insertAttributeManagedObject:@"TYPE" valueList:[NSArray arrayWithObjects:@"Cash", nil] mOC:self.managedObjectContext];
		[CoreDataLib insertAttributeManagedObject:@"TYPE" valueList:[NSArray arrayWithObjects:@"Tournament", nil] mOC:self.managedObjectContext];

		[self populateRefDataForTable:@"GAMETYPE" segment:0];
		[self populateRefDataForTable:@"STAKES" segment:1];
		[self populateRefDataForTable:@"LIMIT" segment:2];
		[self populateRefDataForTable:@"TOURNAMENT" segment:3];
		[self populateRefDataForTable:@"BANKROLL" segment:4];
		[self populateRefDataForTable:@"LOCATION" segment:5];
		
		[CoreDataLib insertAttributeManagedObject:@"YEAR" valueList:[NSArray arrayWithObjects:[[NSDate date] convertDateToStringWithFormat:@"yyyy"], nil] mOC:self.managedObjectContext];

		[self enterNewFilterValue:@"This Month" buttonNumber:1];
		[self enterNewFilterValue:@"Last Month" buttonNumber:2];
		
		
	}

}


-(void)updateMoneyLabel:(UILabel *)localLabel money:(int)money
{
	[localLabel performSelectorOnMainThread:@selector(setText:) withObject:[ProjectFunctions convertIntToMoneyString:money] waitUntilDone:NO];

	UIColor *labelColor = (money<0)?[UIColor orangeColor]:[UIColor greenColor];
	
	[localLabel performSelectorOnMainThread:@selector(setTextColor:) withObject:labelColor waitUntilDone:NO];

}




-(void)displayBankrollLabels:(NSManagedObjectContext *)contextLocal {
	NSString *bankrollName = [ProjectFunctions getUserDefaultValue:@"bankrollDefault"];
	if([bankrollName length]==0 || [bankrollName isEqualToString:@"Default"])
		bankrollName = @"Bankroll";

	if ([@"Y" isEqualToString:[ProjectFunctions getUserDefaultValue:@"bankrollSwitch"]]) {
		[self updateMoneyLabel:bankrollLabel money:[[ProjectFunctions getUserDefaultValue:@"defaultBankroll"] intValue]];
		[bankrollNameLabel performSelectorOnMainThread:@selector(setText:) withObject:[NSString stringWithFormat:@"%@:", bankrollName] waitUntilDone:NO];
	} else {
		
		NSDate *startTime = [ProjectFunctions getFirstDayOfMonth:[NSDate date]];
		NSString *formatString = @"startTime >= %@ AND startTime < %@";
		NSPredicate *predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"%@ AND %@", @"1=1", formatString], startTime, [NSDate date]];
		int winnings = [[CoreDataLib getGameStat:contextLocal dataField:@"winnings" predicate:predicate] intValue];

		[self updateMoneyLabel:bankrollLabel money:winnings];
		[bankrollNameLabel performSelectorOnMainThread:@selector(setText:) withObject:[NSString stringWithFormat:@"%@:", [ProjectFunctions getMonthFromDate:[NSDate date]]] waitUntilDone:NO];
	}
}

-(void)doTheHardWork {
	@autoreleasepool {
		//		[NSThread sleepForTimeInterval:3];
		
		NSManagedObjectContext *contextLocal = [CoreDataLib getLocalContext];
		
		int thisYear = [[ProjectFunctions getUserDefaultValue:@"maxYear"] intValue];
		int currentYear = [[[NSDate date] convertDateToStringWithFormat:@"yyyy"] intValue];
		
		if(thisYear==0 || thisYear>currentYear)
			thisYear = currentYear;
		
		NSString *basicPred = [ProjectFunctions getBasicPredicateString:thisYear type:@"All"];
		NSPredicate *predicate = [NSPredicate predicateWithFormat:basicPred];
		
		[self updateMoneyLabel:yearTotalLabel money:[[CoreDataLib getGameStat:contextLocal dataField:@"winnings" predicate:predicate] intValue]];
		
		[self displayBankrollLabels:contextLocal];
		
		NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"user_id = 0 AND status = %@", @"In Progress"];
		NSArray *items = [CoreDataLib selectRowsFromEntity:@"GAME" predicate:predicate2 sortColumn:@"name" mOC:contextLocal ascendingFlg:YES];
		int badgeCount = (int)items.count;
		[UIApplication sharedApplication].applicationIconBadgeNumber=badgeCount;
		
		if(badgeCount==0) {
			openGamesLabel.alpha=0;
			openGamesCircle.alpha=0;
		} else {
			openGamesLabel.alpha=1;
			openGamesCircle.alpha=1;
			openGamesLabel.text = [NSString stringWithFormat:@"%d", badgeCount];
		}
		
		//----- last 10 games
		predicate = [NSPredicate predicateWithFormat:@"user_id = '0' AND status = 'Completed'"];
		NSString *analysis1 = [CoreDataLib getGameStatWithLimit:contextLocal dataField:@"analysis1" predicate:predicate limit:10];
		NSArray *values = [analysis1 componentsSeparatedByString:@"|"];
		double amountRisked = [[values stringAtIndex:0] doubleValue];
		double netIncome = [[values stringAtIndex:5] doubleValue];
		
		[analysisButton setBackgroundImage:[ProjectFunctions getPlayerTypeImage:amountRisked winnings:netIncome] forState:UIControlStateNormal];
		yearLabel.alpha=0.2;
		yearLabel.text = [NSString stringWithFormat:@"%d", thisYear];
		smallYearLabel.text = [NSString stringWithFormat:@"%d:", thisYear];
		
		[self updateMainGraphWithCOntext:contextLocal year:thisYear];
		
		refreshButton.alpha=0;
		[self.activityIndicatorData stopAnimating];
	}
}

-(void)updateMainGraphWithCOntext:(NSManagedObjectContext *)contextLocal year:(int)year {
	NSString *predString = [ProjectFunctions getBasicPredicateString:year type:@"All"];
	NSPredicate *pred = [NSPredicate predicateWithFormat:predString];
	
	self.largeGraph.image = [ProjectFunctions plotStatsChart:contextLocal predicate:pred displayBySession:displayBySession];
	if(toggleMode==2) {
		self.graphChart.image = [UIImage imageNamed:@"logo2.png"];
		refreshButton.alpha=0;
		yearLabel.alpha=0;
	} else {
		self.graphChart.image = self.largeGraph.image;
		refreshButton.alpha=1;
		yearLabel.alpha=0.2;
	}
}

-(void)calculateStats
{
	[self.activityIndicatorData startAnimating];
	[self performSelectorInBackground:@selector(doTheHardWork) withObject:nil];
}


-(void)findMinAndMaxYear {
    NSString *minYear = [[NSDate date] convertDateToStringWithFormat:@"yyyy"];
    NSString *maxYear = @"";
    
    NSArray *games = [CoreDataLib selectRowsFromEntity:@"GAME" predicate:nil sortColumn:@"startTime" mOC:managedObjectContext ascendingFlg:YES];
    if([games count]>0) {
        NSDate *startTime = [[games objectAtIndex:0] valueForKey:@"startTime"];
        minYear = [startTime convertDateToStringWithFormat:@"yyyy"];
        NSDate *startTimeMax = [[games objectAtIndex:[games count]-1] valueForKey:@"startTime"];
        maxYear = [startTimeMax convertDateToStringWithFormat:@"yyyy"];
		
		if([ProjectFunctions getUserDefaultValue:@"scrub2017"].length==0 && [ProjectFunctions getUserDefaultValue:@"v11.5"].length==0) {
			alertViewNum=2017;
			[ProjectFunctions setUserDefaultValue:@"Y" forKey:@"v11.5"];
			[ProjectFunctions showAlertPopupWithDelegate:@"Notice" message:@"Version 11.5 update notice. Game data needs to be scrubbed." delegate:self];
		}
    }
	self.displayYear = [maxYear intValue];
    if(self.displayYear==0)
        self.displayYear = [[[NSDate date] convertDateToStringWithFormat:@"yyyy"] intValue];
    
    int currentMinYear = [[ProjectFunctions getUserDefaultValue:@"minYear2"] intValue];
    int currentMaxYear = [[ProjectFunctions getUserDefaultValue:@"maxYear"] intValue];
	
	if(currentMinYear != [minYear intValue]) {
		NSLog(@"!!!Setting year to: %@", minYear);
        [ProjectFunctions setUserDefaultValue:minYear forKey:@"minYear2"];
	}
	if(currentMaxYear != [maxYear intValue]) {
		NSLog(@"!!!Setting year to: %@", maxYear);
        [ProjectFunctions setUserDefaultValue:maxYear forKey:@"maxYear"];
	}
	
}

-(void) setReturningValue:(NSString *) value2 {
	
	NSString *value = [NSString stringWithFormat:@"%@", [ProjectFunctions getUserDefaultValue:@"returnValue"]];
	[ProjectFunctions setUserDefaultValue:value forKey:@"defaultBankroll"];
	int bankroll = [value intValue];
	bankrollLabel.text = [ProjectFunctions convertIntToMoneyString:bankroll];
	
}


- (IBAction) statsPressed: (id) sender 
{
	if(screenLock) {
		[self startDisolveNow];
		return;
	}
	if(rotateLock)
		return;
	StatsPage *detailViewController = [[StatsPage alloc] initWithNibName:@"StatsPage" bundle:nil];
	detailViewController.managedObjectContext = managedObjectContext;
	detailViewController.hideMainMenuButton = YES;
	detailViewController.gameType = [ProjectFunctions getUserDefaultValue:@"gameTypeDefault"];
	detailViewController.displayYear = displayYear;
	[self.navigationController pushViewController:detailViewController animated:YES];
}

- (IBAction) cashPressed: (id) sender 
{
	if(screenLock) {
		[self startDisolveNow];
		return;
	}
	if(rotateLock)
		return;
    
    
	GamesVC *detailViewController = [[GamesVC alloc] initWithNibName:@"GamesVC" bundle:nil];
	detailViewController.managedObjectContext = managedObjectContext;
	detailViewController.displayYear = displayYear;
	detailViewController.showMainMenuButton=NO;
	[self.navigationController pushViewController:detailViewController animated:YES];
}

- (IBAction) friendsPressed: (id) sender 
{
	if(screenLock) {
		[self startDisolveNow];
		return;
	}
	if(rotateLock)
		return;
	
	if([ProjectFunctions isLiteVersion]) {
		[ProjectFunctions showConfirmationPopup:@"Upgrade Now?" message:@"You will need to upgrade to use this feature." delegate:self tag:104];
		return;
	}
	UniverseTrackerVC *detailViewController = [[UniverseTrackerVC alloc] initWithNibName:@"UniverseTrackerVC" bundle:nil];
	detailViewController.managedObjectContext = managedObjectContext;
	[self.navigationController pushViewController:detailViewController animated:YES];
}

- (IBAction) oddsPressed: (id) sender
{
	if(screenLock) {
		[self startDisolveNow];
		return;
	}
	if(rotateLock)
		return;
	OddsCalculatorVC *detailViewController = [[OddsCalculatorVC alloc] initWithNibName:@"OddsCalculatorVC" bundle:nil];
	detailViewController.managedObjectContext=managedObjectContext;
	detailViewController.bigHandsFlag = NO;
	[self.navigationController pushViewController:detailViewController animated:YES];
}

- (IBAction) handsPressed: (id) sender 
{
	if(screenLock) {
		[self startDisolveNow];
		return;
	}
	if(rotateLock)
		return;
	
	if([ProjectFunctions isLiteVersion]) {
		[ProjectFunctions showConfirmationPopup:@"Upgrade Now?" message:@"You will need to upgrade to use this feature." delegate:self tag:104];
		return;
	}

    if([[ProjectFunctions getUserDefaultValue:@"userName"] length]>0) {
        self.forumNumCircle.alpha=0;
        self.forumNumLabel.alpha=0;
        ForumVC *detailViewController = [[ForumVC alloc] initWithNibName:@"ForumVC" bundle:nil];
        detailViewController.managedObjectContext = managedObjectContext;
        [self.navigationController pushViewController:detailViewController animated:YES];
    } else {
        [ProjectFunctions showAlertPopup:@"Notice" message:@"You must be signed in to visit the forum. Click the Gear button above."];
    }
}

- (IBAction) moreTrackersPressed: (id) sender
{
	if(rotateLock)
		return;
	MoreTrackersVC *detailViewController = [[MoreTrackersVC alloc] initWithNibName:@"MoreTrackersVC" bundle:nil];
	detailViewController.managedObjectContext = managedObjectContext;
	[self.navigationController pushViewController:detailViewController animated:YES];
}


- (void)viewDidUnload {
    [super viewDidUnload];
	self.largeGraph.alpha=0;

    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}





@end
