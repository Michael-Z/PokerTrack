//
//  CustomSegment.m
//  WealthTracker
//
//  Created by Rick Medved on 10/29/15.
//  Copyright (c) 2015 Rick Medved. All rights reserved.
//

#import "CustomSegment.h"
#import "ProjectFunctions.h"

@implementation CustomSegment

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) {
		[self commonInit];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (self) {
		[self commonInit];
	}
	return self;
}

- (void)commonInit
{
//	[self setTintColor:[UIColor colorWithRed:(6/255.0) green:(122/255.0) blue:(180/255.0) alpha:1.0]];
	[self setTintColor:[UIColor colorWithRed:0 green:.4 blue:0 alpha:1.0]];
	
	self.layer.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1].CGColor;
	self.layer.cornerRadius = 4;
	self.layer.borderColor = [UIColor blackColor].CGColor;
	self.layer.borderWidth = 1;
	
	UIFont *font = [UIFont fontWithName:kFontAwesomeFamilyName size:14.f];
	NSMutableDictionary *attribsNormal;
	attribsNormal = [NSMutableDictionary dictionaryWithObjectsAndKeys:font, UITextAttributeFont, [UIColor blackColor], UITextAttributeTextColor, nil];
	
	NSMutableDictionary *attribsSelected;
	attribsSelected = [NSMutableDictionary dictionaryWithObjectsAndKeys:font, UITextAttributeFont, [UIColor whiteColor], UITextAttributeTextColor, nil];
	
	[self setTitleTextAttributes:attribsNormal forState:UIControlStateNormal];
	[self setTitleTextAttributes:attribsSelected forState:UIControlStateSelected];
	
	[self changeSegment];
}

-(void)turnIntoTop5Segment {
	if(self.numberOfSegments==3) {
		[self setTitle:[NSString stringWithFormat:@"%@ %@", [NSString fontAwesomeIconStringForEnum:FAStar], NSLocalizedString(@"Game", nil)] forSegmentAtIndex:0];
		[self setTitle:[NSString stringWithFormat:@"%@ %@", [NSString fontAwesomeIconStringForEnum:FACalendar], NSLocalizedString(@"month", nil)] forSegmentAtIndex:1];
		[self setTitle:[NSString stringWithFormat:@"%@ %@", [NSString fontAwesomeIconStringForEnum:FAcalendarCheckO], NSLocalizedString(@"Quarter", nil)] forSegmentAtIndex:2];
	}
}

-(void)turnIntoGameSegment {
	if(self.numberOfSegments==3) {
		[self setTitle:[NSString stringWithFormat:@"%@ + %@", [NSString fontAwesomeIconStringForEnum:FAMoney], [NSString fontAwesomeIconStringForEnum:FATrophy]] forSegmentAtIndex:0];
		[self setTitle:[NSString fontAwesomeIconStringForEnum:FAMoney] forSegmentAtIndex:1];
		[self setTitle:[NSString fontAwesomeIconStringForEnum:FATrophy] forSegmentAtIndex:2];
	}
}

-(void)gameSegmentChanged {
	int number = (int)self.selectedSegmentIndex;
	if(self.numberOfSegments==2)
		number++;
	
	if(number==0)
		[self setTintColor:[UIColor colorWithRed:0 green:.5 blue:0 alpha:1]];
	else if(number==1)
		[self setTintColor:[UIColor colorWithRed:.9 green:.7 blue:0 alpha:1]];
	else
		[self setTintColor:[UIColor colorWithRed:0 green:.7 blue:.9 alpha:1]];
}

-(void)changeSegment {
	return;;
	NSString *checkMark = [NSString stringWithFormat:@"%@ ", @"\u2705"];
	for(int i=0; i<self.numberOfSegments; i++) {
		NSString *title = [self titleForSegmentAtIndex:i];
		[self setTitle:[title stringByReplacingOccurrencesOfString:checkMark withString:@""] forSegmentAtIndex:i];
	}
		
	NSString *checkMarkTitle = [NSString stringWithFormat:@"%@%@", checkMark, [self titleForSegmentAtIndex:self.selectedSegmentIndex]];
	[self setTitle:checkMarkTitle forSegmentAtIndex:self.selectedSegmentIndex];
}

@end
