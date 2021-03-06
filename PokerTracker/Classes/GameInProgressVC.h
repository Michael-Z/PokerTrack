//
//  GameInProgressVC.h
//  PokerTracker
//
//  Created by Rick Medved on 10/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NetUserObj.h"
#import "TemplateVC.h"


@interface GameInProgressVC : TemplateVC {
	//---Passed In----------------------------
    NSManagedObjectContext *managedObjectContext;
	NSManagedObject *mo;
	IBOutlet UITableView *mainTableView;

	//---XIB----------------------------
	IBOutlet UIButton *foodButton;
	IBOutlet UIButton *tokesButton;
	IBOutlet UIButton *chipStackButton;
	IBOutlet UIButton *rebuyButton;
	IBOutlet UIButton *pauseButton;
	IBOutlet UIButton *doneButton;
	IBOutlet UIButton *editButton;
	IBOutlet UIButton *notesButton;
	IBOutlet UIButton *friendButton;
	IBOutlet UIButton *graphButton;
	
	NetUserObj *netUserObj;
	
	IBOutlet UILabel *onBreakLabel;
	IBOutlet UILabel *timerLabel;
	IBOutlet UILabel *buyinLabel;
	IBOutlet UILabel *rebuysLabel;
	IBOutlet UILabel *rebuyAmountLabel;
	IBOutlet UILabel *hourlyLabel;
	IBOutlet UILabel *grossLabel;
	IBOutlet UILabel *takehomeLabel;
	IBOutlet UILabel *profitLabel;
	IBOutlet UILabel *pauseTimerLabel;
	IBOutlet UILabel *gameTypeLabel;
	IBOutlet UILabel *clockLabel;

	IBOutlet UILabel *foodLabel;
	IBOutlet UILabel *tokesLabel;
	IBOutlet UILabel *currentStackLabel;
	
	IBOutlet UIImageView *grayPauseBG;
	IBOutlet UIImageView *infoImage;
	IBOutlet UIImageView *playerTypeImage;
	IBOutlet UITextView *infoText;
	IBOutlet UIActivityIndicatorView *activityIndicator;
	
	//---Gloabls----------------------------
	int selectedObjectForEdit;
    int popupViewNumber;
	BOOL infoScreenShown;
	BOOL gameInProgress;
	BOOL gamePaused;
	BOOL cashUpdatedFlg;
	BOOL addOnFlg;
	BOOL waitForResponse;
    NSString *messageString;
    NSString *userData;
    NSDate *startDate;
    double netProfit;
    int totalBreakSeconds;
}

- (IBAction) foodButtonPressed: (id) sender;
- (IBAction) tokesButtonPressed: (id) sender;
- (IBAction) chipsButtonPressed: (id) sender;
- (IBAction) rebuyButtonPressed: (id) sender; 
- (IBAction) pauseButtonPressed: (id) sender;
- (IBAction) doneButtonPressed: (id) sender; 
- (IBAction) editButtonPressed: (id) sender;
- (IBAction) hudButtonPressed: (id) sender;
- (IBAction) notesButtonPressed: (id) sender;
- (IBAction) graphButtonPressed: (id) sender;
- (IBAction) friendButtonPressed: (id) sender;
- (IBAction) cancelButtonPressed: (id) sender;

-(void)refreshScreen;
-(void)setUpScreen;

@property (atomic, strong) NSManagedObject *mo;

@property (atomic, strong) UIButton *foodButton;
@property (atomic, strong) UIButton *tokesButton;
@property (atomic, strong) UIButton *chipStackButton;
@property (atomic, strong) UIButton *rebuyButton;
@property (atomic, strong) UIButton *pauseButton;
@property (atomic, strong) UIButton *doneButton;
@property (atomic, strong) UIButton *graphButton;
@property (atomic, strong) UIButton *editButton;
@property (atomic, strong) UIButton *friendButton;
@property (atomic, strong) UIButton *notesButton;
@property (atomic, strong) IBOutlet UIButton *hudButton;
@property (atomic, strong) IBOutlet UIButton *playerTypeButton;
@property (atomic, strong) IBOutlet UIButton *numberPlayersButton;
@property (atomic, strong) IBOutlet UIButton *numberSpotPaidButton;
@property (atomic, strong) IBOutlet UILabel *numberSpotPaidLabel;
@property (atomic, strong) IBOutlet UILabel *numberPlayersLabel;

@property (atomic, strong) IBOutlet PopupView *playersPopupView;
@property (atomic, strong) IBOutlet PopupView *tournamentEndPopupView;
@property (atomic, strong) NetUserObj *netUserObj;

@property (atomic, strong) UILabel *foodLabel;
@property (atomic, strong) UILabel *tokesLabel;
@property (atomic, strong) UILabel *currentStackLabel;
@property (atomic, strong) UILabel *gameTypeLabel;
@property (atomic, strong) UILabel *clockLabel;
@property (atomic, copy) NSString *messageString;


@property (atomic, strong) UILabel *onBreakLabel;
@property (atomic, strong) UILabel *timerLabel;
@property (atomic, strong) UILabel *buyinLabel;
@property (atomic, strong) UILabel *rebuysLabel;
@property (atomic, strong) UILabel *rebuyAmountLabel;
@property (atomic, strong) UILabel *hourlyLabel;
@property (atomic, strong) UILabel *grossLabel;
@property (atomic, strong) UILabel *takehomeLabel;
@property (atomic, strong) UILabel *profitLabel;
@property (atomic, strong) UILabel *pauseTimerLabel;
@property (atomic, strong) UIImageView *playerTypeImage;

@property (atomic, strong) UIImageView *grayPauseBG;
@property (atomic, strong) UIImageView *infoImage;
@property (atomic, strong) UITextView *infoText;

@property (atomic) int selectedObjectForEdit;
@property (atomic) int popupViewNumber;
@property (atomic) int waitTimerCount;
@property (atomic) BOOL newGameStated;
@property (atomic) BOOL infoScreenShown;
@property (atomic) BOOL gameInProgress;
@property (atomic) BOOL cashUpdatedFlg;
@property (atomic) BOOL gamePaused;
@property (atomic) BOOL addOnFlg;
@property (atomic) BOOL viewLoadedFlg;

@property (atomic, strong) UIActivityIndicatorView *activityIndicator;
@property (atomic, strong) NSMutableArray *valuesArray;
@property (atomic, strong) NSMutableArray *colorsArray;
@property (atomic, copy) NSString *userData;

@property (atomic, strong) NSDate *startDate;
@property (atomic) double netProfit;
@property (atomic) int totalBreakSeconds;





@end
