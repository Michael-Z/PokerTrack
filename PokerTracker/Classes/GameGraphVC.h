//
//  GameGraphVC.h
//  PokerTracker
//
//  Created by Rick Medved on 3/1/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TemplateVC.h"


@interface GameGraphVC : TemplateVC

@property (atomic, strong) NSManagedObject *mo;
@property (atomic, strong) IBOutlet UILabel *faLabel;
@property (atomic, strong) IBOutlet UILabel *dateLabel;
@property (atomic, strong) IBOutlet UILabel *timeLabel;
@property (atomic, strong) IBOutlet UILabel *locationLabel;
@property (atomic, strong) IBOutlet UILabel *netLabel;
@property (atomic, strong) IBOutlet UIImageView *gamePPRView;
@property (atomic, strong) IBOutlet UIImageView *gameGraphView;
@property (atomic, strong) IBOutlet UIImageView *arrow;
@property (atomic, strong) IBOutlet UILabel *chipAmountLabel;
@property (atomic, strong) IBOutlet UILabel *chipTimeLabel;
@property (atomic, strong) IBOutlet UILabel *pprLabel;
@property (atomic, strong) IBOutlet UIButton *notesButton;
@property (atomic, strong) IBOutlet UIButton *hudButton;
@property (atomic, strong) IBOutlet UIButton *deleteCommentButton;
@property (atomic, strong) IBOutlet UILabel *commentTimeLabel;
@property (atomic, strong) IBOutlet UILabel *commentProfitLabel;
@property (atomic, strong) IBOutlet UIView *bottomView;
@property (atomic, strong) IBOutlet UITextField *textField;

@property (atomic) BOOL viewEditable;
@property (atomic) BOOL showMainMenuFlg;
@property (atomic) BOOL touchesFlg;
@property (atomic) BOOL notesFlg;
@property (atomic) int closestPoint;

@property (atomic, strong) NSMutableArray *cellRowsArray;
@property (atomic, strong) NSArray *pointsArray;

- (IBAction) notesButtonPressed: (id) sender;
- (IBAction) enterButtonPressed: (id) sender;
- (IBAction) pprButtonPressed: (id) sender;
- (IBAction) hudButtonPressed: (id) sender;
- (IBAction) deleteCommentButtonPressed: (id) sender;

@end
