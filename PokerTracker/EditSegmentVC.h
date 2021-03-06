//
//  EditSegmentVC.h
//  PokerTracker
//
//  Created by Rick Medved on 7/6/17.
//
//

#import "TemplateVC.h"

@interface EditSegmentVC : TemplateVC

@property (nonatomic, strong) UIViewController *callBackViewController;
@property (nonatomic, strong) IBOutlet UIButton *deleteButton;
@property (nonatomic, strong) IBOutlet UIButton *addButton;
@property (nonatomic, strong) IBOutlet UIButton *editButton;
@property (nonatomic, strong) UIBarButtonItem *selectButton;
@property (nonatomic, strong) NSMutableArray *list;
@property (nonatomic, strong) NSMutableDictionary *listDict;
@property (nonatomic, strong) NSString *entity;
@property (nonatomic, strong) NSString *initialDateValue;
@property (nonatomic, strong) NSString *databaseField;
@property (nonatomic) int option;
@property (nonatomic) BOOL optionSelectedFlg;
@property (nonatomic) BOOL readyOnlyFlg;
@property (nonatomic) int rowNum;
@property (nonatomic) int selectedAction;

- (IBAction)deleteButtonPressed:(id)sender;
- (IBAction)addButtonPressed:(id)sender;
- (IBAction)editButtonPressed:(id)sender;

@end
