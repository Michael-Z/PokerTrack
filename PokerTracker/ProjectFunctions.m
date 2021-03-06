    //
//  ProjectFunctions.m
//  PokerTracker
//
//  Created by Rick Medved on 10/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ProjectFunctions.h"
#import "CoreDataLib.h"
#import "NSDate+ATTDate.h"
#import "NSString+ATTString.h"
#import "QuadFieldTableViewCell.h"
#import "QuadWithImageTableViewCell.h"
#import "WebServicesFunctions.h"
#import "NSArray+ATTArray.h"
#import "NSString+ATTString.h"
#import "NSData+ATTData.h"
#import "GameCell.h"
#import "ChipStackObj.h"
#import "ThemeColorObj.h"


// attrib03 <--- tournament num players
// attrib04 <--- tournament place finished
// FRIEND attrib_07 <--- player pics
// FRIEND attrib_08 <--- game in progress
// FRIEND attrib_09 <--- time in progress
// FRIEND attrib_10 <--- attribs in progress

@implementation ProjectFunctions

+(int)getProductionMode
{
	return kPRODMode;
}

+(BOOL)isPokerZilla {
	return NO;
}

+(NSString *)getProjectVersion
{
	return @"Version 1.0";
}

+(NSString *)getProjectDisplayVersion
{
	NSDictionary *infoDictionary = [[NSBundle mainBundle]infoDictionary];
	
	NSString *version = infoDictionary[@"CFBundleShortVersionString"];
//	NSString *build = infoDictionary[(NSString*)kCFBundleVersionKey];
	
	UIDevice *device = [UIDevice currentDevice];
//    NSString *systemName = [device systemName];
//    NSString *systemVersion = [device systemVersion];
    NSString *model = [device model];
    
//    NSString *softwareVersion = (__bridge NSString *)CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle(), kCFBundleVersionKey); // added RM
	
    NSString *lite = ([self isLiteVersion])?@"L":@"";
	if([ProjectFunctions isPokerZilla])
		lite = @"Z";
    
    return [NSString stringWithFormat:@"Version %@%@ (%@)", version, lite, model];
}

+(float)projectVersionNumber {
	NSDictionary *infoDictionary = [[NSBundle mainBundle]infoDictionary];
	NSString *version = infoDictionary[@"CFBundleShortVersionString"];
	return [version floatValue];
}

+(BOOL)isLiteBundle {
	NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
	return [@"com.PockerTrack.lite" isEqualToString:bundleIdentifier];
}

+(BOOL)isLiteVersion
{
	if([self isLiteBundle] && [ProjectFunctions getUserDefaultValue:@"proVersion101"].length==0)
		return YES;
	else
		return NO;
}

+(NSString *)getAppID
{
	if([ProjectFunctions isPokerZilla])
		return @"928197798";

	if([self isLiteBundle])
		return @"488925221";
	else
		return @"475160109";
}

+(void)writeAppReview
{
	NSString *appId = [ProjectFunctions getAppID];
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://itunes.apple.com/us/app/apple-store/id%@?mt=8", appId]]];
}

+(BOOL)useThreads
{
    NSString *flag = [ProjectFunctions getUserDefaultValue:@"bgThreads"];
    if([flag length]==0)
        return YES;
    else
        return NO;
}


+(NSArray *)getFieldListForVersion:(NSString *)version type:(NSString *)type
{
	if([type isEqualToString:@"FRIEND"]) {
		if([version isEqualToString:@"Version 1.0"]) {
			return [NSArray arrayWithObjects:@"mostRecentDate", 
					@"gamesThisYear", @"gamesLastYear", @"gamesThisMonth", @"gamesLast10", 
					@"streakThisYear", @"streakLastYear", @"streakThisMonth", @"streakLast10", 
					@"gameCountThisYear", @"gameCountLastYear", @"gameCountThisMonth", @"gameCountLast10", 
					@"profitThisYear", @"profitLastYear", @"profitThisMonth", @"profitLast10", 
					@"hoursThisYear", @"hoursLastYear", @"hoursThisMonth", 
					@"hourlyThisYear", @"hourlyThisMonth", @"hourlyLast10",
					@"attrib_01", @"attrib_02", @"attrib_03", @"attrib_04", @"attrib_05", @"attrib_06", 
					@"attrib_07", @"attrib_08", @"attrib_09", @"attrib_10", @"attrib_11", @"attrib_12", 
				nil];
		}
	}
	return nil;
}



+(NSArray *)sortArray:(NSMutableArray *)list
{
	[list sortUsingSelector:@selector(compare:)];
	return list;
}

+(NSArray *)sortArrayDescending:(NSArray *)list
{
	return [list sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:nil ascending:NO]]];
}

+(NSString *)getWinLossStreakString:(int)streak
{
	if(streak==0)
		return @"-";
	return (streak>0)?[NSString stringWithFormat:@"Win %d", streak]:[NSString stringWithFormat:@"Lose %d", (streak*-1)];
}

+(NSString *)hourlyStringFromProfit:(double)profit hours:(float)hours {
	if(hours>0) {
		float hourly = profit/hours;
		return [NSString stringWithFormat:@"%@/hr", [ProjectFunctions smallLabelForMoney:hourly totalMoneyRange:hourly]];
	} else
		return @"-";
}

+(NSString *)pprStringFromProfit:(double)profit risked:(double)risked {
	if(risked==0)
		return @"-";
	else {
		int ppr = round(100*(profit+risked)/risked-100);
		return [NSString stringWithFormat:@"%d%% (%@)", ppr, [ProjectFunctions getPlayerTypelabel:risked winnings:profit]];
	}
}

+(UIColor *)colorForProfit:(double)profit {
	if(profit==0)
		return [UIColor blackColor];
	return (profit>0)?[UIColor colorWithRed:0 green:.5 blue:0 alpha:1]:[UIColor redColor];
}

+ (NSString *)escapeQuotes:(NSString *)string 
{
	return [string stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
}

+(NSDate *)getFirstDayOfMonth:(NSDate *)thisDay
{
	NSString *currentMonth = [thisDay convertDateToStringWithFormat:@"MM"];
	NSString *currentYear = [thisDay convertDateToStringWithFormat:@"yyyy"];
	NSString *Day1 = [NSString stringWithFormat:@"%@/01/%@", currentMonth, currentYear];
	
	return [Day1 convertStringToDateWithFormat:@"MM/dd/yyyy"];
}

+(void)displayTimeFrameLabel:(UILabel *)label mOC:(NSManagedObjectContext *)mOC buttonNum:(int)buttonNum timeFrame:(NSString *)timeFrame {
	
	if([timeFrame isEqualToString:NSLocalizedString(@"LifeTime", nil)] || [timeFrame intValue]>0) {
		label.text=timeFrame;
		return;
	}
	
	NSDate *startTime = [NSDate date];
	NSDate *endTime = [NSDate date];
	
	if([timeFrame isEqualToString:@"*Custom*"]) {
		NSPredicate *pred = [NSPredicate predicateWithFormat:@"type = %@ AND searchNum = %d", @"Timeframe", buttonNum];
		NSArray *items = [CoreDataLib selectRowsFromEntity:@"SEARCH" predicate:pred sortColumn:nil mOC:mOC ascendingFlg:YES];
		if([items count]>0) {
			NSManagedObject *mo = [items objectAtIndex:0];
			startTime = [mo valueForKey:@"startTime"];
			endTime = [mo valueForKey:@"endTime"];
		}
	}
	
	
	if([timeFrame isEqualToString:@"Last 7 Days"])
		startTime = [[NSDate date] dateByAddingTimeInterval:-1*60*60*24*7];
	
	if([timeFrame isEqualToString:@"Last 30 Days"])
		startTime = [[NSDate date] dateByAddingTimeInterval:-1*60*60*24*30];
	
	if([timeFrame isEqualToString:@"Last 90 Days"])
		startTime = [[NSDate date] dateByAddingTimeInterval:-1*60*60*24*90];
	
	if([timeFrame isEqualToString:@"This Month"])
		startTime = [ProjectFunctions getFirstDayOfMonth:[NSDate date]];
	
	if([timeFrame isEqualToString:@"Last Month"]) {
		NSDate *day1 = [ProjectFunctions getFirstDayOfMonth:[NSDate date]];
		NSDate *lastMonth = [day1 dateByAddingTimeInterval:-1*60*60*24];
		startTime = [ProjectFunctions getFirstDayOfMonth:lastMonth];
		endTime = day1;
	}
	
	label.text = [NSString stringWithFormat:@"%@ to %@", [startTime convertDateToStringWithFormat:nil], [endTime convertDateToStringWithFormat:nil]];
	
}

+(NSPredicate *)predicateForGameSegment:(UISegmentedControl *)segment {
	NSPredicate *predicate = nil;
	if(segment.selectedSegmentIndex>0) {
		NSString *gameType = [ProjectFunctions labelForGameSegment:(int)segment.selectedSegmentIndex];
		predicate=[NSPredicate predicateWithFormat:@"user_id = 0 AND Type = %@", gameType];
	}
	return predicate;
}

+(NSPredicate *)getPredicateForFilter:(NSArray *)formDataArray mOC:(NSManagedObjectContext *)mOC buttonNum:(int)buttonNum
{
	int row_id = 0;
	NSPredicate *pred = [NSPredicate predicateWithFormat:@"button = %d", buttonNum];
	NSArray *items = [CoreDataLib selectRowsFromEntity:@"FILTER" predicate:pred sortColumn:nil mOC:mOC ascendingFlg:YES];
	if(items.count>0) {
		NSManagedObject *mo = [items objectAtIndex:0];
		row_id = [[mo valueForKey:@"row_id"] intValue];
	}
	
	NSString *predicateString = [ProjectFunctions getPredicateString:formDataArray mOC:mOC buttonNum:buttonNum];
	
	NSString *timeFrame = [formDataArray stringAtIndex:0];
	
	if([timeFrame isEqualToString:NSLocalizedString(@"LifeTime", nil)] || [timeFrame intValue]>0)
		return [NSPredicate predicateWithFormat:predicateString];
	
	NSDate *startTime = [NSDate date];
	NSDate *endTime = [NSDate date];
	
	NSLog(@"+++filter timeFrame: %@ (%d)", timeFrame, buttonNum);
	if([timeFrame isEqualToString:@"*Custom*"]) {
		NSPredicate *pred = [NSPredicate predicateWithFormat:@"type = %@ AND searchNum = %d", @"Timeframe", row_id];
		NSArray *items = [CoreDataLib selectRowsFromEntity:@"SEARCH" predicate:pred sortColumn:nil mOC:mOC ascendingFlg:YES];
		NSLog(@"+++count (%d)", (int)items.count);
		if([items count]>0) {
			NSManagedObject *mo = [items objectAtIndex:0];
			startTime = [mo valueForKey:@"startTime"];
			endTime = [mo valueForKey:@"endTime"];
		}
	}
	
	if([timeFrame isEqualToString:@"Last 7 Days"])
		startTime = [[NSDate date] dateByAddingTimeInterval:-1*60*60*24*7];
	
	if([timeFrame isEqualToString:@"Last 30 Days"])
		startTime = [[NSDate date] dateByAddingTimeInterval:-1*60*60*24*30];
	
	if([timeFrame isEqualToString:@"Last 90 Days"])
		startTime = [[NSDate date] dateByAddingTimeInterval:-1*60*60*24*90];
	
	if([timeFrame isEqualToString:@"This Month"])
		startTime = [ProjectFunctions getFirstDayOfMonth:[NSDate date]];

	if([timeFrame isEqualToString:@"Last Month"]) {
		NSDate *day1 = [ProjectFunctions getFirstDayOfMonth:[NSDate date]];
		NSDate *lastMonth = [day1 dateByAddingTimeInterval:-1*60*60*24];
		startTime = [ProjectFunctions getFirstDayOfMonth:lastMonth];
		endTime = day1;
	}
	
	NSString *formatString = @"startTime >= %@ AND startTime < %@";
	NSLog(@"+++formatString: %@ (%@) (%@) [%@]", formatString, startTime, endTime, predicateString);
	return [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"%@ AND %@", predicateString, formatString], startTime, endTime];
}

+(NSString *)getYearString:(int)year
{
	if(year>0)
		return [NSString stringWithFormat:@"%d", year];
	else 
		return NSLocalizedString(@"LifeTime", nil);
}

+(NSPredicate *)predicateForBasic:(NSString *)basicPred field:(NSString *)field value:(NSString *)value {
	NSString *fullPred = [NSString stringWithFormat:@"%@ AND %@ = %%@", basicPred, field];
	return [NSPredicate predicateWithFormat:fullPred, value];
}

+(NSString *)getBasicPredicateString:(int)year type:(NSString *)Type
{
	NSMutableString *predicateString = [NSMutableString stringWithCapacity:500];
	[predicateString appendString:@"user_id = '0'"];
	
	if(year>0)
		[predicateString appendFormat:@" AND year = '%@'", [NSString stringWithFormat:@"%d", year]];
	
	NSString *bankroll = [ProjectFunctions getUserDefaultValue:@"bankrollDefault"];
	NSString *limitBankRollGames = [ProjectFunctions getUserDefaultValue:@"limitBankRollGames"];
	if([@"YES" isEqualToString:limitBankRollGames])
		[predicateString appendFormat:@" AND bankroll = '%@'", bankroll];
	
	if([Type isEqualToString:@"Cash"] || [Type isEqualToString:@"Tournament"])
		[predicateString appendFormat:@" AND Type = '%@'", [ProjectFunctions formatForDataBase:Type]];
	
	return predicateString;
}

+(NSString *)getBasicPredicateStringNoBankroll:(int)year type:(NSString *)Type
{
	NSMutableString *predicateString = [NSMutableString stringWithCapacity:500];
	[predicateString appendString:@"user_id = '0'"];
	
	if(year>0)
		[predicateString appendFormat:@" AND year = '%@'", [NSString stringWithFormat:@"%d", year]];
	
	if([Type isEqualToString:@"Cash"] || [Type isEqualToString:@"Tournament"])
		[predicateString appendFormat:@" AND Type = '%@'", [ProjectFunctions formatForDataBase:Type]];
	
	return predicateString;
}

+(NSString *)predicateExt:(NSString *)value allValue:(NSString *)allValue field:(NSString *)field typeValue:(NSString *)typeValue mOC:(NSManagedObjectContext *)mOC buttonNum:(int)buttonNum
{
	NSString *result = @"";
	if(![value isEqualToString:allValue] && ![value isEqualToString:@"*Custom*"] && ![value isEqualToString:@"All"])
		result = [NSString stringWithFormat:@" AND %@ = '%@'", field, [ProjectFunctions formatForDataBase:value]];
	
	if([value isEqualToString:@"*Custom*"])
		result = [CoreDataLib getFieldValueForEntity:mOC entityName:@"SEARCH" field:@"searchStr" predString:[NSString stringWithFormat:@"type = '%@' AND searchNum = %d", typeValue, buttonNum] indexPathRow:0];
	
	return result;
}

+(NSString *)getPredicateString:(NSArray *)formDataArray mOC:(NSManagedObjectContext *)mOC buttonNum:(int)buttonNum
{
	NSMutableString *predicateString = [NSMutableString stringWithCapacity:500];
	int year = [[formDataArray stringAtIndex:0] intValue];
	
	NSString *pred = [ProjectFunctions getBasicPredicateString:year type:[formDataArray stringAtIndex:1]];
	if(formDataArray.count>6) {
		NSString *bankroll = [formDataArray objectAtIndex:6];
		if([bankroll isEqualToString:NSLocalizedString(@"All", nil)])
			pred = [ProjectFunctions getBasicPredicateStringNoBankroll:year type:[formDataArray stringAtIndex:1]];
	}

	[predicateString appendString:pred];
	
	if([formDataArray count]==2)
		return predicateString;

	[predicateString appendString:[ProjectFunctions predicateExt:[formDataArray stringAtIndex:2] allValue:NSLocalizedString(@"All", nil) field:@"gametype" typeValue:@"Game" mOC:mOC buttonNum:buttonNum]];
	[predicateString appendString:[ProjectFunctions predicateExt:[formDataArray stringAtIndex:3] allValue:NSLocalizedString(@"All", nil) field:@"limit" typeValue:@"Limit" mOC:mOC buttonNum:buttonNum]];
	[predicateString appendString:[ProjectFunctions predicateExt:[formDataArray stringAtIndex:4] allValue:NSLocalizedString(@"All", nil) field:@"stakes" typeValue:@"Stakes" mOC:mOC buttonNum:buttonNum]];
	[predicateString appendString:[ProjectFunctions predicateExt:[formDataArray stringAtIndex:5] allValue:NSLocalizedString(@"All", nil) field:@"location" typeValue:@"Location" mOC:mOC buttonNum:buttonNum]];
	[predicateString appendString:[ProjectFunctions predicateExt:[formDataArray stringAtIndex:6] allValue:NSLocalizedString(@"All", nil) field:@"bankroll" typeValue:@"Bankroll" mOC:mOC buttonNum:buttonNum]];
	if([formDataArray count]>7)
		[predicateString appendString:[ProjectFunctions predicateExt:[formDataArray stringAtIndex:7] allValue:NSLocalizedString(@"All", nil) field:@"tournamentType" typeValue:@"Tournament Type" mOC:mOC buttonNum:buttonNum]];
	
	
	if(kLOG)
		NSLog(@"[%@]", predicateString);
	
	return predicateString;
}

+(NSString *)convertNumberToMoneyString:(double)money
{
	if (money == round(money))
		return [self convertNumberToMoneyStringNoDec:money];
	
	NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
	[formatter setLocale:[NSLocale currentLocale]];
	[formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
	return [formatter stringFromNumber:[NSNumber numberWithDouble:money]];
}

+(NSString *)convertNumberToMoneyStringNoDec:(double)money {
	NSNumberFormatter *currencyFormatter = [[NSNumberFormatter alloc] init];
	[currencyFormatter setLocale:[NSLocale currentLocale]];
	[currencyFormatter setMaximumFractionDigits:0];
	[currencyFormatter setMinimumFractionDigits:0];
	[currencyFormatter setAlwaysShowsDecimalSeparator:NO];
	[currencyFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
	
	NSNumber *someAmount = [NSNumber numberWithDouble:money];
	NSString *string = [currencyFormatter stringFromNumber:someAmount];
	return string;
}

+(NSString *)convertNumberToMoneyStringOneDec:(double)money {
	NSNumberFormatter *currencyFormatter = [[NSNumberFormatter alloc] init];
	[currencyFormatter setLocale:[NSLocale currentLocale]];
	[currencyFormatter setMaximumFractionDigits:1];
	[currencyFormatter setMinimumFractionDigits:0];
	[currencyFormatter setAlwaysShowsDecimalSeparator:YES];
	[currencyFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
	
	NSNumber *someAmount = [NSNumber numberWithDouble:money];
	NSString *string = [currencyFormatter stringFromNumber:someAmount];
	return string;
}

+(NSString *)convertStringToMoneyString:(NSString *)moneyStr
{
	double amount = [self convertMoneyStringToDouble:moneyStr];
	return [self convertNumberToMoneyString:amount];
}

+(double)convertMoneyStringToDouble:(NSString *)moneyStr
{
	NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
	[numberFormatter setNumberStyle: NSNumberFormatterCurrencyStyle];
	NSNumber* number = [numberFormatter numberFromString:moneyStr];
	if (!number) {
		[numberFormatter setNumberStyle: NSNumberFormatterDecimalStyle];
		number = [numberFormatter numberFromString:moneyStr];
	}
	if (!number) {
		moneyStr = [moneyStr stringByReplacingOccurrencesOfString:@"$" withString:@""];
		moneyStr = [moneyStr stringByReplacingOccurrencesOfString:@"," withString:@""];
		moneyStr = [moneyStr stringByTrimmingCharactersInSet: [NSCharacterSet symbolCharacterSet]];
		moneyStr = [moneyStr stringByTrimmingCharactersInSet: [NSCharacterSet letterCharacterSet]];
		return [moneyStr doubleValue];
	}
	
	return [number doubleValue];
}

+(NSString *)convertIntToMoneyString:(double)money
{
	return [ProjectFunctions convertNumberToMoneyString:(double)money];
}

+(NSArray *)getArrayForSegment:(int)segment
{
	if(segment==0)
		return [NSArray arrayWithObjects:@"Hold'em", @"Omaha", @"Razz", @"7-Card", @"5-Card", nil];
	if(segment==1)
		return [NSArray arrayWithObjects:@"$1/$2", @"$1/$3", @"$3/$5", @"$3/$6", @"$5/$10", nil];
	if(segment==2)
		return [NSArray arrayWithObjects:@"No-Limit", @"Limit", @"Spread", @"Pot-Limit", nil];
	if(segment==3)
		return [NSArray arrayWithObjects:@"Single Table", @"Multi Table", @"Heads up", @"Rebuy", nil];
	if(segment==4) // bankroll
		return [NSArray arrayWithObjects:@"Default", nil];
	if(segment==5) // casino
		return [NSArray arrayWithObjects:@"Casino", nil];
	
	NSLog(@"EROR!!! no value for getArrayForSegment: %d", segment);
	return [NSArray arrayWithObjects:@"Whoa!", nil];
	
}

+(NSArray *)getColumnListForEntity:(NSString *)entityName type:(NSString *)type
{
	NSArray *list=nil;
	if([entityName isEqualToString:@"BIGHAND"] && [type isEqualToString:@"column"])
		list = [NSArray arrayWithObjects:
				@"winStatus", 
				@"gameDate", 
				@"player1Hand", 
				@"player2Hand",
				@"player3Hand",
				@"player4Hand",
				@"player5Hand",
				@"player6Hand",
				@"flop",
				@"turn",
				@"river",
				@"potsize",
				@"numPlayers",
				@"name",
				@"preflopAction",
				@"attrib02",
				@"turnAction",
				@"riverAction",
				@"details",
				nil];
	
	if([entityName isEqualToString:@"BIGHAND"] && [type isEqualToString:@"type"])
		list = [NSArray arrayWithObjects:
				@"text", 
				@"shortDate", 
				@"text", //1
				@"text", 
				@"text", 
				@"text", 
				@"text", 
				@"text", //6
				@"text", 
				@"text", 
				@"text", 
				@"int", 
				@"int", 
				@"text", 
				@"text", 
				@"text", 
				@"text", 
				@"text", 
				@"text", 
				nil];
	
	if([entityName isEqualToString:@"GAME"] && [type isEqualToString:@"column"])
		list = [NSArray arrayWithObjects:
				@"startTime", 
				@"endTime", 
				@"hours", 
				@"buyInAmount",
				@"rebuyAmount",
				@"foodDrinks",
				@"cashoutAmount",
				@"winnings",
				@"name",
				@"gametype",
				@"stakes",//10
				@"limit",
				@"location",
				@"bankroll",
				@"numRebuys",
				@"notes",
				@"breakMinutes",
				@"tokes",
				@"minutes",
				@"year",
				@"Type",//20
				@"status",
				@"tournamentType",
				@"user_id",
				@"weekday",
				@"month",
				@"daytime",
				@"attrib01",
				@"attrib02",
				@"tournamentSpots",
				@"tournamentFinish",//30
				@"game_id",
				@"tournamentSpotsPaid",
				nil];
	
	if([entityName isEqualToString:@"GAME"] && [type isEqualToString:@"type"])
		list = [NSArray arrayWithObjects:
				@"date", 
				@"date", 
				@"text", 
				@"float", 
				@"float", 
				@"int", 
				@"float", 
				@"float", 
				@"text",	// name
				@"text", 
				@"text", 
				@"text", 
				@"text", 
				@"text", 
				@"int", 
				@"text",	// Notes
				@"int", 
				@"int", 
				@"int", 
				@"text", // year
				@"text", 
				@"text", 
				@"text", 
				@"int", 
				@"text", 
				@"text", 
				@"text", 
				@"text",
				@"text",
				@"int",
				@"int",
				@"int",
				@"int",
				nil];

	if([entityName isEqualToString:@"FILTER"] && [type isEqualToString:@"column"])
		list = [NSArray arrayWithObjects:
				@"timeframe", 
				@"Type", 
				@"game", 
				@"limit", 
				@"stakes", 
				@"location", 
				@"bankroll", 
				@"tournamentType",
				@"button", 
				@"name", 
				nil];
	
	if([entityName isEqualToString:@"FILTER"] && [type isEqualToString:@"type"])
		list = [NSArray arrayWithObjects:
				@"text", 
				@"text", 
				@"text", 
				@"text",
				@"text",
				@"text",
				@"text",
				@"text",
				@"int",
				@"text",
				nil];

	if([entityName isEqualToString:@"FRIEND"] && [type isEqualToString:@"column"])
		list = [NSArray arrayWithObjects:
				@"lastGameDate", 
				@"created", 
				@"name",
				@"status",
				@"email",
				@"bankRoll", 
				@"user_id",
				@"gamesThisYear",
				@"gamesLastYear",
				@"gamesThisMonth",
				@"gamesLast10",
				@"streakThisYear",
				@"streakLastYear",
				@"streakThisMonth",
				@"streakLast10",
				@"gameCountThisYear",
				@"gameCountLastYear",
				@"gameCountThisMonth",
				@"gameCountLast10",
				@"profitThisYear",
				@"profitLastYear",
				@"profitThisMonth",
				@"profitLast10",
				@"hoursThisYear",
				@"hoursLastYear",
				@"hoursThisMonth",
				@"hourlyThisYear",
				@"hourlyThisMonth",
				@"hourlyLast10",
				@"attrib_01",
				@"attrib_02",
				@"attrib_03",
				@"attrib_04",
				@"attrib_05",
				@"attrib_06",
				@"attrib_07",
				@"attrib_08",
				@"attrib_09",
				@"attrib_10",
				@"attrib_11",
				@"attrib_12",
				nil];
	
	if([entityName isEqualToString:@"FRIEND"] && [type isEqualToString:@"type"])
		list = [NSArray arrayWithObjects:
				@"date",
				@"date", 
				@"text", 
				@"text",
				@"text",
				@"text",
				@"int",
				@"text",
				@"text",
				@"text",
				@"text",
				@"int",
				@"int",
				@"int",
				@"int",
				@"int",
				@"int",
				@"int",
				@"int",
				@"int",
				@"int",
				@"int",
				@"int",
				@"int",
				@"int",
				@"int",
				@"int",
				@"int",
				@"int",
				@"int",
				@"int",
				@"int",
				@"int",
				@"int",
				@"int",
				@"text",
				@"text",
				@"text",
				@"text",
				@"text",
				@"text",
				nil];
	
	if([entityName isEqualToString:@"SEARCH"] && [type isEqualToString:@"column"])
		list = [NSArray arrayWithObjects:
				@"type", 
				@"searchStr", 
				@"startTime", 
				@"endTime",
				@"checkmarkList",
				@"searchNum",
				nil];
	
	if([entityName isEqualToString:@"SEARCH"] && [type isEqualToString:@"type"])
		list = [NSArray arrayWithObjects:
				@"text", 
				@"text", 
				@"date", 
				@"date",
				@"text", 
				@"int", 
				nil];
	
	if([entityName isEqualToString:@"MESSAGE"] && [type isEqualToString:@"column"])
		list = [NSArray arrayWithObjects:
				@"friend_id", 
				@"created", 
				@"body", 
				nil];
	
	if([entityName isEqualToString:@"MESSAGE"] && [type isEqualToString:@"type"])
		list = [NSArray arrayWithObjects:
				@"int", 
				@"date", 
				@"text", 
				nil];
	
	if([entityName isEqualToString:@"EXTRA"] && [type isEqualToString:@"column"])
		list = [NSArray arrayWithObjects:
				@"type", 
				@"name", 
				@"attrib_01", 
				@"attrib_02", 
				@"attrib_03", 
				@"attrib_04", 
				@"status",
				@"user_id",
				@"player_id",
				@"looseNum",
				@"agressiveNum",
				nil];
	
	if([entityName isEqualToString:@"EXTRA"] && [type isEqualToString:@"type"])
		list = [NSArray arrayWithObjects:
				@"text", 
				@"text", 
				@"int", 
				@"int", 
				@"text", 
				@"text", 
				@"text",
				@"int",
				@"int",
				@"int",
				@"int",
				nil];
	
	if([entityName isEqualToString:@"CHIPSTACK"] && [type isEqualToString:@"column"])
		list = [NSArray arrayWithObjects:
				@"amount", 
				@"timeStamp", 
				nil];
	
	if([entityName isEqualToString:@"CHIPSTACK"] && [type isEqualToString:@"type"])
		list = [NSArray arrayWithObjects:
				@"float", 
				@"date", 
				nil];
	
	if([entityName isEqualToString:@"PLAYER"] && [type isEqualToString:@"column"])
		list = [NSArray arrayWithObjects:
				@"playerNum",
				@"chips",
				@"preflopBet",
				@"preflopOdds",
				@"flopBet", 
				@"flopOdds",
				@"turnBet",
				@"turnOdds",
				@"riverBet",
				@"result",
				@"bighand",
				nil];
	
	if([entityName isEqualToString:@"PLAYER"] && [type isEqualToString:@"type"])
		list = [NSArray arrayWithObjects:
				@"int", 
				@"int", 
				@"int", 
				@"text", 
				@"int", 
				@"text", 
				@"int", 
				@"text", 
				@"int", 
				@"text", 
				@"key", 
				nil];
	
	if([entityName isEqualToString:@"GAMEPLAYER"] && [type isEqualToString:@"column"])
		list = [NSArray arrayWithObjects:
				@"game_id",
				@"player_id",
				@"winFlag",
				@"wonMoneyFlg",
				nil];
	
	if([entityName isEqualToString:@"GAMEPLAYER"] && [type isEqualToString:@"type"])
		list = [NSArray arrayWithObjects:
				@"int", 
				@"int", 
				@"text", 
				@"text", 
				nil];
	
	if([entityName isEqualToString:@"EXTRA2"] && [type isEqualToString:@"column"])
		list = [NSArray arrayWithObjects:
				@"type",
				@"name",
				@"attrib_01",
				@"created",
				nil];
	
	if([entityName isEqualToString:@"EXTRA2"] && [type isEqualToString:@"type"])
		list = [NSArray arrayWithObjects:
				@"text",
				@"text",
				@"int",
				@"date",
				nil];
	
	if([entityName isEqualToString:@"BANKROLL"] && [type isEqualToString:@"column"])
		list = [NSArray arrayWithObjects:
				@"name",
				nil];
	
	if([entityName isEqualToString:@"BANKROLL"] && [type isEqualToString:@"type"])
		list = [NSArray arrayWithObjects:
				@"text",
				nil];
	
	
	
	return list;
}

+(BOOL)updateGameInDatabase:(NSManagedObjectContext *)mOC mo:(NSManagedObject *)mo valueList:(NSArray *)valueList2
{
	NSArray *keyList = [ProjectFunctions getColumnListForEntity:@"GAME" type:@"column"];
	NSArray *typeList = [ProjectFunctions getColumnListForEntity:@"GAME" type:@"type"];
	
	NSMutableArray *valueList = [NSMutableArray arrayWithArray:valueList2];

	int user_id = [[valueList stringAtIndex:23] intValue];

	[ProjectFunctions updateNewvalueIfNeeded:[valueList stringAtIndex:9] type:@"Game" mOC:mOC];
	NSString *gameType = [valueList stringAtIndex:kType];
	NSString *notes = [valueList stringAtIndex:15];
	if([notes length]>1) {
		NSString *newNotes = [notes stringByReplacingOccurrencesOfString:@"[nl]" withString:@"\n"];
		if(![notes isEqualToString:newNotes])
			[valueList replaceObjectAtIndex:15 withObject:newNotes];
	}
	
	if([gameType isEqualToString:@"Cash"]) {
		if(user_id==0) {
			[ProjectFunctions updateNewvalueIfNeeded:[valueList stringAtIndex:kBlinds] type:@"Stakes" mOC:mOC];
			[ProjectFunctions setUserDefaultValue:[NSString stringWithFormat:@"%d", [[valueList stringAtIndex:kbuyIn] intValue]] forKey:@"buyinDefault"];
		}
		
	} else {
		if(user_id==0) {
			[ProjectFunctions updateNewvalueIfNeeded:[valueList stringAtIndex:kBlinds] type:@"Tournament" mOC:mOC];
			[ProjectFunctions setUserDefaultValue:[NSString stringWithFormat:@"%d", [[valueList stringAtIndex:kbuyIn] intValue]] forKey:@"tournbuyinDefault"];
		}
		NSMutableArray *temp = [[NSMutableArray alloc] initWithArray:valueList];
		[temp addObject:@""];
		[temp addObject:@""];
		[temp addObject:[valueList stringAtIndex:kFood]];
		[temp addObject:[valueList stringAtIndex:kdealertokes]];
		valueList = temp;
	}
		
	if(user_id==0) {
		[ProjectFunctions updateNewvalueIfNeeded:[valueList stringAtIndex:kLimit] type:@"Limit" mOC:mOC];
		[ProjectFunctions updateNewvalueIfNeeded:[valueList stringAtIndex:kLocation] type:@"Location" mOC:mOC];
		[ProjectFunctions updateNewvalueIfNeeded:[valueList stringAtIndex:kBankroll] type:@"Bankroll" mOC:mOC];
		[ProjectFunctions updateNewvalueIfNeeded:[valueList stringAtIndex:kYear] type:@"Year" mOC:mOC];
		[ProjectFunctions updateNewvalueIfNeeded:[valueList stringAtIndex:kType] type:@"Type" mOC:mOC];

	
		[self updateRefDataValueForKey:@"gameTypeDefault" value:[valueList stringAtIndex:kType] context:mOC];
		[ProjectFunctions setUserDefaultValue:[valueList stringAtIndex:kGameMode] forKey:@"gameDefault"];
		[self updateRefDataValueForKey:@"gameNameDefault" value:[valueList stringAtIndex:kGame] context:mOC];
		if([gameType isEqualToString:@"Cash"])
			[self updateRefDataValueForKey:@"blindDefault" value:[valueList stringAtIndex:kBlinds] context:mOC];

		[self updateRefDataValueForKey:@"limitDefault" value:[valueList stringAtIndex:kLimit] context:mOC];
		[self updateRefDataValueForKey:@"locationDefault" value:[valueList stringAtIndex:kLocation] context:mOC];
		[self updateRefDataValueForKey:@"bankrollDefault" value:[valueList stringAtIndex:kBankroll] context:mOC];
		[self updateRefDataValueForKey:@"tourneyTypeDefault" value:[valueList stringAtIndex:kTourneyType] context:mOC];
	}
	if(kLOG)
		NSLog(@"-------------------------------------------");
	
	BOOL success = [CoreDataLib updateManagedObject:mo keyList:keyList valueList:valueList typeList:typeList mOC:mOC];
	NSDate *startTime = [mo valueForKey:@"startTime"];
	NSDate *endTime = [mo valueForKey:@"endTime"];
	
	int seconds = [endTime timeIntervalSinceDate:startTime];
	[mo setValue:[NSString stringWithFormat:@"%.1f", (float)seconds/3600] forKey:@"hours"];
	[mo setValue:[NSNumber numberWithInt:seconds/60] forKey:@"minutes"];
	[self scrubDataForObj:mo context:mOC];
//	[mOC save:nil];

	return success;
}

+(void)updateRefDataValueForKey:(NSString *)key value:(NSString *)value context:(NSManagedObjectContext *)context {
	NSString *scrubbedValue = [ProjectFunctions scrubRefData:value context:context];
	[ProjectFunctions setUserDefaultValue:scrubbedValue forKey:key];
}

+(void)scrubDataForObj:(NSManagedObject *)mo context:(NSManagedObjectContext *)context field:(NSString *)field {
	NSString *gametype = [mo valueForKey:field];
	NSString *scrubbedData = [ProjectFunctions scrubRefData:gametype context:context];
	if (![scrubbedData isEqualToString:gametype])
		[mo setValue:scrubbedData forKey:field];
}

+(int)getNowYear {
	return [[[NSDate date] convertDateToStringWithFormat:@"yyyy"] intValue];
}

+(NSString *)getNetTrackerMonth {
	NSDateFormatter *df = [[NSDateFormatter alloc] init];
	df.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
	[df setDateFormat:@"MMM yyyy"];
	NSString *dateString = [df stringFromDate:[NSDate date]];
	return dateString;
}

+(NSString *)playerTypeFromLlooseNum:(int)looseNum agressiveNum:(int)agressiveNum {
	NSString *style1 = (looseNum>=50)?@"Tight":@"Loose";
	NSString *style2 = (agressiveNum>=50)?@"Aggressive":@"Passive";
	return [NSString stringWithFormat:@"%@-%@", style1, style2];
}

+(NSString *)playerTypeLongFromLooseNum:(int)looseNum agressiveNum:(int)agressiveNum {
	int looseValue = looseNum/20;
	if(looseValue>4)
		looseValue=4;
	NSString *style1 = @"?";
	NSArray *styles1 = [NSArray arrayWithObjects:@"Very Loose", @"Loose", @"Moderate", @"Tight", @"Very Tight", nil];
	if(looseValue<styles1.count)
		style1 = [styles1 objectAtIndex:looseValue];
	
	int agressiveValue = agressiveNum/20;
	if(agressiveValue>4)
		agressiveValue=4;
	NSString *style2 = @"?";
	NSArray *styles2 = [NSArray arrayWithObjects:@"Very Passive", @"Passive", @"Moderate", @"Aggressive", @"Very Aggressive", nil];
	if(agressiveValue<styles2.count)
		style2 = [styles2 objectAtIndex:agressiveValue];
	
	return [NSString stringWithFormat:@"%@-%@", style1, style2];
}

+(int)getYearOfFirstGameAscendingFlg:(BOOL)ascendingFlg context:(NSManagedObjectContext *)context {
	NSArray *items = [CoreDataLib selectRowsFromEntityWithLimit:@"GAME" predicate:nil sortColumn:@"startTime" mOC:context ascendingFlg:ascendingFlg limit:1];
	if(items.count>0) {
		NSManagedObject *game = [items objectAtIndex:0];
		int year = [[[game valueForKey:@"startTime"] convertDateToStringWithFormat:@"yyyy"] intValue];
		if(year>1970)
			return year;
	}
	return [[[NSDate date] convertDateToStringWithFormat:@"yyyy"] intValue];
}

+(int)findMinAndMaxYear:(NSManagedObjectContext *)context {
	int minYear = [self getYearOfFirstGameAscendingFlg:YES context:context];
	int maxYear = [self getYearOfFirstGameAscendingFlg:NO context:context];
	NSLog(@"findMinAndMaxYear: %d %d", minYear, maxYear);
	int currentMinYear = [[ProjectFunctions getUserDefaultValue:@"minYear2"] intValue];
	int currentMaxYear = [[ProjectFunctions getUserDefaultValue:@"maxYear"] intValue];
	
	if(currentMinYear != minYear) {
		currentMinYear = minYear;
		NSLog(@"!!!Setting minYear2 year to: %d", minYear);
		[ProjectFunctions setUserDefaultValue:[NSString stringWithFormat:@"%d", minYear] forKey:@"minYear2"];
	}
	if(currentMaxYear != maxYear) {
		currentMaxYear = maxYear;
		NSLog(@"!!!Setting maxYear year to: %d", maxYear);
		[ProjectFunctions setUserDefaultValue:[NSString stringWithFormat:@"%d", maxYear] forKey:@"maxYear"];
	}
	return currentMaxYear;
}

+(void)scrubDataForObj:(NSManagedObject *)mo context:(NSManagedObjectContext *)context {
	NSLog(@"scrubbing...");
	[self scrubDataForObj:mo context:context field:@"gametype"];
	[self scrubDataForObj:mo context:context field:@"stakes"];
	[self scrubDataForObj:mo context:context field:@"limit"];
	[self scrubDataForObj:mo context:context field:@"tournamentType"];
	[self scrubDataForObj:mo context:context field:@"location"];
	[self scrubDataForObj:mo context:context field:@"bankroll"];

	NSDate *startTime = [mo valueForKey:@"startTime"];
	NSString *weekday = [ProjectFunctions getWeekDayFromDate:startTime];
	NSString *month = [ProjectFunctions getMonthFromDate:startTime];
	NSString *year = [startTime convertDateToStringWithFormat:@"yyyy"];
	NSString *daytime = [ProjectFunctions getDayTimeFromDate:startTime];
	[mo setValue:weekday forKey:@"weekday"];
	[mo setValue:month forKey:@"month"];
	[mo setValue:year forKey:@"year"];
	[mo setValue:daytime forKey:@"daytime"];
	
	NSString *type = [mo valueForKey:@"Type"];
	if ([@"Cash" isEqualToString:type])
		[mo setValue:@"" forKey:@"tournamentType"];
	else
		[mo setValue:@"" forKey:@"stakes"];
	
	int breakMinutes = [[mo valueForKey:@"breakMinutes"] intValue];
	int minutes = [ProjectFunctions getMinutesPlayedUsingStartTime:startTime andEndTime:[mo valueForKey:@"endTime"] andBreakMin:breakMinutes];
	[mo setValue:[NSNumber numberWithInt:minutes] forKey:@"minutes"];
	[mo setValue:[NSString stringWithFormat:@"%.1f", (float)minutes/60] forKey:@"hours"];
	
	
	double buyInAmount = [[mo valueForKey:@"buyInAmount"] doubleValue];
	double reBuyAmount = [[mo valueForKey:@"rebuyAmount"] doubleValue];
	double cashoutAmount = [[mo valueForKey:@"cashoutAmount"] doubleValue];
	int foodDrink = [[mo valueForKey:@"foodDrinks"] intValue];
	double winnings = cashoutAmount+foodDrink-buyInAmount-reBuyAmount;
	[mo setValue:[NSNumber numberWithDouble:winnings] forKey:@"winnings"];

	
	[ProjectFunctions updateNewvalueIfNeeded:[mo valueForKey:@"gametype"] type:@"Game" mOC:context];
	[ProjectFunctions updateNewvalueIfNeeded:[mo valueForKey:@"stakes"] type:@"Stakes" mOC:context];
	[ProjectFunctions updateNewvalueIfNeeded:[mo valueForKey:@"tournamentType"] type:@"Tournament" mOC:context];
	[ProjectFunctions updateNewvalueIfNeeded:[mo valueForKey:@"limit"] type:@"Limit" mOC:context];
	[ProjectFunctions updateNewvalueIfNeeded:[mo valueForKey:@"location"] type:@"Location" mOC:context];
	[ProjectFunctions updateNewvalueIfNeeded:[mo valueForKey:@"bankroll"] type:@"Bankroll" mOC:context];
	[ProjectFunctions updateNewvalueIfNeeded:[mo valueForKey:@"year"] type:@"Year" mOC:context];
	NSString *hudString = [mo valueForKey:@"attrib01"];
	if(hudString && hudString.length>10) {
		NSLog(@"Hud stats!");
		[mo setValue:@"Y" forKey:@"hudHeroLine"];
	}
	
	if([@"Tournament" isEqualToString:type]) {
		int tournamentSpotsPaid = [[mo valueForKey:@"tournamentSpotsPaid"] intValue];
		int tournamentSpots = [[mo valueForKey:@"tournamentSpots"] intValue];
		if (tournamentSpots>0 && breakMinutes>0 && tournamentSpotsPaid==0 && [year intValue]<=2017) {
			NSString *attrib05 = [mo valueForKey:@"attrib05"];
			if (attrib05.length == 0) {
				NSLog(@"Fixing tournament!!!");
				[mo setValue:[NSNumber numberWithInt:0] forKey:@"breakMinutes"];
				[mo setValue:[NSNumber numberWithInt:0] forKey:@"foodDrinks"];
				[mo setValue:[NSNumber numberWithInt:0] forKey:@"tokes"];
				[mo setValue:[NSNumber numberWithInt:breakMinutes] forKey:@"tournamentSpotsPaid"];
				[mo setValue:@"Y" forKey:@"attrib05"]; // mark as scrubbed!
			}
		}
	}
	NSLog(@"Scrubbing complete!");
	[context save:nil];
}

+(NSString *)localizedTitle:(NSString *)title {
	NSString *localized = NSLocalizedString(title, nil);
	if(![localized isEqualToString:title])
		return localized;
	NSArray *words = [title componentsSeparatedByString:@" "];
	if(words.count<=1)
		return NSLocalizedString(title, nil);
	else {
		NSMutableArray *newWords = [[NSMutableArray alloc] init];
		for(NSString *word in words) {
			[newWords addObject:NSLocalizedString(word, nil)];
		}
		return [newWords componentsJoinedByString:@" "];
	}
}

+(UIBarButtonItem *)UIBarButtonItemWithIcon:(NSString *)icon target:(id)target action:(SEL)action {
	UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:icon style:UIBarButtonItemStylePlain target:target action:action];
	
	[button setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: [UIFont fontWithName:kFontAwesomeFamilyName size:24.f], NSFontAttributeName, nil] forState:UIControlStateNormal];
	return button;
}

+(NSString *)getMonthFromDate:(NSDate *)date {
	return [[date convertDateToStringWithFormat:@"MMMM"] capitalizedString];
}

+(NSString *)getWeekDayFromDate:(NSDate *)date {
	return [[date convertDateToStringWithFormat:@"EEEE"] capitalizedString];
}

+(BOOL)updateEntityInDatabase:(NSManagedObjectContext *)mOC mo:(NSManagedObject *)mo valueList:(NSArray *)valueList entityName:(NSString *)entityName
{
	NSArray *keyList = [ProjectFunctions getColumnListForEntity:entityName type:@"column"];
	NSArray *typeList = [ProjectFunctions getColumnListForEntity:entityName type:@"type"];
	NSLog(@"+++updating %@", entityName);
    
	return [CoreDataLib updateManagedObject:mo keyList:keyList valueList:valueList typeList:typeList mOC:mOC];
}

+(NSString *)translatedData:(NSString *)data {
	NSString *translatedValue = [data lowercaseString];
	translatedValue = [translatedValue stringByReplacingOccurrencesOfString:@" " withString:@""];
	translatedValue = [translatedValue stringByReplacingOccurrencesOfString:@"_" withString:@""];
	translatedValue = [translatedValue stringByReplacingOccurrencesOfString:@"-" withString:@""];
	translatedValue = [translatedValue stringByReplacingOccurrencesOfString:@"|" withString:@""];
	translatedValue = [translatedValue stringByReplacingOccurrencesOfString:@"'" withString:@""];
	translatedValue = [translatedValue stringByReplacingOccurrencesOfString:@"$" withString:@""];
	return translatedValue;
}

+(NSString *)scrubRefData:(NSString *)data context:(NSManagedObjectContext *)context {
	NSString *translatedData = [self translatedData:data];
	NSArray *tables = [NSArray arrayWithObjects:@"GAMETYPE", @"STAKES", @"LIMIT", @"TOURNAMENT", @"BANKROLL", @"LOCATION", nil];
	for (NSString *table in tables) {
		NSArray *items = [CoreDataLib selectRowsFromTable:table mOC:context];
		for (NSManagedObject *mo in items) {
			NSString *refData = [mo valueForKey:@"name"];
			if ([translatedData isEqualToString:[self translatedData:refData]])
				return refData;
		}
	}
	if([data isEqualToString:@"2-Jan"])
		return @"$1/$2";
	if([data isEqualToString:@"3-Jan"])
		return @"$1/$3";
	if([data isEqualToString:@"3-Feb"])
		return @"$2/$3";
	if([data isEqualToString:@"5-Feb"])
		return @"$2/$5";
	if([data isEqualToString:@"5-Mar"])
		return @"$3/$5";
	
	return data;
}

+(BOOL)trackChipsSwitchValue {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	return [[userDefaults valueForKey:@"trackChipsSwitch"] boolValue];
}

+(void)setUserDefaultValue:(NSString *)value forKey:(NSString *)key
{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setObject:value forKey:key];
}

+(NSString *)getUserDefaultValue:(NSString *)key
{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSString *result = [userDefaults stringForKey:key];
	
	if([key isEqualToString:@"gameTypeDefault"] && [result length]==0) {
		result = @"Cash";
	}
	if([key isEqualToString:@"buyinDefault"] && [result length]==0) {
		result = @"100";
	}
	if([key isEqualToString:@"tournbuyinDefault"] && [result length]==0) {
		result = @"30";
	}
	if([key isEqualToString:@"gameDefault"] && [result length]==0) {
		result = @"Hold'em $1/$3 No-Limit";
	}
	if([key isEqualToString:@"gameNameDefault"] && [result length]==0) {
		result = @"Hold'em";
	}
	if([key isEqualToString:@"blindDefault"] && [result length]==0) {
		result = @"$1/$3";
	}
	if([key isEqualToString:@"limitDefault"] && [result length]==0) {
		result = @"No-Limit";
	}
	if([key isEqualToString:@"locationDefault"] && [result length]==0) {
		result = @"Casino";
	}
	if([key isEqualToString:@"bankrollDefault"] && [result length]==0) {
		result = @"Default";
	}

	if([key isEqualToString:@"profitGoal"] && [result length]==0) {
		result = @"1000";
	}
	if([key isEqualToString:@"hourlyGoal"] && [result length]==0) {
		result = @"20";
	}

	if([key isEqualToString:@"tourneyTypeDefault"] && [result length]<2) {
		result = @"Single Table";
	}
	if([key isEqualToString:@"lastSyncedDate"] && [result length]<2) {
		result = @"01/01/1990 12:00:00 AM";
	}
	
	return result;
}

+(UIImage *)plotStatsChart:(NSManagedObjectContext *)mOC predicate:(NSPredicate *)predicate displayBySession:(BOOL)displayBySession
{
	int totalWidth=640;
	int totalHeight=300;
	int leftEdgeOfChart=50;
	int bottomEdgeOfChart=totalHeight-25;
	float chartWidth = totalWidth-leftEdgeOfChart-6; // account for border of image
	
	// get games from the database based on the filter
	NSArray *games = [CoreDataLib selectRowsFromEntity:@"GAME" predicate:predicate sortColumn:@"startTime" mOC:mOC ascendingFlg:YES];
	int numGames=(int)games.count;
	
	NSDate *firstDate = (numGames>0)?[[games objectAtIndex:0] valueForKey:@"startTime"]:[NSDate date];
	NSDate *lastDate = (numGames>0)?[[games objectAtIndex:numGames-1] valueForKey:@"startTime"]:[NSDate date];
	
	//--------- Initialyze spacing/min/max values
	double min=0;
	double max=0;
	double totalMoney=0;
	for (NSManagedObject *mo in games) {
		totalMoney += [[mo valueForKey:@"winnings"] doubleValue];
		if(totalMoney<min)
			min = totalMoney;
		if(totalMoney>max)
			max = totalMoney;
	}
	max*=1.04;
	double totalMoneyRange = max-min;
	int totalSecondsRange = [lastDate timeIntervalSinceDate:firstDate];

	float yMultiplier = 1;
	float xMultiplier = 1;
	if(totalMoneyRange>0)
		yMultiplier = (float)bottomEdgeOfChart/totalMoneyRange;
	if(totalSecondsRange>0)
		xMultiplier = (float)chartWidth/totalSecondsRange;
	
	float sessionSpacer = 100;
	if(numGames>0)
		sessionSpacer = (float)chartWidth/(numGames);

	//------- init UIImage
	UIImage *dynamicChartImage = [[UIImage alloc] init];

	CGContextRef c = [self contextRefForGraphofWidth:totalWidth totalHeight:totalHeight];
	int zeroLoc = [self drawZeroLineForContext:c min:min max:max bottomEdgeOfChart:bottomEdgeOfChart leftEdgeOfChart:leftEdgeOfChart totalWidth:totalWidth];
	// draw bottom labels ---------------------
	CGContextSetRGBFillColor(c, 0.0, 0.0, 0.4, 1); // text
	int percentOver=0;
	for(int i=0; i<=4; i++) {
		int timeSecs = totalSecondsRange*i/4;
		int XCord = leftEdgeOfChart+(totalWidth-leftEdgeOfChart)*i/4;
		NSDate *labelDate = [firstDate dateByAddingTimeInterval:timeSecs];
		[self drawLine:c startX:XCord+20 startY:bottomEdgeOfChart-5 endX:XCord+20 endY:bottomEdgeOfChart+5];
		NSString *label = nil;
		if(totalSecondsRange>60*60*24*365*4)
			label = [labelDate convertDateToStringWithFormat:@"yyyy"];
		else if(totalSecondsRange>60*60*24*31*12)
			label = [labelDate convertDateToStringWithFormat:@"MMM yy"];
		else if(totalSecondsRange>60*60*24*120)
			label = [labelDate convertDateToStringWithFormat:@"MMM"];
		else
			label = [labelDate convertDateToStringWithFormat:@"MMM dd"];

		int labelSpacer=-20;
		if(displayBySession) {
			int sessionNum=(int)games.count*percentOver/100;
			if(sessionNum==0 && games.count>10)
				sessionNum=1;
			label = [NSString stringWithFormat:@"%d", sessionNum];
			labelSpacer = -2;
		}
		
		if(i==4) // last label pushed over a bit
			labelSpacer -= 20;

		BOOL showLabel = NO;
		if(numGames==1 && i==0)
			showLabel = YES;
		if(numGames==2 && (i==0 || i==4))
			showLabel = YES;
		if(numGames==3 && (i==0 || i==2 || i==4))
			showLabel = YES;
		if(numGames==4 && (i==0 || i==1 || i==3 || i==4))
			showLabel = YES;
		if(numGames>4)
			showLabel = YES;
		
		if(numGames==4 && i==1)
			labelSpacer+=20;
		if(numGames==4 && i==3)
			labelSpacer-=25;
		
		if(showLabel)
			[label drawAtPoint:CGPointMake(XCord+labelSpacer, bottomEdgeOfChart) withFont:[UIFont fontWithName:@"Helvetica" size:18]];
		
		percentOver+=25;
	}
	
	// Draw horizontal and vertical baselines
	CGContextSetRGBStrokeColor(c, 0, 0, 0, 1); // black
	[self drawLine:c startX:leftEdgeOfChart startY:bottomEdgeOfChart endX:totalWidth endY:bottomEdgeOfChart];
	[self drawLine:c startX:leftEdgeOfChart startY:0 endX:leftEdgeOfChart endY:bottomEdgeOfChart];
	

	// Graph the Chart---------------------
	UIBezierPath *aPath = [UIBezierPath bezierPath];
	[aPath moveToPoint:CGPointMake(leftEdgeOfChart, bottomEdgeOfChart)];
	if(games.count>0)
		[aPath addLineToPoint:CGPointMake(leftEdgeOfChart, max*yMultiplier)];

	double plotY = [self drawTheGraphWithContext:c games:games firstDate:firstDate aPath:aPath leftEdgeOfChart:leftEdgeOfChart bottomEdgeOfChart:bottomEdgeOfChart max:max min:min xMultiplier:xMultiplier yMultiplier:yMultiplier sessionSpacer:sessionSpacer displayBySession:displayBySession];

	[aPath addLineToPoint:CGPointMake(totalWidth, plotY)];
	[aPath addLineToPoint:CGPointMake(totalWidth, bottomEdgeOfChart)];
	[aPath addLineToPoint:CGPointMake(leftEdgeOfChart, bottomEdgeOfChart)];
	[aPath closePath];

	NSLog(@"Adding Green Grad!");
//	[self addGradientToPath:aPath context:c color1:[ProjectFunctions themeBGColor] color2:[ProjectFunctions themeBGColor] lineWidth:(int)0 imgWidth:totalWidth imgHeight:totalHeight];
	[self addGradientToPath:aPath context:c color1:[ProjectFunctions primaryButtonColor] color2:[ProjectFunctions primaryButtonColor] lineWidth:(int)0 imgWidth:totalWidth imgHeight:totalHeight];

	[self drawLeftLabelsAndLinesForContext:c totalMoneyRange:totalMoneyRange min:min leftEdgeOfChart:leftEdgeOfChart totalHeight:totalHeight totalWidth:totalWidth];

	// Graph the Chart Again---------------------
	[self drawTheGraphWithContext:c games:games firstDate:firstDate aPath:nil leftEdgeOfChart:leftEdgeOfChart bottomEdgeOfChart:bottomEdgeOfChart max:max min:min xMultiplier:xMultiplier yMultiplier:yMultiplier sessionSpacer:sessionSpacer displayBySession:displayBySession];


	//----- draw zero line---------------
	CGContextSetRGBStrokeColor(c, 0.6, 0.2, 0.2, 1); // red
	CGContextSetLineWidth(c, 2);
	
	float percentUp = 0;
	if(totalMoneyRange>0)
		percentUp = (float)(0 - min) / totalMoneyRange;

	zeroLoc = bottomEdgeOfChart - ((float)bottomEdgeOfChart*percentUp);
	if(zeroLoc <= bottomEdgeOfChart && zeroLoc >= 0)
		[self drawLine:c startX:leftEdgeOfChart startY:zeroLoc endX:totalWidth endY:zeroLoc];

	[self displaySessionBoxAtLeft:totalWidth-200 top:bottomEdgeOfChart-25 c:c displayBySession:displayBySession];

	//---finish up----------
	UIGraphicsPopContext();
	dynamicChartImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return dynamicChartImage;
	
}

+(void)displaySessionBoxAtLeft:(float)left top:(float)top c:(CGContextRef)c displayBySession:(BOOL)displayBySession {
	//----------Draw display type
	CGContextSetLineWidth(c, 1);
	CGContextSetRGBFillColor(c, 0, 0, 0, 1); //
	CGContextFillRect(c, CGRectMake(left, top, left+140, 25));
	CGContextSetRGBFillColor(c, 1, 1, 1, 1);
	if(displayBySession)
		[@"Display by Session" drawAtPoint:CGPointMake(left+10, top-2) withFont:[UIFont boldSystemFontOfSize:20]];
	else
		[@"  Display by Date" drawAtPoint:CGPointMake(left+10, top-2) withFont:[UIFont boldSystemFontOfSize:20]];
}


+(double)drawTheGraphWithContext:(CGContextRef)c
						 games:(NSArray *)games
					 firstDate:(NSDate *)firstDate
						aPath:(UIBezierPath *)aPath
			   leftEdgeOfChart:(int)leftEdgeOfChart
			 bottomEdgeOfChart:(int)bottomEdgeOfChart
						   max:(double)max
						   min:(double)min
				   xMultiplier:(float)xMultiplier
				   yMultiplier:(float)yMultiplier
				 sessionSpacer:(float)sessionSpacer
			  displayBySession:(BOOL)displayBySession
{
	if(games.count>20)
		CGContextSetLineWidth(c, 1);
	else
		CGContextSetLineWidth(c, 2);
	int oldX=leftEdgeOfChart;
	double oldY=(max*yMultiplier);
	double plotY=0;
	double currentMoney = 0;
	int circleSize=30-(int)games.count;
	int i=1;
	BOOL prevWinFlg=YES;
	for (NSManagedObject *mo in games) {
		NSDate *startTime = [mo valueForKey:@"startTime"];
		double money = [[mo valueForKey:@"winnings"] doubleValue];
		BOOL winFlg = (money>=0);
		int seconds = [startTime timeIntervalSinceDate:firstDate];
		currentMoney += money;
		int plotX = seconds*xMultiplier+leftEdgeOfChart;
		
		if(displayBySession || games.count==1)
			plotX = sessionSpacer*i+leftEdgeOfChart;
		
		if(games.count==1)
			plotX-=10; // just to show it better
		
		plotY = (float)bottomEdgeOfChart-(currentMoney-min)*yMultiplier;
		
		CGContextSetRGBFillColor(c, 0, 0, 0, 1);
		CGContextSetRGBStrokeColor(c, 0, 0, 0, 1); // black
		[self drawLine:c startX:oldX-1 startY:oldY+1 endX:plotX-1 endY:plotY+1];
		
		if(winFlg)
			CGContextSetRGBStrokeColor(c, 0, .5, 0, 1); // green
		else
			CGContextSetRGBStrokeColor(c, 1, 0, 0, 1); // red
		
		[self drawLine:c startX:oldX startY:oldY endX:plotX endY:plotY];
		
		[self drawGraphCircleForContext:c x:plotX y:plotY winFlg:winFlg circleSize:circleSize];
		if(i>1)
			[self drawGraphCircleForContext:c x:oldX y:oldY winFlg:prevWinFlg circleSize:circleSize];

		
		if(aPath) {
			[aPath addLineToPoint:CGPointMake(plotX, plotY)];
		}

		prevWinFlg=winFlg;
		oldX = plotX;
		oldY = plotY;
		i++;
	}
	return plotY;
}

+(void)addGradientToPath:(UIBezierPath *)aPath
				 context:(CGContextRef)context
				  color1:(UIColor *)color1
				  color2:(UIColor *)color2
			   lineWidth:(int)lineWidth
				imgWidth:(int)width
			   imgHeight:(int)height
{
	CGFloat red1 = 0.0, green1 = 0.0, blue1 = 0.0, alpha1 =0.0;
	[color1 getRed:&red1 green:&green1 blue:&blue1 alpha:&alpha1];
	
	CGFloat red2 = 0.0, green2 = 0.0, blue2 = 0.0, alpha2 =0.0;
	[color2 getRed:&red2 green:&green2 blue:&blue2 alpha:&alpha2];
	
	CGColorSpaceRef myColorspace=CGColorSpaceCreateDeviceRGB();
	size_t num_locations = 2;
	CGFloat locations[2] = { 1.0, 0.0 };
	CGFloat components[8] =	{ red2, green2, blue2, alpha2,    red1, green1, blue1, alpha1};
	
	CGGradientRef myGradient = CGGradientCreateWithColorComponents(myColorspace, components, locations, num_locations);
	
	CGContextSaveGState(context);
	[aPath addClip];
	CGContextDrawLinearGradient(context, myGradient, CGPointMake(0, 0), CGPointMake(width, height), 0);
	CGContextRestoreGState(context);
	
	[[UIColor blackColor] setStroke];
	aPath.lineWidth = lineWidth;
	[aPath stroke];
	
	CGGradientRelease(myGradient);
}

+(void)drawGraphCircleForContext:(CGContextRef)c x:(int)x y:(int)y winFlg:(BOOL)winFlg circleSize:(int)circleSize {
	if(circleSize>22)
		circleSize=22;
	if(circleSize<6)
		circleSize=6;
	
	CGContextSetRGBFillColor(c, .5, .5, .5, 1);
	for(int i=1; i<=2; i++)
		CGContextFillEllipseInRect(c, CGRectMake(x-circleSize/2+i,y-circleSize/2+i,circleSize,circleSize));
	
	CGContextSetRGBFillColor(c, 0, 0, 0, 1);
	if(circleSize<=7)
		CGContextSetRGBFillColor(c, 1, 1, 1, 1);
	
	CGContextFillEllipseInRect(c, CGRectMake(x-circleSize/2,y-circleSize/2,circleSize,circleSize));
	
	circleSize-=2;
	CGContextSetRGBFillColor(c, 1, 1, 1, 1);
	CGContextFillEllipseInRect(c, CGRectMake(x-circleSize/2,y-circleSize/2,circleSize,circleSize));
	
	if(circleSize>8)
		circleSize-=8;
	if(winFlg)
		CGContextSetRGBFillColor(c, 0, .5, 0, 1);
	else
		CGContextSetRGBFillColor(c, 1, 0, 0, 1);
	
	CGContextFillEllipseInRect(c, CGRectMake(x-circleSize/2,y-circleSize/2,circleSize,circleSize));
	
	CGContextDrawPath(c, kCGPathFillStroke);
}



+(NSString *)smallLabelForMoney:(double)money totalMoneyRange:(double)totalMoneyRange {
	int moneyRoundingFactor = 1;
	if(totalMoneyRange>500)
		moneyRoundingFactor=10;
	if(totalMoneyRange>5000)
		moneyRoundingFactor=100;
	if(totalMoneyRange>50000)
		moneyRoundingFactor=1000;
	if(totalMoneyRange>500000)
		moneyRoundingFactor=10000;
	if(totalMoneyRange>5000000)
		moneyRoundingFactor=100000;
	
	float moneyFloat = money/moneyRoundingFactor;
	moneyFloat *=moneyRoundingFactor;
	if(totalMoneyRange>10)
		moneyFloat = round(moneyFloat);
	
//	BOOL negValue = (money<0)?YES:NO;
//	if(negValue)
//		money*=-1;
	
	
	NSString *label = [ProjectFunctions convertNumberToMoneyString:moneyFloat];
	if(abs(money)>1000)
		label = [NSString stringWithFormat:@"%@k", [self convertNumberToMoneyStringOneDec:money/1000]];
	if(abs(money)>10000)
		label = [NSString stringWithFormat:@"%@k", [ProjectFunctions convertNumberToMoneyString:(int)money/1000]];
	if(abs(money)>100000)
		label = [NSString stringWithFormat:@"%dk", (int)money/1000];
	if(abs(money)>1000000)
		label = [NSString stringWithFormat:@"%@M", [self convertNumberToMoneyStringOneDec:money/1000000]];
	if(abs(money)>10000000)
		label = [NSString stringWithFormat:@"%@M", [ProjectFunctions convertNumberToMoneyString:(int)money/1000000]];
	
//	if (negValue)
//		return [NSString stringWithFormat:@"-%@", label];
//	else
		return label;
}

+(void)drawLeftLabelsAndLinesForContext:(CGContextRef)c totalMoneyRange:(float)totalMoneyRange min:(double)min leftEdgeOfChart:(int)leftEdgeOfChart totalHeight:(int)totalHeight totalWidth:(int)totalWidth
{
	//------ draw left hand labels and grid---------------------
	int YCord=-8;
	for(int i=11; i>=0; i--) {
		float multiplyer = (float)totalMoneyRange/11;
		float money = (multiplyer*i+min);
		
		NSString *label = [ProjectFunctions smallLabelForMoney:money totalMoneyRange:totalMoneyRange];
		
		if(money>=0)
			CGContextSetRGBFillColor(c, 0.0, 0.3, 0.0, 1); // text green
		else
			CGContextSetRGBFillColor(c, .8, 0, 0, 1); // text red
		
		if(i<11) {
			[label drawAtPoint:CGPointMake(6, YCord) withFont:[UIFont fontWithName:@"Helvetica" size:15]];
			CGContextSetRGBStrokeColor(c, 0.7, 0.7, 0.7, 1); // line color - lightGray
			[self drawLine:c startX:leftEdgeOfChart+1 startY:YCord+7 endX:totalWidth endY:YCord+7];
		}
		YCord += totalHeight/12;
	}

}

+(void)drawBottomLabelsForContext:(CGContextRef)c totalSecondsRange:(int)totalSecondsRange leftEdgeOfChart:(int)leftEdgeOfChart totalHeight:(int)totalHeight totalWidth:(int)totalWidth bottomEdgeOfChart:(int)bottomEdgeOfChart firstDate:(NSDate *)firstDate sessionSpacer:(int)sessionSpacer displayBySession:(BOOL)displayBySession numGames:(int)numGames {
	CGContextSetRGBFillColor(c, 0.4, 0.4, 0.4, 1); // black
	for(int i=0; i<=4; i++) {
		int timeSecs = totalSecondsRange*i/4;
		int XCord = leftEdgeOfChart+(totalWidth-leftEdgeOfChart)*i/4;
		NSDate *labelDate = [firstDate dateByAddingTimeInterval:timeSecs];
		[self drawLine:c startX:XCord+20 startY:bottomEdgeOfChart-5 endX:XCord+20 endY:bottomEdgeOfChart+5];
		NSString *label = nil;
		if(totalSecondsRange>60*60*24*365*4)
			label = [labelDate convertDateToStringWithFormat:@"yyyy"];
		else if(totalSecondsRange>60*60*24*31*12)
			label = [labelDate convertDateToStringWithFormat:@"MMM yy"];
		else if(totalSecondsRange>60*60*24*120)
			label = [labelDate convertDateToStringWithFormat:@"MMM"];
		else if(totalSecondsRange>60*60*24*2)
			label = [labelDate convertDateToStringWithFormat:@"MMM dd"];
		else
			label = [labelDate convertDateToStringWithFormat:@"h:mm a"];
		
		int sessionNum = 1;
		if(sessionSpacer>0)
			sessionNum = ceil(XCord/sessionSpacer);
		
		int labelSpacer=-20;
		if(displayBySession) {
			label = [NSString stringWithFormat:@"%d", sessionNum];
			labelSpacer = -2;
		}
		
		if(i==4) // last label pushed over a bit
			labelSpacer -= 20;
		
		BOOL showLabel = NO;
		if(numGames==1 && i==0)
			showLabel = YES;
		if(numGames==2 && (i==0 || i==4))
			showLabel = YES;
		if(numGames==3 && (i==0 || i==2 || i==4))
			showLabel = YES;
		if(numGames==4 && (i==0 || i==1 || i==3 || i==4))
			showLabel = YES;
		if(numGames>4)
			showLabel = YES;
		
		if(numGames==4 && i==1)
			labelSpacer+=20;
		if(numGames==4 && i==3)
			labelSpacer-=25;
		
		if(showLabel)
			[label drawAtPoint:CGPointMake(XCord+labelSpacer, bottomEdgeOfChart+2) withFont:[UIFont fontWithName:@"Helvetica" size:16]];
		
	} // <-- for
}

+(ChipStackObj *)plotGameChipsChart:(NSManagedObjectContext *)mOC mo:(NSManagedObject *)mo predicate:(NSPredicate *)predicate2 displayBySession:(BOOL)displayBySession
{
	int totalWidth=640;
	int totalHeight=300;
	int leftEdgeOfChart=50;
	int bottomEdgeOfChart=totalHeight-25;
	
	NSMutableArray *pointsArray = [[NSMutableArray alloc] init];

	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"game = %@", mo];
	
	NSArray *items = [CoreDataLib selectRowsFromEntity:@"CHIPSTACK" predicate:predicate sortColumn:@"timeStamp" mOC:mOC ascendingFlg:YES];

	int circleSize=30-(int)items.count;

	NSDate *firstDate = (items.count>0)?[[items objectAtIndex:0] valueForKey:@"timeStamp"]:[NSDate date];
	NSDate *lastDate = (items.count>0)?[[items objectAtIndex:items.count-1] valueForKey:@"timeStamp"]:[NSDate date];
	double min=0;
	double max=0;
	int numGames=0;
	for (NSManagedObject *mo in items) {
		double money = [[mo valueForKey:@"amount"] doubleValue];
		if(money<min)
			min = money;
		if(money>max)
			max = money;
	}
	max = ceil(max);
	if(max<1)
		max=1;
	if(max>100)
		max+=20;
	int totalMoneyRange = max-min;
	int totalSecondsRange = [lastDate timeIntervalSinceDate:firstDate];
	
	float yMultiplier = 1;
	float xMultiplier = 1;
	if(totalMoneyRange>0)
		yMultiplier = (float)bottomEdgeOfChart/totalMoneyRange;
	if(totalSecondsRange>0)
		xMultiplier = (float)(totalWidth-leftEdgeOfChart-10)/totalSecondsRange;
	
	float sessionSpacer = 100;
	if(numGames>0)
		sessionSpacer = (float)(totalWidth-leftEdgeOfChart)/(numGames);
	
	UIImage *dynamicChartImage = [[UIImage alloc] init];
	
	UIGraphicsBeginImageContext(CGSizeMake(totalWidth,totalHeight));
	CGContextRef c = UIGraphicsGetCurrentContext();
	UIGraphicsPushContext(c); // <--
	CGContextSetLineCap(c, kCGLineCapRound);
	
	// draw Box---------------------
	CGContextSetLineWidth(c, 1);
	CGContextSetRGBStrokeColor(c, 0, 0, 0, 1); // blank
	CGContextSetRGBFillColor(c, 1, 1, 1, 1); // white
	CGContextFillRect(c, CGRectMake(0, 0, totalWidth, totalHeight));
	CGContextStrokeRect(c, CGRectMake(0, 0, totalWidth, totalHeight));
	
	
	// draw left hand labels and grid---------------------
	[self drawLeftLabelsAndLinesForContext:c totalMoneyRange:totalMoneyRange min:min leftEdgeOfChart:leftEdgeOfChart totalHeight:totalHeight totalWidth:totalWidth];

	// draw bottom labels ---------------------
	[self drawBottomLabelsForContext:c totalSecondsRange:totalSecondsRange leftEdgeOfChart:leftEdgeOfChart totalHeight:totalHeight totalWidth:totalWidth bottomEdgeOfChart:bottomEdgeOfChart firstDate:firstDate sessionSpacer:sessionSpacer displayBySession:displayBySession numGames:5];
	
	// Draw horizontal and vertical baselines
	CGContextSetRGBStrokeColor(c, 0, 0, 0, 1); // black
	[self drawLine:c startX:leftEdgeOfChart startY:bottomEdgeOfChart endX:totalWidth endY:bottomEdgeOfChart];
	[self drawLine:c startX:leftEdgeOfChart startY:0 endX:leftEdgeOfChart endY:bottomEdgeOfChart];
	
	// Graph the Chart---------------------
	CGContextSetLineWidth(c, 2);
	float oldX=leftEdgeOfChart;
	float oldY=(max*yMultiplier);
	float currentMoney = 0;
	//	NSLog(@"start [%d, %d]", oldX, oldY);
	int i=0;
	BOOL prevWinFlg=NO;
	for (NSManagedObject *mo in items) {
		NSDate *startTime = [mo valueForKey:@"timeStamp"];
		double money = [[mo valueForKey:@"amount"] doubleValue];
		BOOL rebuyFlg = [[mo valueForKey:@"rebuyFlg"] intValue];
		int seconds = [startTime timeIntervalSinceDate:firstDate];
		currentMoney = money;
		int plotX = seconds*xMultiplier+leftEdgeOfChart;
		if(displayBySession)
			plotX = sessionSpacer*i+leftEdgeOfChart;
		
		float plotY = bottomEdgeOfChart-(currentMoney-min)*yMultiplier;
		
		BOOL winFlg=(money>=0)?YES:NO;
			
		if(money>=0)
			CGContextSetRGBStrokeColor(c, 0, .5, 0, 1); // green
		else
			CGContextSetRGBStrokeColor(c, 1, 0, 0, 1); // red
		
		if(rebuyFlg)
			CGContextSetRGBStrokeColor(c, 0, 0, 1, 1); // blue
		
		[self drawLine:c startX:oldX startY:oldY endX:plotX endY:plotY];
		[self drawGraphCircleForContext:c x:plotX y:plotY winFlg:winFlg circleSize:circleSize];
		[self drawGraphCircleForContext:c x:oldX y:oldY winFlg:prevWinFlg circleSize:circleSize];
		[pointsArray addObject:[NSString stringWithFormat:@"%d|%f|%f|%@", plotX, plotY, money, [startTime convertDateToStringWithFormat:@"h:mm a"]]];
		
		prevWinFlg=winFlg;
		oldX = plotX;
		oldY = plotY;
		i++;
	}

	// draw zero line---------------
	CGContextSetRGBStrokeColor(c, 0.6, 0.2, 0.2, 1); // lightGray
	CGContextSetLineWidth(c, 2);
	float percentOfScreen = 0;
	if(max-min>0)
		percentOfScreen = (float)max/(max-min);
	
	int zeroLoc=bottomEdgeOfChart*percentOfScreen;
	if(zeroLoc<bottomEdgeOfChart)
		[self drawLine:c startX:leftEdgeOfChart startY:zeroLoc endX:totalWidth endY:zeroLoc];
	

	//Draw display type
	CGContextSetLineWidth(c, 1);
	CGContextSetRGBFillColor(c, 0, 0, 0, 1); // 
	CGContextFillRect(c, CGRectMake(leftEdgeOfChart, 0, leftEdgeOfChart+100, 26));
	CGContextSetRGBFillColor(c, 1, 1, 1, 1); 
	[@"    Profit" drawAtPoint:CGPointMake(leftEdgeOfChart+10, 1) withFont:[UIFont fontWithName:@"Helvetica" size:24]];
	
	
	// Draw box outline again
	CGContextSetRGBStrokeColor(c, 0, 0, 0, 1); // black
	CGContextStrokeRect(c, CGRectMake(0, 0, totalWidth, totalHeight));
	
	UIGraphicsPopContext();
	dynamicChartImage = UIGraphicsGetImageFromCurrentImageContext();
	
	UIGraphicsEndImageContext();
	ChipStackObj *chipStackObj = [[ChipStackObj alloc] init];
	chipStackObj.image = dynamicChartImage;
	chipStackObj.pointArray = pointsArray;
	return chipStackObj;
	
}


+(void)drawLine:(CGContextRef)c startX:(int)startX startY:(int)startY endX:(int)endX endY:(int)endY
{
	CGContextMoveToPoint(c, startX, startY);
	CGContextAddLineToPoint(c, endX, endY);
	CGContextStrokePath(c);
}

+(void)showAlertPopup:(NSString *)title message:(NSString *)message
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
													message:message
												   delegate:nil
										  cancelButtonTitle:@"OK"
										  otherButtonTitles: nil];
    [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
//	[alert show];
}	

+(void)showAlertPopupWithDelegate:(NSString *)title message:(NSString *)message delegate:(id)delegate
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
													message:message
												   delegate:delegate
										  cancelButtonTitle:@"OK"
										  otherButtonTitles: nil];
    [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
//	[alert show];
	//-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
}

+(void)showAlertPopupWithDelegateBG:(NSString *)title message:(NSString *)message delegate:(id)delegate
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
													message:message
												   delegate:delegate
										  cancelButtonTitle:@"OK"
										  otherButtonTitles: nil];
    [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
	//-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
}

+(void)showConfirmationPopup:(NSString *)title message:(NSString *)message delegate:(id)delegate tag:(int)tag
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
													message:message
												   delegate:delegate
										  cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
										  otherButtonTitles: NSLocalizedString(@"OK", nil), nil];
	alert.tag = tag;
    [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
//	[alert show];
	//-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
}	

+(void)showAcceptDeclinePopup:(NSString *)title message:(NSString *)message delegate:(id)delegate
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
													message:message
												   delegate:delegate
										  cancelButtonTitle:@"Decline"
										  otherButtonTitles: @"Accept", nil];
	
    [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
    //	[alert show];
	//-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
}	

+(void)showTwoButtonPopupWithTitle:(NSString *)title message:(NSString *)message button1:(NSString *)button1 button2:(NSString *)button2 delegate:(id)delegate
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
													message:message
												   delegate:delegate
										  cancelButtonTitle:button1
										  otherButtonTitles: button2, nil];
	
    [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
    //	[alert show];
	//-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
}	

+(NSArray *)getContentsOfFlatFile:(NSString *)filename
{
	NSString *defaultPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:filename];
	NSFileHandle *fh = [NSFileHandle fileHandleForReadingAtPath:defaultPath];
	if(!fh)
		[ProjectFunctions showAlertPopup:@"File not Found!" message:[NSString stringWithFormat:@"File: %@ not found.", filename]];
	[fh closeFile];
	
	NSString *contents = [NSString stringWithContentsOfFile:defaultPath encoding:NSUTF8StringEncoding error:nil];
	NSArray *lines = [contents componentsSeparatedByString:@"\n"];
	return lines;
}

+(void)updateNewvalueIfNeeded:(NSString *)value type:(NSString *)type mOC:(NSManagedObjectContext *)mOC
{
	if([value length]==0)
		return;
	
	NSString *scrubbedValue = [ProjectFunctions scrubRefData:value context:mOC];
	if (![scrubbedValue isEqualToString:value]) {
		NSLog(@"Whoa!!! This should not be added: %@ %@", value, scrubbedValue);
		return;
	}
	
	NSString *entityname = [type uppercaseString];
	if([type isEqualToString:@"Game"])
		entityname = @"GAMETYPE";
	
	if(entityname.length==0)
		return;
	
	NSArray *items = [CoreDataLib selectRowsFromTable:entityname mOC:mOC];
	BOOL newEntryFlg=YES;
	for (NSManagedObject *mo in items) {
		NSString *name = [mo valueForKey:@"name"];
		if([name isEqualToString:value])
			newEntryFlg=NO;
	}
	if(newEntryFlg)
		[CoreDataLib insertAttributeManagedObject:entityname valueList:[NSArray arrayWithObjects:value, nil] mOC:mOC];
}

+(BOOL)limitTextViewLength:(UITextView *)textViewLocal currentText:(NSString *)currentText string:(NSString *)string limit:(int)limit saveButton:(UIBarButtonItem *)saveButton resignOnReturn:(BOOL)resignOnReturn
{
	if([string isEqualToString:@"|"])
		return NO;
	if([string isEqualToString:@"`"])
		return NO;
	
	if(saveButton != nil) {
		if([string length]==0 && [currentText length]==1)
			saveButton.enabled = NO;
		else 
			saveButton.enabled = YES;
	}
	
	if(resignOnReturn && [string isEqualToString:@"\n"]) {
		[textViewLocal resignFirstResponder];
		return NO;
	}
	
	if( [string length]==0)
		return YES;
	
	if([textViewLocal.text length]>=limit)
		return NO;  //prevents change
	else {
		return YES;
	}
}

+(BOOL)limitTextFieldLength:(UITextField *)textViewLocal currentText:(NSString *)currentText string:(NSString *)string limit:(int)limit saveButton:(UIBarButtonItem *)saveButton resignOnReturn:(BOOL)resignOnReturn
{
//-(BOOL)textField:(UITextField *)textFieldlocal shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
	if([string isEqualToString:@"|"])
		return NO;
	if([string isEqualToString:@"`"])
		return NO;
	
	if(saveButton != nil) {
		if([string length]==0 && [currentText length]==1)
			saveButton.enabled = NO;
		else 
			saveButton.enabled = YES;
	}
	
	if(resignOnReturn && [string isEqualToString:@"\n"]) {
		[textViewLocal resignFirstResponder];
		return NO;
	}
	
	if( [string length]==0)
		return YES;
	
	if([textViewLocal.text length]>=limit)
		return NO;  //prevents change
	else {
		return YES;
	}
}

+(void)SetButtonAttributes:(UIButton *)button yearStr:(NSString *)yearStr enabled:(BOOL)enabled
{
	[button setTitle:yearStr forState:UIControlStateNormal];
	
	button.enabled=enabled;
	if([yearStr isEqualToString:@"0"]) {
		[button setTitle:@"-" forState:UIControlStateNormal];
		button.enabled=NO;
	}
}

+(void)resetTheYearSegmentBar:(UITableView *)tableView displayYear:(int)displayYear MoC:(NSManagedObjectContext *)MoC leftButton:(UIButton *)leftButton rightButton:(UIButton *)rightButton displayYearLabel:(UILabel *)displayYearLabel
{
    
    int prevYear = displayYear-1;
	int nextYear = displayYear+1;

    int minYear = [[ProjectFunctions getUserDefaultValue:@"minYear2"] intValue];
    NSString *maxYearStr = [ProjectFunctions getUserDefaultValue:@"maxYear"];

    int maxYear = [maxYearStr intValue];
    

    if(displayYear>0)
        [displayYearLabel performSelectorOnMainThread:@selector(setText: ) withObject:[NSString stringWithFormat:@"%d", displayYear] waitUntilDone:NO];
    
    if(displayYear==0) {
        if([displayYearLabel.text length]<=1)
            [displayYearLabel performSelectorOnMainThread:@selector(setText: ) withObject:NSLocalizedString(@"LifeTime", nil) waitUntilDone:NO];

		if(maxYear>0)
			[ProjectFunctions SetButtonAttributes:leftButton yearStr:maxYearStr enabled:YES];
		if(prevYear>0)
			[ProjectFunctions SetButtonAttributes:rightButton yearStr:@"0" enabled:YES];
		return;
	}
	
	
    if(prevYear>=minYear)
        [ProjectFunctions SetButtonAttributes:leftButton yearStr:[NSString stringWithFormat:@"%d", prevYear] enabled:YES];
    else
        [ProjectFunctions SetButtonAttributes:leftButton yearStr:@"-" enabled:NO];
 

	if(nextYear>maxYear)
		[ProjectFunctions SetButtonAttributes:rightButton yearStr:NSLocalizedString(@"LifeTime", nil) enabled:YES];
	else
		[ProjectFunctions SetButtonAttributes:rightButton yearStr:[NSString stringWithFormat:@"%d", nextYear] enabled:YES];
	
}

+(NSString *)labelForYearValue:(int)yearValue
{
	NSString *yearString = @"";
	if(yearValue==0)
		yearString = NSLocalizedString(@"LifeTime", nil);
	else
		yearString = [NSString stringWithFormat:@"%d", yearValue];
	return yearString;
}

+(void)displayLoginMessage {
	if ([self isLiteVersion])
		[ProjectFunctions showAlertPopup:@"Notice" message:NSLocalizedString(@"upgradeMessage", nil)];
	else
		[ProjectFunctions showAlertPopup:@"Notice" message:NSLocalizedString(@"loginMessage", nil)];
}



+(NSString *)labelForGameSegment:(int)segmentIndex
{
	NSString *name=@"";
	if(segmentIndex==0) {
		name = @"All Game Types";
	}
	if(segmentIndex==1) {
		name = @"Cash";
	}
	if(segmentIndex==2) {
		name = @"Tournament";
	}
	return name;
}

+(int)selectedSegmentForGameType:(NSString *)gameType
{
	if([gameType isEqualToString:@"Cash"])
		return 1;
	else if([gameType isEqualToString:@"Tournament"])
		return 2;
	else
		return 0;
}

+(NSManagedObject *)insertRecordIntoEntity:(NSManagedObjectContext *)mOC EntityName:(NSString *)EntityName valueList:(NSArray *)valueList
{
	NSArray *keyList = [ProjectFunctions getColumnListForEntity:EntityName type:@"column"];
	NSArray *typeList = [ProjectFunctions getColumnListForEntity:EntityName type:@"type"];

	NSManagedObject *mo = [NSEntityDescription insertNewObjectForEntityForName:EntityName inManagedObjectContext:mOC];
	
	[CoreDataLib updateManagedObject:mo keyList:keyList valueList:valueList typeList:typeList mOC:mOC];
	return mo;
}

+(void)updateYourOwnFriendRecord:(NSManagedObjectContext *)MoC list:(NSMutableArray *)list
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"user_id = %d", 0];
	NSManagedObject *mo = nil;
	NSArray *items = [CoreDataLib selectRowsFromEntity:@"FRIEND" predicate:predicate sortColumn:nil mOC:MoC ascendingFlg:YES];
	
	NSMutableArray *selfList = [[NSMutableArray alloc] initWithArray:list];
	[selfList insertObject:[[NSDate date] convertDateToStringWithFormat:nil] atIndex:1];
	[selfList insertObject:[ProjectFunctions getUserDefaultValue:@"firstName"] atIndex:2];
	[selfList insertObject:@"Active" atIndex:3];
	[selfList insertObject:[ProjectFunctions getUserDefaultValue:@"userName"] atIndex:4];
	[selfList insertObject:@"" atIndex:5];
	[selfList insertObject:@"0" atIndex:6]; // user_id
	
	if([items count]==0) {
		[ProjectFunctions insertRecordIntoEntity:MoC EntityName:@"FRIEND" valueList:selfList];
	} else {
		mo = [items objectAtIndex:0];
		[CoreDataLib updateManagedObjectForEntity:mo entityName:@"FRIEND" valueList:selfList mOC:MoC];
	}
}

+(void)checkForFriendRecords:(NSManagedObjectContext *)MoC
{
	NSArray *nameList = [NSArray arrayWithObjects:@"Username", @"Password", nil];
	
	NSArray *valueList = [NSArray arrayWithObjects:[ProjectFunctions getUserDefaultValue:@"userName"], [ProjectFunctions getUserDefaultValue:@"password"], nil];
	NSString *webAddr = @"http://www.appdigity.com/poker/pokerCheckFriends.php";
	NSString *responseStr = [WebServicesFunctions getResponseFromServerUsingPost:webAddr fieldList:nameList valueList:valueList];
	NSArray *friends = [responseStr componentsSeparatedByString:@"\n"];
	for(NSString *friend in friends) {
		NSArray *fields = [friend componentsSeparatedByString:@"|"];
		int user_id = [[fields stringAtIndex:0] intValue];
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"user_id = %d", user_id];
		NSArray *items = [CoreDataLib selectRowsFromEntity:@"FRIEND" predicate:predicate sortColumn:nil mOC:MoC ascendingFlg:YES];
		if([items count]==0) {
			NSMutableArray *selfList = [[NSMutableArray alloc] init];
			[selfList addObject:[[NSDate date] convertDateToStringWithFormat:nil]];
			[selfList addObject:[[NSDate date] convertDateToStringWithFormat:nil]];
			[selfList addObject:[fields stringAtIndex:2]];
			[selfList addObject:@"Active"];
			[selfList addObject:[fields stringAtIndex:1]];
			[selfList addObject:@"Default"];
			[selfList addObject:[fields stringAtIndex:0]];
			[ProjectFunctions insertRecordIntoEntity:MoC EntityName:@"FRIEND" valueList:selfList];
		}
	}
}

+(NSString *)getLastestStatsForFriend:(NSManagedObjectContext *)MoC
{
	NSMutableArray *list = [[NSMutableArray alloc] init];
	NSString *version = [ProjectFunctions getProjectVersion];
	NSArray *fields = [ProjectFunctions getFieldListForVersion:version type:@"FRIEND"];
	for(NSString *field in fields)
		[list addObject:[CoreDataLib getGameStat:MoC dataField:field predicate:nil]];

	[list replaceObjectAtIndex:23 withObject:[CoreDataLib getGameStatWithLimit:MoC dataField:@"amountRisked" predicate:nil limit:10]];
	[list replaceObjectAtIndex:24 withObject:[CoreDataLib getGameStat:MoC dataField:@"amountRiskedThisYear" predicate:nil]];
	[list replaceObjectAtIndex:25 withObject:[CoreDataLib getGameStat:MoC dataField:@"amountRiskedThisMonth" predicate:nil]];
	[ProjectFunctions updateYourOwnFriendRecord:MoC list:list];
	[ProjectFunctions checkForFriendRecords:MoC];
	
	return [NSString stringWithFormat:@"%@\n%@\n%@", version, [list componentsJoinedByString:@"|"], [ProjectFunctions getLast5GamesForFriend:MoC]];
}


+(NSString *)getLast5GamesForFriend:(NSManagedObjectContext *)MoC
{
	NSArray *keyList = [ProjectFunctions getColumnListForEntity:@"GAME" type:@"column"];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"user_id = %d", 0];
	NSArray *items = [CoreDataLib selectRowsFromEntity:@"GAME" predicate:predicate sortColumn:@"startTime" mOC:MoC ascendingFlg:NO];
	NSMutableString *line = [NSMutableString stringWithCapacity:50000];
	
	int count = (int)[items count];
	if(count>10)
		count=10;
	
	for(int i=0; i<count; i++) {
		NSManagedObject *mo = [items objectAtIndex:i];
		for(NSString *key in keyList) {
			NSString *value = [mo valueForKey:key];
			if([key isEqualToString:@"startTime"] || [key isEqualToString:@"endTime"] || [key isEqualToString:@"gameDate"] || [key isEqualToString:@"created"]) {
				value = [[mo valueForKey:key] convertDateToStringWithFormat:nil];
			}
			[line appendFormat:@"%@%@", value, @"|"];
		}
		[line appendString:@"\n"];
	}
	return line;
}

+(UITableViewCell *)getGameCell:(NSManagedObject *)mo CellIdentifier:(NSString *)CellIdentifier tableView:(UITableView *)tableView evenFlg:(BOOL)evenFlg
{
	GameCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[GameCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
	}
	
	[GameCell populateCell:cell obj:mo evenFlg:evenFlg];

	
	


	return cell;
}

+(int)getSegmentValueForSegment:(int)segment currentValue:(NSString *)currentValue startGameScreen:(BOOL)startGameScreen
{
	NSArray *dtValues = [ProjectFunctions getArrayForSegment:segment];
	int i=0;
	int result=0;
	for(NSString *value in dtValues) {
		if([value isEqualToString:currentValue])
			result = i;
		i++;
	}
	
	if(startGameScreen && result==4)
		return 0; // make sure it doesn't auto skip to next screen
	if(startGameScreen && result==3 && (segment==0 || segment==2))
		return 0;
	
	return result;
}

+(void)initializeSegmentBar:(UISegmentedControl *)segmentBar defaultValue:(NSString *)defaultValue field:(NSString *)field
{
	NSMutableArray *options = [[NSMutableArray alloc] init];
	if (defaultValue.length>0)
		[options addObject:defaultValue];
	
	NSString *fieldValues = [ProjectFunctions getUserDefaultValue:[NSString stringWithFormat:@"%@Segments", field]];
	NSArray *items = [fieldValues componentsSeparatedByString:@"|"];
	for (NSString *item in items) {
		NSArray *components = [item componentsSeparatedByString:@":"];
		if (components.count>1) {
			NSString *value = [components objectAtIndex:1];
			if (value.length >0 && ![value isEqualToString:defaultValue])
				[options addObject:value];
		}
	}
	NSArray *hardCodedValues = [self getDefaultOptionsForField:field];
	for (NSString *item in hardCodedValues) {
		if (item.length >0 && ![item isEqualToString:defaultValue])
			[options addObject:item];
	}
	int numSegs = (int)[segmentBar numberOfSegments];
	for(int i=0; i<numSegs; i++) {
		NSString *title = [segmentBar titleForSegmentAtIndex:i];
		if([@"edit" isEqualToString:[title lowercaseString]])
			[segmentBar setTitle:[NSString fontAwesomeIconStringForEnum:FAPencil] forSegmentAtIndex:i];
		else
			[segmentBar setTitle:[options objectAtIndex:i] forSegmentAtIndex:i];
	}
}

+(NSArray *)getDefaultOptionsForField:(NSString *)field {
	if ([field isEqualToString:@"gametype"])
		return [self getArrayForSegment:0];
	if ([field isEqualToString:@"stakes"])
		return [self getArrayForSegment:1];
	if ([field isEqualToString:@"limit"])
		return [self getArrayForSegment:2];
	return [self getArrayForSegment:3];
}



+(void)insertFriendGames:(NSMutableArray *)components friend_id:(int)friend_id mOC:(NSManagedObjectContext *)mOC
{
	if([components count]<24 || friend_id==0)
		return;
	NSManagedObject *mo = [NSEntityDescription insertNewObjectForEntityForName:@"GAME" inManagedObjectContext:mOC];
	[components replaceObjectAtIndex:23 withObject:[NSString stringWithFormat:@"%d", friend_id]];
	[components removeLastObject];
	[ProjectFunctions updateGameInDatabase:mOC mo:mo valueList:components];
	[ProjectFunctions scrubDataForObj:mo context:mOC];
}

+(void)updateOrInsertThisFriend:(NSManagedObjectContext *)mOC line:(NSString *)line
{
	NSArray *components = [line componentsSeparatedByString:@"<li>"];
	if([components count]>3) {
		NSString *friend_id = [components stringAtIndex:0];
		NSString *email = [components stringAtIndex:1];
		NSString *name = [components stringAtIndex:2];
		NSString *status = [components stringAtIndex:3];
		NSString *data = [components stringAtIndex:4];
		
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"email = %@", email];
		NSManagedObject *mo = nil;
		NSArray *items = [CoreDataLib selectRowsFromEntity:@"FRIEND" predicate:predicate sortColumn:nil mOC:mOC ascendingFlg:YES];
		if([items count]==0) {
			NSArray *valueList = [NSArray arrayWithObjects: 
								  [[NSDate date] convertDateToStringWithFormat:nil], 
								  [[NSDate date] convertDateToStringWithFormat:nil], 
								  name, 
								  status, 
								  email, 
								  @"", 
								  friend_id, 
								  @"", 
								  @"", 
								  @"", 
								  @"", 
								  @"", 
								  @"", 
								  @"", 
								  @"", 
								  @"", 
								  @"", 
								  @"", 
								  @"", 
								  @"", 
								  @"", 
								  @"", 
								  nil];
			mo = [ProjectFunctions insertRecordIntoEntity:mOC EntityName:@"FRIEND" valueList:valueList];
		} else {
			mo = [items objectAtIndex:0];
		}
		
		if(mo != nil && [friend_id intValue]>0) {
			// delete old games
			NSPredicate *predicate = [NSPredicate predicateWithFormat:@"user_id = %@", friend_id];
			NSArray *friendGames = [CoreDataLib selectRowsFromEntity:@"GAME" predicate:predicate sortColumn:nil mOC:mOC ascendingFlg:YES];
			for(NSManagedObject *gameObject in friendGames)
				[mOC deleteObject:gameObject];
			
			NSArray *lines = [data componentsSeparatedByString:@"<br>"];
			int i=0;
			NSString *version = @"";
			for(NSString *line in lines) {
				if(i==0)
					version=line;
				NSMutableArray *valuesAmount = [NSMutableArray arrayWithArray:[line componentsSeparatedByString:@"|"]];
				if(i==1 && [valuesAmount count]>34) {
					// insert basic values
					if([version isEqualToString:@"Version 1.0"]) {
						NSLog(@"friend: [%@]", friend_id);
						NSArray *valueList = [NSArray arrayWithObjects:
											  [valuesAmount stringAtIndex:0], // last date
											  [[NSDate date] convertDateToStringWithFormat:nil], 
											  name, 
											  status, 
											  email, 
											  @"", 
											  friend_id, 
											  [valuesAmount stringAtIndex:1], 
											  [valuesAmount stringAtIndex:2], 
											  [valuesAmount stringAtIndex:3], 
											  [valuesAmount stringAtIndex:4], 
											  [valuesAmount stringAtIndex:5], 
											  [valuesAmount stringAtIndex:6], 
											  [valuesAmount stringAtIndex:7], 
											  [valuesAmount stringAtIndex:8], 
											  [valuesAmount stringAtIndex:9], 
											  [valuesAmount stringAtIndex:10], 
											  [valuesAmount stringAtIndex:11], 
											  [valuesAmount stringAtIndex:12], 
											  [valuesAmount stringAtIndex:13], 
											  [valuesAmount stringAtIndex:14], 
											  [valuesAmount stringAtIndex:15], 
											  [valuesAmount stringAtIndex:16], 
											  [valuesAmount stringAtIndex:17], 
											  [valuesAmount stringAtIndex:18], 
											  [valuesAmount stringAtIndex:19], 
											  [valuesAmount stringAtIndex:20], 
											  [valuesAmount stringAtIndex:21], 
											  [valuesAmount stringAtIndex:22], 
											  [valuesAmount stringAtIndex:23], 
											  [valuesAmount stringAtIndex:24], 
											  [valuesAmount stringAtIndex:25], 
											  [valuesAmount stringAtIndex:26], 
											  [valuesAmount stringAtIndex:27], 
											  [valuesAmount stringAtIndex:28], 
											  [valuesAmount stringAtIndex:29], 
											  [valuesAmount stringAtIndex:30], 
											  [valuesAmount stringAtIndex:31], 
											  [valuesAmount stringAtIndex:32], 
											  [valuesAmount stringAtIndex:33], 
											  [valuesAmount stringAtIndex:34], 
											  nil];
						[CoreDataLib updateManagedObjectForEntity:mo entityName:@"FRIEND" valueList:valueList mOC:mOC];
					}
				} else {
					// insert games
					[ProjectFunctions insertFriendGames:valuesAmount friend_id:[friend_id intValue] mOC:mOC];
				}
				
				i++;
			}
		}
		
		[mOC save:nil];
	
	}
}

+(void)updateOrInsertThisMessage:(NSManagedObjectContext *)mOC line:(NSString *)line
{
	NSArray *components = [line componentsSeparatedByString:@"|"];
	NSManagedObject *mo = [NSEntityDescription insertNewObjectForEntityForName:@"MESSAGE" inManagedObjectContext:mOC];
	[CoreDataLib updateManagedObjectForEntity:mo entityName:@"MESSAGE" valueList:components mOC:mOC];
}

+(int)updateFriendRecords:(NSManagedObjectContext *)mOC responseStr:(NSString *)responseStr delegate:(id)delegate refreshDateLabel:(UILabel *)refreshDateLabel
{
	NSString *syncDate = [[NSDate date] convertDateToStringWithFormat:nil];
	NSArray *lines = [responseStr componentsSeparatedByString:@"<hr>"];
	int i=0;
	NSString *type = @"None";
	int friendRecords=0;
	int messages=0;
	for(NSString *line in lines) {
		
		if([type isEqualToString:@"-----FRIEND"] && [line length]>15) {
			[ProjectFunctions updateOrInsertThisFriend:mOC line:line];
			friendRecords++;
		}
		
		if([type isEqualToString:@"-----MESSAGE"] && [line length]>15) {
			[ProjectFunctions updateOrInsertThisMessage:mOC line:line];
			messages++;
		}
		
		if([line isEqualToString:@"-----FRIEND"] || [line isEqualToString:@"-----MESSAGE"])
			type = line;
		i++;
	}
	[ProjectFunctions setUserDefaultValue:[ProjectFunctions getUserDefaultValue:@"lastSyncedDate"] forKey:@"prevSyncedDate"];
	[ProjectFunctions setUserDefaultValue:syncDate forKey:@"lastSyncedDate"];
	if(refreshDateLabel != nil)
		refreshDateLabel.text = syncDate;
	if(0 && (id)delegate != nil) {
		if(friendRecords==0 && messages==0)
			[ProjectFunctions showAlertPopupWithDelegate:@"Success" message:@"Server data synced" delegate:(id)delegate];
		else if(friendRecords>0)
			[ProjectFunctions showAlertPopupWithDelegate:@"Success" message:@"Server data synced. You have an update to your firend's games" delegate:(id)delegate];
		else 
			[ProjectFunctions showAlertPopupWithDelegate:@"Success" message:@"Server data synced. You have a new mail message" delegate:(id)delegate];
	}
	return friendRecords;
}

+(NSString *)pullGameString:(NSManagedObjectContext *)mOC mo:(NSManagedObject *)mo {
    return [NSString stringWithFormat:@"%@|%@|%@|%@|%@|%@|%@|%@|%@|%@|%@|%@|%@|%@|%d|%d",
                [[mo valueForKey:@"startTime"] convertDateToStringWithFormat:nil],
                [mo valueForKey:@"buyInAmount"],
                [mo valueForKey:@"rebuyAmount"],
                [mo valueForKey:@"cashoutAmount"],
            [mo valueForKey:@"location"],
            [mo valueForKey:@"minutes"],
            [mo valueForKey:@"Type"],
                ([[mo valueForKey:@"status"] isEqualToString:@"In Progress"])?@"Y":@"N",
            [mo valueForKey:@"gametype"],
            [mo valueForKey:@"stakes"],
            [mo valueForKey:@"limit"],
            [[NSDate date] convertDateToStringWithFormat:nil],
            [[mo valueForKey:@"endTime"] convertDateToStringWithFormat:nil],
            [ProjectFunctions getMoneySymbol],
            [[ProjectFunctions getUserDefaultValue:@"latestPos"] intValue],
            [[mo valueForKey:@"foodDrinks"] intValue]
            ];
  
}

+(NSString *)getLast90Days:(NSManagedObjectContext *)mOC
{
    NSMutableString *last90Str = [[NSMutableString alloc] initWithCapacity:1000];
    NSDate *startDate = [[NSDate date] dateByAddingTimeInterval:-1*60*60*24*90];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"startTime >= %@", startDate];
    NSArray *games = [CoreDataLib selectRowsFromEntity:@"GAME" predicate:predicate sortColumn:@"startTime" mOC:mOC ascendingFlg:YES];
    for(NSManagedObject *game in games)
        [last90Str appendString:[NSString stringWithFormat:@"%@|%f:", [[game valueForKey:@"startTime"] convertDateToStringWithFormat:@"MM/dd/yyyy"], [[game valueForKey:@"winnings"] doubleValue]]];
    return last90Str;
}

+(BOOL)uploadUniverseStats:(NSManagedObjectContext *)mOC
{
	// Step 1: Upload your stats to the server
	if([[ProjectFunctions getUserDefaultValue:@"userName"] length]==0)
		return NO;
	if([[ProjectFunctions getUserDefaultValue:@"password"] length]==0)
		return NO;

    
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"user_id = %d ", 0];
    NSArray *games = [CoreDataLib selectRowsFromEntity:@"GAME" predicate:predicate sortColumn:@"startTime" mOC:mOC ascendingFlg:NO];
    NSString *dateText = @"";
    NSString *yearText = @"";
    NSString *lastGame = nil;
    NSString *playFlg = nil;
    
    if([games count]>0) {
        NSManagedObject *mo = [games objectAtIndex:0];
        lastGame = [ProjectFunctions pullGameString:mOC mo:mo];
        NSString *status = [mo valueForKey:@"status"];
        playFlg = ([status isEqualToString:@"In Progress"])?@"Y":@"N";
    }
    dateText = [ProjectFunctions getNetTrackerMonth];
    yearText = [[NSDate date] convertDateToStringWithFormat:@"yyyy"];
    
    //----------last10Stats--------
	NSPredicate *predicateLast10 = [NSPredicate predicateWithFormat:@"user_id = %d AND status = 'Completed'", 0];
    NSString *last10Stats = [CoreDataLib getGameStatWithLimit:mOC dataField:@"totalStatsL10" predicate:predicateLast10 limit:10];

    
    //----------yearStats--------
    NSPredicate *predicateYear = [NSPredicate predicateWithFormat:@"user_id = %d AND year = %@ AND status = 'Completed'", 0, [[NSDate date] convertDateToStringWithFormat:@"yyyy"]];
    NSString *yearStats = [CoreDataLib getGameStat:mOC dataField:@"totalStats" predicate:predicateYear];

    //----------monthStats--------
    NSMutableString *thisMonthStr = [[NSMutableString alloc] initWithCapacity:1000];
    NSPredicate *predicateMonth = [NSPredicate predicateWithFormat:@"user_id = %d AND year = %@ AND month = %@ AND status = 'Completed'", 0, [[NSDate date] convertDateToStringWithFormat:@"yyyy"], [ProjectFunctions getMonthFromDate:[NSDate date]]];
    NSString *monthStats = [CoreDataLib getGameStat:mOC dataField:@"totalStats" predicate:predicateMonth];
    NSArray *monthGames = [CoreDataLib selectRowsFromEntity:@"GAME" predicate:predicateMonth sortColumn:@"startTime" mOC:mOC ascendingFlg:YES];
    for(NSManagedObject *mo in monthGames)
        [thisMonthStr appendString:[NSString stringWithFormat:@"%@|%f:", [[mo valueForKey:@"startTime"] convertDateToStringWithFormat:@"MM/dd/yyyy"], [[mo valueForKey:@"winnings"] doubleValue]]];
    
    //----------last10 Games--------
    NSArray *last10 = [CoreDataLib selectRowsFromEntityWithLimit:@"GAME" predicate:predicateLast10 sortColumn:@"startTime" mOC:mOC ascendingFlg:NO limit:10];
    NSMutableArray *last10Reverse = [[NSMutableArray alloc] initWithCapacity:10];
    NSString *last10String = @"";
    for(NSManagedObject *mo in last10) {
        last10String = [NSString stringWithFormat:@"%@[li]%@", last10String, [ProjectFunctions pullGameString:mOC mo:mo]];
        [last10Reverse addObject:[NSString stringWithFormat:@"%@|%f", [[mo valueForKey:@"startTime"] convertDateToStringWithFormat:@"MM/dd/yyyy"], [[mo valueForKey:@"winnings"] doubleValue]]];
    }


    NSString *last90Days = [ProjectFunctions getLast90Days:mOC];
    last10Reverse = [NSMutableArray arrayWithArray:[self reverseArray:last10Reverse]];
	int iconGroupNumber = [[ProjectFunctions getUserDefaultValue:@"IconGroupNumber"] intValue];
	NSString *themeobj = [ThemeColorObj packageThemeAsString];

    NSString *dataUpload = [NSString stringWithFormat:@"Last10|%@[xx]%@|%@[xx]%@|%@[xx]%@[xx]%@[xx]%@|%@|%@[xx]%@[xx]%@[xx]%@[xx]%d[xx]%@",
                            last10Stats,
                            dateText,	monthStats,
                            yearText,	yearStats,
                            lastGame, 
                            last10String,
							playFlg, [ProjectFunctions getProjectDisplayVersion], [ProjectFunctions getMoneySymbol],
                            last90Days,
							thisMonthStr,
							[last10Reverse componentsJoinedByString:@":"],
							iconGroupNumber,
							themeobj];

    NSLog(@"Sending Universe tracker Stats...");
	NSLog(@"+++dataUpload: %@", dataUpload);
	NSArray *nameList = [NSArray arrayWithObjects:@"Username", @"Password", @"LastUpd", @"Data", @"dateText", nil];
	NSDate *lastUpd = [[ProjectFunctions getUserDefaultValue:@"lastSyncedDate"] convertStringToDateFinalSolution];
	NSString *lastUpdDate = [lastUpd convertDateToStringWithFormat:@"MM/dd/yyyy HH:mm:ss"];


    NSArray *valueList = [NSArray arrayWithObjects:[ProjectFunctions getUserDefaultValue:@"userName"], [ProjectFunctions getUserDefaultValue:@"password"], lastUpdDate, dataUpload, dateText, nil];
	NSString *webAddr = @"http://www.appdigity.com/poker/pokerUploadUniverseStats.php";
	NSString *responseStr = [WebServicesFunctions getResponseFromServerUsingPost:webAddr fieldList:nameList valueList:valueList];
	NSLog(@"+++responseStr: %@", responseStr);
    if([responseStr isEqualToString:@"Success"])
        return YES;
    else
        return NO;
}

+(NSArray *)reverseArray:(NSArray *)array
{
    NSMutableArray *reverseArray = [[NSMutableArray alloc] initWithCapacity:[array count]];
    for(int i=(int)[array count]-1; i>=0; i--)
        [reverseArray addObject:[array objectAtIndex:i]];
    return reverseArray;
}

+(int)countFriendsPlaying {
 	NSArray *nameList = [NSArray arrayWithObjects:@"Username", @"Password", nil];
	NSString *userName = @"x";
	NSString *password = @"x";
	if([ProjectFunctions getUserDefaultValue:@"userName"])
		userName = [ProjectFunctions getUserDefaultValue:@"userName"];
	if([ProjectFunctions getUserDefaultValue:@"password"])
		password = [ProjectFunctions getUserDefaultValue:@"password"];
    NSArray *valueList = [NSArray arrayWithObjects:userName, password, nil];
	NSString *webAddr = @"http://www.appdigity.com/poker/pokerCheckFriendsPlaying.php";
	NSString *responseStr = [WebServicesFunctions getResponseFromServerUsingPost:webAddr fieldList:nameList valueList:valueList];
    //    NSLog(@"responseStr: %@", responseStr);
    return [responseStr intValue];
}

+(NSString *)getFriendsPlayingData {
    NSLog(@"Getting friend data...");
 	NSArray *nameList = [NSArray arrayWithObjects:@"Username", @"Password", nil];
	NSString *userName = @"x";
	NSString *password = @"x";
	if([ProjectFunctions getUserDefaultValue:@"userName"])
		userName = [ProjectFunctions getUserDefaultValue:@"userName"];
	if([ProjectFunctions getUserDefaultValue:@"password"])
		password = [ProjectFunctions getUserDefaultValue:@"password"];
    NSArray *valueList = [NSArray arrayWithObjects:userName, password, nil];
	NSString *webAddr = @"http://www.appdigity.com/poker/pokergetFriendsPlayingData.php";
	NSString *responseStr = [WebServicesFunctions getResponseFromServerUsingPost:webAddr fieldList:nameList valueList:valueList];
    return responseStr;
}


+(BOOL)syncDataWithServer:(NSManagedObjectContext *)mOC delegate:(id)delegate refreshDateLabel:(UILabel *)refreshDateLabel
{
	// Step 1: Upload your stats to the server
	if([[ProjectFunctions getUserDefaultValue:@"userName"] length]==0)
		return NO;
	if([[ProjectFunctions getUserDefaultValue:@"password"] length]==0)
		return NO;
	
	NSString *dataUpload = [ProjectFunctions getLastestStatsForFriend:mOC];
	NSArray *nameList = [NSArray arrayWithObjects:@"Username", @"Password", @"LastUpd", @"Data", @"dateText", nil];
	NSDate *lastUpd = [[ProjectFunctions getUserDefaultValue:@"lastSyncedDate"] convertStringToDateWithFormat:nil];
	NSString *lastUpdDate = [lastUpd convertDateToStringWithFormat:@"MM/dd/yyyy HH:mm:ss"];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"user_id = %d", 0];
	NSArray *items = [CoreDataLib selectRowsFromEntity:@"GAME" predicate:predicate sortColumn:@"startTime" mOC:mOC ascendingFlg:NO];
    NSString *dateText = @"";
    if([items count]>0) {
        NSManagedObject *lastGame = [items objectAtIndex:0];
        NSDate *startDate = [lastGame valueForKey:@"startTime"];
        dateText = [startDate convertDateToStringWithFormat:@"yyyyMM"];
        NSLog(@"dateText: %@", dateText);
    }

	
	NSArray *valueList = [NSArray arrayWithObjects:[ProjectFunctions getUserDefaultValue:@"userName"], [ProjectFunctions getUserDefaultValue:@"password"], lastUpdDate, dataUpload, dateText, nil];
	NSString *webAddr = @"http://www.appdigity.com/poker/pokerSyncData.php";
	NSString *responseStr = [WebServicesFunctions getResponseFromServerUsingPost:webAddr fieldList:nameList valueList:valueList];
	
	if([WebServicesFunctions validateStandardResponse:responseStr delegate:(id)delegate]) {
		// Step 2: Based on the response, update the data on the phone to match the server.
		[ProjectFunctions updateFriendRecords:mOC responseStr:responseStr delegate:delegate refreshDateLabel:refreshDateLabel];
		return YES;
		
	} // Success
	return NO;
}

+(NSString *)formatForDataBase:(NSString *)str
{
	str = [str stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
	str = [str stringByReplacingOccurrencesOfString:@"`" withString:@"\\'"];
	return [str stringByReplacingOccurrencesOfString:@"\"" withString:@"\\'"];
}

+(NSString *)getDayTimeFromDate:(NSDate *)localDate
{
	NSArray *dayTimes = [ProjectFunctions namesOfAllDayTimes];
	int hour = [[localDate convertDateToStringWithFormat:@"H"] intValue];
	if(hour>=0 && hour < 12)
		return [dayTimes objectAtIndex:0];
	else if(hour>=12 && hour < 16)
		return [dayTimes objectAtIndex:1];
	else if(hour>=16 && hour < 20)
		return [dayTimes objectAtIndex:2];
	else 
		return [dayTimes objectAtIndex:3];
	
}

+(CGContextRef)contextRefForGraphofWidth:(int)totalWidth totalHeight:(int)totalHeight {
	UIGraphicsBeginImageContext(CGSizeMake(totalWidth,totalHeight));
	CGContextRef c = UIGraphicsGetCurrentContext();
	UIGraphicsPushContext(c); // <--
	CGContextSetLineCap(c, kCGLineCapRound);
	
	// draw Box---------------------
	CGContextSetLineWidth(c, 0);
	CGContextSetRGBStrokeColor(c, 0, 0, 0, 1); // blank
	CGContextSetRGBFillColor(c, 1, 1, 1, 1); // white
	CGContextFillRect(c, CGRectMake(0, 0, totalWidth, totalHeight));
	CGContextStrokeRect(c, CGRectMake(0, 0, totalWidth, totalHeight));
	
	return c;
}

+(int)drawZeroLineForContext:(CGContextRef)c min:(float)min max:(float)max bottomEdgeOfChart:(int)bottomEdgeOfChart leftEdgeOfChart:(int)leftEdgeOfChart totalWidth:(int)totalWidth
{
	UIBezierPath *aPath3 = [UIBezierPath bezierPath];
	[aPath3 moveToPoint:CGPointMake(leftEdgeOfChart, 0)];
	[aPath3 addLineToPoint:CGPointMake(totalWidth, 0)];
	[aPath3 addLineToPoint:CGPointMake(totalWidth, bottomEdgeOfChart)];
	[aPath3 addLineToPoint:CGPointMake(leftEdgeOfChart, bottomEdgeOfChart)];
	[aPath3 addLineToPoint:CGPointMake(leftEdgeOfChart, 0)];
	[aPath3 closePath];
	NSLog(@"+++++Adding Green!!!");
	[self addGradientToPath:aPath3 context:c color1:[ProjectFunctions themeBGColor] color2:[ProjectFunctions themeBGColor] lineWidth:0 imgWidth:totalWidth imgHeight:bottomEdgeOfChart];
	//	[self addGradientToPath:aPath3 context:c color1:[ProjectFunctions primaryButtonColor] color2:[ProjectFunctions primaryButtonColor] lineWidth:(int)1 imgWidth:totalWidth imgHeight:bottomEdgeOfChart];
	
	// draw zero line---------------
	CGContextSetRGBStrokeColor(c, 0.6, 0.2, 0.2, 1); // lightGray
	CGContextSetLineWidth(c, 2);
	//	int zeroLoc = max*yMultiplier-10;
	//	float percentOfScreen = max/(max-min);
	int zeroLoc = 0;
	if((max-min)>0)
		zeroLoc = bottomEdgeOfChart*max/(max-min);
	if(zeroLoc<bottomEdgeOfChart)
		[self drawLine:c startX:leftEdgeOfChart startY:zeroLoc endX:totalWidth endY:zeroLoc];
	
	// Draw horizontal and vertical baselines
	CGContextSetRGBStrokeColor(c, 0, 0, 0, 1); // black
	[self drawLine:c startX:leftEdgeOfChart startY:bottomEdgeOfChart endX:totalWidth endY:bottomEdgeOfChart];
	[self drawLine:c startX:leftEdgeOfChart startY:0 endX:leftEdgeOfChart endY:bottomEdgeOfChart];
	
	return zeroLoc;
}

+(int)drawGoalsZeroLineForContext:(CGContextRef)c min:(float)min max:(float)max bottomEdgeOfChart:(int)bottomEdgeOfChart leftEdgeOfChart:(int)leftEdgeOfChart totalWidth:(int)totalWidth
{
	UIBezierPath *aPath3 = [UIBezierPath bezierPath];
	[aPath3 moveToPoint:CGPointMake(leftEdgeOfChart, 0)];
	[aPath3 addLineToPoint:CGPointMake(totalWidth, 0)];
	[aPath3 addLineToPoint:CGPointMake(totalWidth, bottomEdgeOfChart)];
	[aPath3 addLineToPoint:CGPointMake(leftEdgeOfChart, bottomEdgeOfChart)];
	[aPath3 addLineToPoint:CGPointMake(leftEdgeOfChart, 0)];
	[aPath3 closePath];
	NSLog(@"+++++Adding Yellow!!!");
	//[self addGradientToPath:aPath3 context:c color1:[ProjectFunctions themeBGColor] color2:[ProjectFunctions themeBGColor] lineWidth:0 imgWidth:totalWidth imgHeight:bottomEdgeOfChart];
	[self addGradientToPath:aPath3 context:c color1:[ProjectFunctions primaryButtonColor] color2:[ProjectFunctions primaryButtonColor] lineWidth:(int)1 imgWidth:totalWidth imgHeight:bottomEdgeOfChart];
	
	// draw zero line---------------
	CGContextSetRGBStrokeColor(c, 0.6, 0.2, 0.2, 1); // lightGray
	CGContextSetLineWidth(c, 2);
	//	int zeroLoc = max*yMultiplier-10;
	//	float percentOfScreen = max/(max-min);
	int zeroLoc = 0;
	if((max-min)>0)
		zeroLoc = bottomEdgeOfChart*max/(max-min);
	if(zeroLoc<bottomEdgeOfChart)
		[self drawLine:c startX:leftEdgeOfChart startY:zeroLoc endX:totalWidth endY:zeroLoc];
	
	// Draw horizontal and vertical baselines
	CGContextSetRGBStrokeColor(c, 0, 0, 0, 1); // black
	[self drawLine:c startX:leftEdgeOfChart startY:bottomEdgeOfChart endX:totalWidth endY:bottomEdgeOfChart];
	[self drawLine:c startX:leftEdgeOfChart startY:0 endX:leftEdgeOfChart endY:bottomEdgeOfChart];
	
	return zeroLoc;
}

+(void)drawBottomLabelsForArray:(NSArray *)labels c:(CGContextRef)c bottomEdgeOfChart:(int)bottomEdgeOfChart leftEdgeOfChart:(int)leftEdgeOfChart totalWidth:(int)totalWidth
{
	int spacing = totalWidth/(labels.count+1);
	int XCord = leftEdgeOfChart+spacing/2-10;
	CGContextSetRGBFillColor(c, 0, 0, 0, 1); // black
	for(NSString *label in labels) {
		NSString *labelStr = label;
		if(labels.count>4 && label.length>4) {
			if(labels.count<10)
				labelStr = [NSString stringWithFormat:@"  %@", [label substringToIndex:3]];
			else
				labelStr = [label substringToIndex:3];
		}
		
		[labelStr drawAtPoint:CGPointMake(XCord+spacing/10, bottomEdgeOfChart+2) withFont:[UIFont fontWithName:@"Helvetica" size:18]];
		XCord+=spacing;
	}
}

+(void)drawBarChartForContext:(CGContextRef)c itemArray:(NSArray *)itemArray leftEdgeOfChart:(int)leftEdgeOfChart mainGoal:(int)mainGoal zeroLoc:(int)zeroLoc yMultiplier:(float)yMultiplier totalWidth:(int)totalWidth
{
	int spacing = totalWidth/(itemArray.count+1);
	int XCord = leftEdgeOfChart+spacing/2-10;
	for(NSString *item in itemArray) {
		float value = [item floatValue];
		
		UIColor *mainColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:1];
		UIColor *topColor = [UIColor colorWithRed:.5 green:0 blue:0 alpha:1];
		UIColor *sideColor = [UIColor colorWithRed:1 green:.8 blue:.8 alpha:1];
		
		if(value>=0) {
			if(value>=mainGoal) { // green
				mainColor = [UIColor colorWithRed:0 green:.8 blue:0 alpha:1];
				topColor = [UIColor colorWithRed:0 green:.5 blue:0 alpha:1];
				sideColor = [UIColor colorWithRed:.7 green:1 blue:.7 alpha:1];
			} else { // blue
				mainColor = [UIColor colorWithRed:0 green:.5 blue:1 alpha:1];
				topColor = [UIColor colorWithRed:0 green:0 blue:.5 alpha:1];
				sideColor = [UIColor colorWithRed:.5 green:.8 blue:1 alpha:1];
			}
		}
		
		
		int top = zeroLoc-value*yMultiplier;
		int bot = zeroLoc;
		if(value<0) {
			bot = top;
			top = zeroLoc;
		}
		
		if(value != 0) {
			int width=(totalWidth/(itemArray.count+2))-10;
			UIBezierPath *aPath = [UIBezierPath bezierPath];
			[aPath moveToPoint:CGPointMake(XCord, bot)];
			[aPath addLineToPoint:CGPointMake(XCord, top)];
			[aPath addLineToPoint:CGPointMake(XCord+width, top)];
			[aPath addLineToPoint:CGPointMake(XCord+width, bot)];
			[aPath addLineToPoint:CGPointMake(XCord, bot)];
			[aPath closePath];
			[self addGradientToPath:aPath context:c color1:[UIColor whiteColor] color2:(UIColor *)mainColor lineWidth:(int)1 imgWidth:XCord+width imgHeight:300];
			
			UIBezierPath *aPath2 = [UIBezierPath bezierPath];
			[aPath2 moveToPoint:CGPointMake(XCord, top)];
			[aPath2 addLineToPoint:CGPointMake(XCord+10, top-10)];
			[aPath2 addLineToPoint:CGPointMake(XCord+10+width, top-10)];
			[aPath2 addLineToPoint:CGPointMake(XCord+width, top)];
			[aPath2 addLineToPoint:CGPointMake(XCord, top)];
			[aPath2 closePath];
			[self addGradientToPath:aPath2 context:c color1:[UIColor whiteColor] color2:(UIColor *)topColor lineWidth:(int)1 imgWidth:XCord+width imgHeight:300];

			UIBezierPath *aPath3 = [UIBezierPath bezierPath];
			[aPath3 moveToPoint:CGPointMake(XCord+width, top)];
			[aPath3 addLineToPoint:CGPointMake(XCord+width+10, top-10)];
			[aPath3 addLineToPoint:CGPointMake(XCord+10+width, bot-10)];
			[aPath3 addLineToPoint:CGPointMake(XCord+width, bot)];
			[aPath3 addLineToPoint:CGPointMake(XCord+width, bot)];
			[aPath3 closePath];
			[self addGradientToPath:aPath3 context:c color1:[UIColor whiteColor] color2:(UIColor *)sideColor lineWidth:(int)1 imgWidth:XCord+width imgHeight:300];

		}
		XCord+=spacing;
	}
}

+(NSArray *)getValuesForField:(NSString *)field context:(NSManagedObjectContext *)context year:(int)year type:(NSString *)type {
	NSMutableDictionary *daysOfWeekDict = [[NSMutableDictionary alloc] init];
	NSString *basicPred = [ProjectFunctions getBasicPredicateString:year type:type];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:basicPred];
	NSArray *allGames = [CoreDataLib selectRowsFromEntity:@"GAME" predicate:predicate sortColumn:nil mOC:context ascendingFlg:NO];
	for (NSManagedObject *mo in allGames) {
		[daysOfWeekDict setObject:@"1" forKey:[mo valueForKey:field]];
	}
	return [daysOfWeekDict allKeys];
}

+(NSArray *)namesOfAllMonths {
	NSMutableArray *array = [[NSMutableArray alloc] init];
	for (int i=1; i<=12; i++) {
		[array addObject:[ProjectFunctions getMonthFromDate:[[NSString stringWithFormat:@"%02d/01/2017", i] convertStringToDateWithFormat:@"MM/dd/yyyy"]]];
	}
	return array;
}

+(NSArray *)namesOfAllDayTimes {
	NSMutableArray *array = [[NSMutableArray alloc] init];
	[array addObject:NSLocalizedString(@"Morning", nil)];
	[array addObject:NSLocalizedString(@"Afternoon", nil)];
	[array addObject:NSLocalizedString(@"Evening", nil)];
	[array addObject:NSLocalizedString(@"Night", nil)];
	return array;
}

+(UIImage *)graphGoalsChart:(NSManagedObjectContext *)mOC displayYear:(int)displayYear chartNum:(int)chartNum goalFlg:(BOOL)goalFlg
{
	int totalWidth=640;
	int totalHeight=300;
	int leftEdgeOfChart=50;
	int bottomEdgeOfChart=totalHeight-25;
	
	int mainGoal=0;
	if(goalFlg)
		mainGoal = (chartNum==1)?[[ProjectFunctions getUserDefaultValue:@"profitGoal"] intValue]:[[ProjectFunctions getUserDefaultValue:@"hourlyGoal"] intValue];
	
	NSMutableArray *itemList = [[NSMutableArray alloc] init];
	NSString *basicPred = [ProjectFunctions getBasicPredicateString:displayYear type:@"All"];
	NSArray *months = [self namesOfAllMonths];
	double min=0;
	double max=0;
	for(NSString *month in months) {
		NSPredicate *predicate = [ProjectFunctions predicateForBasic:basicPred field:@"month" value:month];
		
		
		NSString *chart1 = [CoreDataLib getGameStat:mOC dataField:@"chart1" predicate:predicate];
		NSArray *values = [chart1 componentsSeparatedByString:@"|"];
		double winnings = [[values stringAtIndex:0] doubleValue];
		int minutes = [[values stringAtIndex:2] intValue];
		
		int hours = minutes/60;
		int hourlyRate = 0;
		if(hours>0)
			hourlyRate = winnings/hours;
		float amount = (chartNum==1)?winnings:hourlyRate;
		
		if(amount>max)
			max=amount;
		if(amount<min)
			min=amount;
		[itemList addObject:[NSString stringWithFormat:@"%f", amount]];
	}
	max*=1.1;
	double totalMoneyRange = max-min;
	
	float yMultiplier = 1;
	if(totalMoneyRange>0)
		yMultiplier = (float)bottomEdgeOfChart/totalMoneyRange;
	
	
	UIImage *dynamicChartImage = [[UIImage alloc] init];
	
	CGContextRef c = [self contextRefForGraphofWidth:totalWidth totalHeight:totalHeight];
	
	int zeroLoc = [self drawGoalsZeroLineForContext:c min:min max:max bottomEdgeOfChart:bottomEdgeOfChart leftEdgeOfChart:leftEdgeOfChart totalWidth:totalWidth];
	
	[self drawLeftLabelsAndLinesForContext:c totalMoneyRange:totalMoneyRange min:min leftEdgeOfChart:leftEdgeOfChart totalHeight:totalHeight totalWidth:totalWidth];
	
	[self drawBottomLabelsForArray:months c:c bottomEdgeOfChart:bottomEdgeOfChart leftEdgeOfChart:leftEdgeOfChart totalWidth:totalWidth];
	
	
	[self drawBarChartForContext:c itemArray:itemList leftEdgeOfChart:leftEdgeOfChart mainGoal:mainGoal zeroLoc:zeroLoc yMultiplier:yMultiplier totalWidth:totalWidth];
	
	//Draw goal line
	int goalHeight = zeroLoc-mainGoal*yMultiplier;
	CGContextSetLineWidth(c, 4);
	CGContextSetRGBStrokeColor(c, 0, .8, 1, 1); // black
	if(goalFlg)
		[self drawLine:c startX:leftEdgeOfChart startY:goalHeight endX:totalWidth endY:goalHeight];
	
	UIGraphicsPopContext();
	dynamicChartImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return dynamicChartImage;
	
}

+(NSArray *)namesOfAllWeekdays {
	NSMutableArray *array = [[NSMutableArray alloc] init];
	for (int i=1; i<=7; i++) {
		[array addObject:[ProjectFunctions getWeekDayFromDate:[[NSString stringWithFormat:@"01/%02d/2017", i] convertStringToDateWithFormat:@"MM/dd/yyyy"]]];
	}
	return array;
}



+(UIImage *)graphDaysChart:(NSManagedObjectContext *)mOC yearStr:(NSString *)yearStr chartNum:(int)chartNum goalFlg:(BOOL)goalFlg
{
	int totalWidth=640;
	int totalHeight=300;
	int leftEdgeOfChart=50;
	int bottomEdgeOfChart=totalHeight-25;
	
	int displayYear = [yearStr intValue];
	NSMutableArray *profitList = [[NSMutableArray alloc] init];
	NSString *basicPred = [ProjectFunctions getBasicPredicateString:displayYear type:@"All"];
	NSArray *months = [self namesOfAllWeekdays];
	double min=0;
	double max=0;
	for(NSString *month in months) {
		NSPredicate *predicate = [ProjectFunctions predicateForBasic:basicPred field:@"weekday" value:month];
		double winnings = [[CoreDataLib getGameStat:mOC dataField:@"winnings" predicate:predicate] doubleValue];
		int minutes = [[CoreDataLib getGameStat:mOC dataField:@"minutes" predicate:predicate] intValue];
		int hours = minutes/60;
		int hourlyRate = 0;
		if(hours>0)
			hourlyRate = winnings/hours;
		float amount = (chartNum==1)?winnings:hourlyRate;
		
		if(amount>max)
			max=amount;
		if(amount<min)
			min=amount;
		[profitList addObject:[NSString stringWithFormat:@"%f", amount]];
	}
	max*=1.1;
	double totalMoneyRange = max-min;
	
	float yMultiplier = 1;
	if(totalMoneyRange>0)
		yMultiplier = (float)bottomEdgeOfChart/totalMoneyRange;
	
	
	UIImage *dynamicChartImage = [[UIImage alloc] init];

	CGContextRef c = [self contextRefForGraphofWidth:totalWidth totalHeight:totalHeight];
	
	int zeroLoc = [self drawZeroLineForContext:c min:min max:max bottomEdgeOfChart:bottomEdgeOfChart leftEdgeOfChart:leftEdgeOfChart totalWidth:totalWidth];
	
	[self drawLeftLabelsAndLinesForContext:c totalMoneyRange:totalMoneyRange min:min leftEdgeOfChart:leftEdgeOfChart totalHeight:totalHeight totalWidth:totalWidth];
	
	[self drawBottomLabelsForArray:months c:c bottomEdgeOfChart:bottomEdgeOfChart leftEdgeOfChart:leftEdgeOfChart totalWidth:totalWidth];

	[self drawBarChartForContext:c itemArray:profitList leftEdgeOfChart:leftEdgeOfChart mainGoal:0 zeroLoc:zeroLoc yMultiplier:yMultiplier totalWidth:totalWidth];

	
	UIGraphicsPopContext();
	dynamicChartImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return dynamicChartImage;
	
}

+(UIImage *)graphDaytimeChart:(NSManagedObjectContext *)mOC yearStr:(NSString *)yearStr chartNum:(int)chartNum goalFlg:(BOOL)goalFlg
{
	int totalWidth=640;
	int totalHeight=300;
	int leftEdgeOfChart=50;
	int bottomEdgeOfChart=totalHeight-25;
	
	int displayYear = [yearStr intValue];
	NSMutableArray *profitList = [[NSMutableArray alloc] init];
	NSString *basicPred = [ProjectFunctions getBasicPredicateString:displayYear type:@"All"];
	NSArray *months = [ProjectFunctions namesOfAllDayTimes];
	double min=0;
	double max=0;
	for(NSString *month in months) {
		NSPredicate *predicate = [ProjectFunctions predicateForBasic:basicPred field:@"daytime" value:month];
		double winnings = [[CoreDataLib getGameStat:mOC dataField:@"winnings" predicate:predicate] doubleValue];
		int minutes = [[CoreDataLib getGameStat:mOC dataField:@"minutes" predicate:predicate] intValue];
		int hours = minutes/60;
		int hourlyRate = 0;
		if(hours>0)
			hourlyRate = winnings/hours;

		float amount = (chartNum==1)?winnings:hourlyRate;

		if(amount>max)
			max=amount;
		if(amount<min)
			min=amount;
		
		[profitList addObject:[NSString stringWithFormat:@"%f", amount]];
	}
	max*=1.1;
	double totalMoneyRange = max-min;
	
	float yMultiplier = 1;
	if(totalMoneyRange>0)
		yMultiplier = (float)bottomEdgeOfChart/totalMoneyRange;
	
	UIImage *dynamicChartImage = [[UIImage alloc] init];
	
	CGContextRef c = [self contextRefForGraphofWidth:totalWidth totalHeight:totalHeight];
	
	int zeroLoc = [self drawZeroLineForContext:c min:min max:max bottomEdgeOfChart:bottomEdgeOfChart leftEdgeOfChart:leftEdgeOfChart totalWidth:totalWidth];
	
	[self drawLeftLabelsAndLinesForContext:c totalMoneyRange:totalMoneyRange min:min leftEdgeOfChart:leftEdgeOfChart totalHeight:totalHeight totalWidth:totalWidth];
	
	[self drawBottomLabelsForArray:months c:c bottomEdgeOfChart:bottomEdgeOfChart leftEdgeOfChart:leftEdgeOfChart totalWidth:totalWidth];
	
	[self drawBarChartForContext:c itemArray:profitList leftEdgeOfChart:leftEdgeOfChart mainGoal:0 zeroLoc:zeroLoc yMultiplier:yMultiplier totalWidth:totalWidth];

	
	UIGraphicsPopContext();
	dynamicChartImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return dynamicChartImage;
	
}

+(UIImage *)graphYearlyChart:(NSManagedObjectContext *)mOC yearStr:(NSString *)yearStr chartNum:(int)chartNum goalFlg:(BOOL)goalFlg
{
	
	int totalWidth=640;
	int totalHeight=300;
	int leftEdgeOfChart=50;
	int bottomEdgeOfChart=totalHeight-25;
	
//	int displayYear = [yearStr intValue];
	NSMutableArray *profitList = [[NSMutableArray alloc] init];
	NSString *basicPred = [ProjectFunctions getBasicPredicateString:0 type:@"All"];
	NSMutableArray *months = [[NSMutableArray alloc] init];
	
	NSArray *items = [CoreDataLib selectRowsFromEntity:@"GAME" predicate:nil sortColumn:@"startTime" mOC:mOC ascendingFlg:YES];
	int endYear = [[[NSDate date] convertDateToStringWithFormat:@"yyyy"] intValue];
	int startYear = endYear;
	if([items count]>1) {
		NSManagedObject *mo1 = [items objectAtIndex:0];
		startYear = [[mo1 valueForKey:@"year"] intValue];
	}
    
    if(startYear < endYear-10)
        startYear=endYear-10;

	for(int i=startYear; i<=endYear; i++)
		[months addObject:[NSString stringWithFormat:@"%d", i]];
	
	double min=0;
	double max=0;
	for(NSString *month in months) {
		NSString *predString = [NSString stringWithFormat:@"%@ AND year = %d", basicPred, [month intValue]];
		NSPredicate *predicate = [NSPredicate predicateWithFormat:predString];
		double winnings = [[CoreDataLib getGameStat:mOC dataField:@"winnings" predicate:predicate] doubleValue];
		int minutes = [[CoreDataLib getGameStat:mOC dataField:@"minutes" predicate:predicate] intValue];
		int hours = minutes/60;
		int hourlyRate = 0;
		if(hours>0)
			hourlyRate = winnings/hours;
		if(chartNum==1) {
			if(winnings>max)
				max=winnings;
			if(winnings<min)
				min=winnings;
		}
		if(chartNum==2) {
			if(hourlyRate>max)
				max=hourlyRate;
			if(hourlyRate<min)
				min=hourlyRate;
		}
		float amount = (chartNum==1)?winnings:hourlyRate;
		[profitList addObject:[NSString stringWithFormat:@"%f", amount]];
	}
	max*=1.1;
	double totalMoneyRange = max-min;
	
	float yMultiplier = 1;
	if(totalMoneyRange>0)
		yMultiplier = (float)bottomEdgeOfChart/totalMoneyRange;
	
	
	UIImage *dynamicChartImage = [[UIImage alloc] init];

	CGContextRef c = [self contextRefForGraphofWidth:totalWidth totalHeight:totalHeight];
	
	int zeroLoc = [self drawZeroLineForContext:c min:min max:max bottomEdgeOfChart:bottomEdgeOfChart leftEdgeOfChart:leftEdgeOfChart totalWidth:totalWidth];
	
	[self drawLeftLabelsAndLinesForContext:c totalMoneyRange:totalMoneyRange min:min leftEdgeOfChart:leftEdgeOfChart totalHeight:totalHeight totalWidth:totalWidth];
	
	[self drawBottomLabelsForArray:months c:c bottomEdgeOfChart:bottomEdgeOfChart leftEdgeOfChart:leftEdgeOfChart totalWidth:totalWidth];
	
	[self drawBarChartForContext:c itemArray:profitList leftEdgeOfChart:leftEdgeOfChart mainGoal:0 zeroLoc:zeroLoc yMultiplier:yMultiplier totalWidth:totalWidth];
	UIGraphicsPopContext();
	dynamicChartImage = UIGraphicsGetImageFromCurrentImageContext();
	
	UIGraphicsEndImageContext();
	
	return dynamicChartImage;
	
}


+(NSString *)getGamesTextFromInt:(int)numGames
{
	NSString *gameTxt = (numGames==1)?@"Game":@"Games";
	return [NSString stringWithFormat:@"%d %@", numGames, gameTxt];
}

+(CLLocation *)getCurrentLocation
{
	CLLocation *currentLocation = nil;
//	if ([LocationGetter sharedInstance].currentLocation == nil)
//		return nil;

	[[[LocationGetter sharedInstance] locationManager] startUpdatingLocation];
	
	currentLocation = [LocationGetter sharedInstance].currentLocation;

//	currentLocation = [[[CLLocation alloc] initWithLatitude:47.7590380 longitude:-122.2021071] autorelease];

	return currentLocation;
}

+(NSString *)getLatitudeFromLocation:(CLLocation *)currentLocation decimalPlaces:(int)decimalPlaces
{
	if(currentLocation==nil)
		return @"-";
	NSString *floatStr = [NSString stringWithFormat:@"%%.%df", decimalPlaces];
	return [NSString stringWithFormat:floatStr, currentLocation.coordinate.latitude];
}

+(NSString *)getLongitudeFromLocation:(CLLocation *)currentLocation decimalPlaces:(int)decimalPlaces
{
	if(currentLocation==nil)
		return @"-";
	NSString *floatStr = [NSString stringWithFormat:@"%%.%df", decimalPlaces];
	return [NSString stringWithFormat:floatStr, currentLocation.coordinate.longitude];
}

+(float)getDistanceFromTarget:(float)fromLatitude fromLong:(float)fromLongitude toLat:(float)toLatitude toLong:(float)toLongitude
{
	CLLocation *currentLocation = [[CLLocation alloc] initWithLatitude:fromLatitude longitude:fromLongitude];
	CLLocation *targetLocation = [[CLLocation alloc] initWithLatitude:toLatitude longitude:toLongitude];
	CLLocationDistance distance =[currentLocation distanceFromLocation:targetLocation] * 0.000621371192237334;
    
//    NSLog(@"+++ %.1f %.1f %.1f %.1f %.1f", fromLatitude, fromLongitude, toLatitude, toLongitude, distance);
	return (float)distance; 
}

+(NSString *)getCurrentLocationFromCoreData:(float)fromLatitude long:(float)fromLongitude moc:(NSManagedObjectContext *)managedObjectContext
{
	
	if(fromLatitude==0)	
		return nil;

	NSArray *items = [CoreDataLib selectRowsFromTable:@"LOCATION" mOC:managedObjectContext];
	NSString *thisLoc = nil;
	float distance = 99;
	float minDist = 99;
	for(NSManagedObject *mo in items) {
		NSString *lat = [mo valueForKey:@"latitude"];
		NSString *longitude = [mo valueForKey:@"longitude"];
		if([lat length]>1) {
			distance = [ProjectFunctions getDistanceFromTarget:fromLatitude fromLong:fromLongitude toLat:[lat floatValue] toLong:[longitude floatValue]];

            if(distance<1.8) {
                if(distance<minDist) {
                    minDist=distance;
                    thisLoc = [mo valueForKey:@"name"];
                }
            }

		}
	} // <-- for
	NSLog(@"+++looking for casino on device: %@", thisLoc);
	return thisLoc;
}


+(NSString *)getDefaultLocation:(float)fromLatitude long:(float)fromLongitude moc:(NSManagedObjectContext *)managedObjectContext
{
	if(fromLatitude==0)
		return [ProjectFunctions getUserDefaultValue:@"locationDefault"];
	
	NSString *thisLoc = [ProjectFunctions getCurrentLocationFromCoreData:fromLatitude long:fromLongitude moc:managedObjectContext];

	if(thisLoc==nil)	
		return [ProjectFunctions getUserDefaultValue:@"locationDefault"];
	else
		return thisLoc;
}

+(NSString *)checkLocation1:(CLLocation *)currentLocation moc:(NSManagedObjectContext *)managedObjectContext
{
    NSString *locationName = nil;
	float lat=currentLocation.coordinate.latitude;
	float lng=currentLocation.coordinate.longitude;
	
	BOOL coordsFound = (currentLocation != nil);
	
	if(0) {		//testing
		lat=36.11;
		lng=-115.171;
		coordsFound=YES;
	}
	
	if(coordsFound)
		locationName = [ProjectFunctions getCurrentLocationFromCoreData:lat long:lng moc:managedObjectContext];
    
	if([locationName length]==0 && coordsFound)
		locationName = [ProjectFunctions getDefaultDBLocation:lat lng:lng];
    
    return locationName;
}

+(NSString *)checkLocation2:(CLLocation *)currentLocation moc:(NSManagedObjectContext *)managedObjectContext
{
 	float lat=currentLocation.coordinate.latitude;
	float lng=currentLocation.coordinate.longitude;
   
    NSString *locationName = [WebServicesFunctions getAddressFromGPSLat:lat lng:lng type:1];

	if([locationName length]==0)
		locationName = [ProjectFunctions getUserDefaultValue:@"locationDefault"];
    
    return locationName;
}

+(NSString *)getBestLocation:(CLLocation *)currentLocation MoC:(NSManagedObjectContext *)managedObjectContext
{
    NSString *locationName = [ProjectFunctions checkLocation1:currentLocation moc:managedObjectContext];
    
	if([locationName length]==0)
        locationName = [ProjectFunctions checkLocation2:currentLocation moc:managedObjectContext];
    
	return locationName;
}



+(NSString *)getDefaultDBLocation:(float)currLat lng:(float)currLng
{
	
	NSString *latitude = [NSString stringWithFormat:@"%.6f", currLat];
	NSString *longitutde = [NSString stringWithFormat:@"%.6f", currLng];
	NSArray *nameList = [NSArray arrayWithObjects:@"Username", @"Password", @"lat", @"lng", @"distance", nil];
	
	NSString *userName = @"test@test.com";
	NSString *password = @"test";
	if([[ProjectFunctions getUserDefaultValue:@"userName"] length]>0)
		userName = [ProjectFunctions getUserDefaultValue:@"userName"];
	if([ProjectFunctions getUserDefaultValue:@"password"])
		password = [ProjectFunctions getUserDefaultValue:@"password"];

	NSLog(@"+++Checking Casinos at loc: (%f, %f)", currLat, currLng);

	NSArray *valueList = [NSArray arrayWithObjects:userName, password, latitude, longitutde, @"2", nil];
	NSString *webAddr = @"http://www.appdigity.com/poker/pokerCasinoLookup.php";
	NSString *responseStr = [WebServicesFunctions getResponseFromServerUsingPost:webAddr fieldList:nameList valueList:valueList];
	NSString *thisLoc = nil;
	if([WebServicesFunctions validateStandardResponse:responseStr delegate:nil]) {
		NSArray *casinos = [responseStr componentsSeparatedByString:@"<li>"];
		
		float minDist = .3;
		for(NSString *casino in casinos) {
			NSArray *items = [casino componentsSeparatedByString:@"|"];
			if(items.count>7) {
				NSString *name = [items stringAtIndex:1];
				NSString *lat = [items stringAtIndex:6];
				NSString *lng = [items stringAtIndex:7];
				if(lat.length>0) {
					float distance = [ProjectFunctions getDistanceFromTarget:currLat fromLong:currLng toLat:[lat floatValue] toLong:[lng floatValue]];
					if(distance <= minDist) {
						NSLog(@"--------> Winner! %f: %@ (%f, %f)", distance, name, lat.floatValue, lng.floatValue);
						minDist = distance;
						thisLoc = name;
					} else
						NSLog(@"no good! dist: %f: %@ (%f, %f)", distance, name, lat.floatValue, lng.floatValue);
				}
			}
		} // <-- for
	}
		
	return thisLoc;
	
	
}




+(NSDate *)getDateInCorrectFormat:(NSString *)istartTime {
	NSDate *ist = [istartTime convertStringToDateWithFormat:@"pokerJounral"];
    
	if(ist==nil)
		ist = [istartTime convertStringToDateWithFormat:@"pokerJounral2"];
	if(ist==nil)
		ist = [istartTime convertStringToDateWithFormat:nil];
	if(ist==nil)
		ist = [istartTime convertStringToDateWithFormat:@"MM/dd/yy hh:mm a"];
	if(ist==nil)
		ist = [istartTime convertStringToDateWithFormat:@"MM/dd/yyyy hh:mm:ss a"];
	if(ist==nil)
		ist = [istartTime convertStringToDateWithFormat:@"MM/dd/yy HH:mm"];
	if(ist==nil)
		ist = [istartTime convertStringToDateWithFormat:@"MM/dd/yy hh:mm:ss a"];
	if(ist==nil)
		ist = [istartTime convertStringToDateWithFormat:@"MM/dd/yy hh:mm a"];

    if(ist==nil)
        ist=[istartTime convertStringToDateFinalSolution];
    
	
	return ist;
}

+ (UIImage *)imageWithImage:(UIImage *)image newSize:(CGSize)newSize {
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();    
    UIGraphicsEndImageContext();
    return newImage;
}

+(NSString *)getPicPath:(int)user_id
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *docDir = [paths stringAtIndex:0];
	return [docDir stringByAppendingPathComponent:[NSString stringWithFormat:@"player%d.jpg", user_id]];
}

+(NSArray *)getStateArray
{
	return [NSArray arrayWithObjects:@"AK", @"AL", @"AR", @"AZ", @"CA", @"CO", @"CT", @"DE", @"FL", @"GA",
			@"HI", @"IA", @"ID", @"IL", @"IN", @"KS", @"KY", @"LA", @"MA", @"MD", @"ME",
			@"MI", @"MN", @"MO", @"MS", @"MT", @"NC", @"ND", @"NE", @"NH", @"NJ", @"NM",
			@"NV", @"NY", @"OH", @"OK", @"OR", @"PA", @"RI", @"SC", @"SD", @"TN", @"TX",
			@"UT", @"VA", @"VT", @"WA", @"WI", @"WV", @"WY",
			nil];
}

+(NSArray *)getCountryArray
{
	return [NSArray arrayWithObjects:@"Afghanistan",
							 @"Albania",
							 @"Algeria",
							 @"Andorra",
							 @"Angola",
							 @"Antigua and Barbuda",
							 @"Argentina",
							 @"Armenia",
							 @"Australia",
							 @"Austria",
							 @"Azerbaijan",
							 @"Bahamas, The",
							 @"Bahrain",
							 @"Bangladesh",
							 @"Barbados",
							 @"Belarus",
							 @"Belgium",
							 @"Belize",
							 @"Benin",
							 @"Bhutan",
							 @"Bolivia",
							 @"Bosnia and Herzegovina",
							 @"Botswana",
							 @"Brazil",
							 @"Brunei",
							 @"Bulgaria",
							 @"Burkina Faso",
							 @"Burma",
							 @"Burundi",
							 @"Cambodia",
							 @"Cameroon",
							 @"Canada",
							 @"Cape Verde",
							 @"Central African Republic",
							 @"Chad",
							 @"Chile",
							 @"China",
							 @"Colombia",
							 @"Comoros",
							 @"Congo, Democratic Republic of the",
							 @"Congo, Republic of the",
							 @"Costa Rica",
							 @"Cote d'Ivoire",
							 @"Croatia",
							 @"Cuba",
							 @"Cyprus",
							 @"Czech Republic",
							 @"Denmark",
							 @"Djibouti",
							 @"Dominica",
							 @"Dominican Republic",
							 @"East Timor",
							 @"Ecuador",
							 @"Egypt",
							 @"El Salvador",
							 @"Equatorial Guinea",
							 @"Eritrea",
							 @"Estonia",
							 @"Ethiopia",
							 @"Fiji",
							 @"Finland",
							 @"France",
							 @"Gabon",
							 @"Gambia, The",
							 @"Georgia",
							 @"Germany",
							 @"Ghana",
							 @"Greece",
							 @"Grenada",
							 @"Guatemala",
							 @"Guinea",
							 @"Guinea-Bissau",
							 @"Guyana",
							 @"Haiti",
							 @"Holy See",
							 @"Honduras",
							 @"Hong Kong",
							 @"Hungary",
							 @"Iceland",
							 @"India",
							 @"Indonesia",
							 @"Iran",
							 @"Iraq",
							 @"Ireland",
							 @"Israel",
							 @"Italy",
							 @"Jamaica",
							 @"Japan",
							 @"Jordan",
							 @"Kazakhstan",
							 @"Kenya",
							 @"Kiribati",
							 @"Kosovo",
							 @"Kuwait",
							 @"Kyrgyzstan",
							 @"Laos",
							 @"Latvia",
							 @"Lebanon",
							 @"Lesotho",
							 @"Liberia",
							 @"Libya",
							 @"Liechtenstein",
							 @"Lithuania",
							 @"Luxembourg",
							 @"Macau",
							 @"Macedonia",
							 @"Madagascar",
							 @"Malawi",
							 @"Malaysia",
							 @"Maldives",
							 @"Mali",
							 @"Malta",
							 @"Marshall Islands",
							 @"Mauritania",
							 @"Mauritius",
							 @"Mexico",
							 @"Micronesia",
							 @"Moldova",
							 @"Monaco",
							 @"Mongolia",
							 @"Montenegro",
							 @"Morocco",
							 @"Namibia",
							 @"Nauru",
							 @"Nepal",
							 @"Netherlands",
							 @"Netherlands Antilles",
							 @"New Zealand",
							 @"Nicaragua",
							 @"Niger",
							 @"Nigeria",
							 @"North Korea",
							 @"Norway",
							 @"Oman",
							 @"Pakistan",
							 @"Palau",
							 @"Palestinian Territories",
							 @"Panama",
							 @"Papua New Guinea",
							 @"Paraguay",
							 @"Peru",
							 @"Philippines",
							 @"Poland",
							 @"Portugal",
							 @"Qatar",
							 @"Romania",
							 @"Russia",
							 @"Rwanda",
							 @"Saint Kitts and Nevis",
							 @"Saint Lucia",
							 @"Saint Vincent and the Grenadines",
							 @"Samoa",
							 @"San Marino",
							 @"Sao Tome and Principe",
							 @"Saudi Arabia",
							 @"Senegal",
							 @"Serbia",
							 @"Seychelles",
							 @"Sierra Leone",
							 @"Singapore",
							 @"Slovakia",
							 @"Slovenia",
							 @"Solomon Islands",
							 @"Somalia",
							 @"South Africa",
							 @"South Korea",
							 @"South Sudan",
							 @"Spain",
							 @"Sri Lanka",
							 @"Sudan",
							 @"Suriname",
							 @"Swaziland",
							 @"Sweden",
							 @"Switzerland",
							 @"Syria",
							 @"Taiwan",
							 @"Tajikistan",
							 @"Tanzania",
							 @"Thailand",
							 @"Timor-Leste",
							 @"Togo",
							 @"Tonga",
							 @"Trinidad and Tobago",
							 @"Tunisia",
							 @"Turkey",
							 @"Turkmenistan",
							 @"Tuvalu",
							 @"Uganda",
							 @"Ukraine",
							 @"United Arab Emirates",
							 @"United Kingdom",
							 @"Uruguay",
							 @"USA",
							 @"Uzbekistan",
							 @"Vanuatu",
							 @"Venezuela",
							 @"Vietnam",
							 @"Yemen",
							 @"Zambia",
							 @"Zimbabwe",
							 nil];
}	

+ (NSString *)formatTelNumberForCalling:(NSString *)phoneNumber
{
	phoneNumber = [NSString removeTelephoneFormatting:phoneNumber];
	int len = (int)[phoneNumber length];
	
	if (len>=11 && [[phoneNumber substringWithRange:NSMakeRange(0, 1)] isEqualToString:@"1"]) {
		phoneNumber = [phoneNumber substringWithRange:NSMakeRange(1, len-1)];
		len--;
	}
	
	if(len<=10)
		return phoneNumber;
	
	return [NSString stringWithFormat:@"%@p%@",
			[phoneNumber substringWithRange:NSMakeRange(0, 10)],
			[phoneNumber substringWithRange:NSMakeRange(10, len-10)]];	
}	

+(NSString *)formatFieldForWebService:(NSString *)field
{
	field = [field stringByReplacingOccurrencesOfString:@"|" withString:@""];
	field = [field stringByReplacingOccurrencesOfString:@"&" withString:@"[amp]"];
	field = [field stringByReplacingOccurrencesOfString:@"<li>" withString:@""];
	field = [field stringByReplacingOccurrencesOfString:@"<hr>" withString:@""];
	field = [field stringByReplacingOccurrencesOfString:@"\n" withString:@"[nl]"];
	return field;
}

+(void)updateMoneyFloatLabel:(UILabel *)localLabel money:(float)money
{
	localLabel.text = [ProjectFunctions convertNumberToMoneyString:money];
	if(money<0)
		localLabel.textColor = [UIColor orangeColor];
	else 
		localLabel.textColor = [UIColor greenColor];
}

+(void)updateMoneyLabel:(UILabel *)localLabel money:(double)money
{
    [localLabel performSelectorOnMainThread:@selector(setText: ) withObject:[ProjectFunctions convertIntToMoneyString:money] waitUntilDone:NO];
    
	if(money<0)
        [localLabel performSelectorOnMainThread:@selector(setTextColor: ) withObject:[UIColor orangeColor] waitUntilDone:NO];
	else
        [localLabel performSelectorOnMainThread:@selector(setTextColor: ) withObject:[UIColor greenColor] waitUntilDone:NO];
    
}

+(int)getPlayerType:(double)amountRisked winnings:(double)winnings
{
	int amountReturned = amountRisked+winnings;
	int percent=100;
	if(amountRisked>0)
		percent = amountReturned*100/amountRisked;
	
	if(percent<50)
		return 0;
	if(percent>=50 && percent<100)
		return 1;
	if(percent>=100 && percent<125)
		return 2;
	if(percent>=125 && percent<150)
		return 3;
	
	return 4;
}

+(NSString *)getPlayerTypelabel:(double)amountRisked winnings:(double)winnings
{
	int value = [ProjectFunctions getNewPlayerType:amountRisked winnings:winnings];
	NSArray *types = [NSArray arrayWithObjects:@"Donkey", @"Fish", @"Rounder", @"Grinder", @"Shark", @"Pro", nil];
	return [types stringAtIndex:value];
}


+(int)getNewPlayerType:(double)amountRisked winnings:(double)winnings
{
	double amountReturned = amountRisked+winnings;
	int percent=100;
	if(amountRisked>0)
		percent = amountReturned*100/amountRisked;
	if(percent<35)
		return 0;
	if(percent>=35 && percent<75)
		return 1;
	if(percent>=75 && percent<=100)
		return 2;
	if(percent>=100 && percent<125)
		return 3;
	if(percent>=125 && percent<150)
		return 4;
	
	return 5;
}

+(UIImage *)playerImageOfType:(int)type {
	int iconGroupNumber = [[ProjectFunctions getUserDefaultValue:@"IconGroupNumber"] intValue];
	return [self ptpPlayerImageOfType:type iconGroupNumber:iconGroupNumber];
}

+(UIImage *)ptpPlayerImageOfType:(int)type iconGroupNumber:(int)iconGroupNumber {
	NSString *letter = @"";
	if(iconGroupNumber==1)
		letter=@"b";
	if(iconGroupNumber==2)
		letter=@"c";
	if(iconGroupNumber==3)
		letter=@"d";
	return [UIImage imageNamed:[NSString stringWithFormat:@"playerType%d%@.png", type, letter]];
}

+(UIImage *)getPtpPlayerTypeImage:(double)amountRisked winnings:(double)winnings iconGroupNumber:(int)iconGroupNumber {
	if(winnings==0)
		return [UIImage imageNamed:@"Icon-152.png"];
	int type = [ProjectFunctions getNewPlayerType:amountRisked winnings:winnings];
	return [self ptpPlayerImageOfType:type iconGroupNumber:iconGroupNumber];
}

+(UIImage *)getPlayerTypeImage:(double)amountRisked winnings:(double)winnings
{
    if(winnings==0)
        return [UIImage imageNamed:@"Icon-152.png"];
	int value = [ProjectFunctions getNewPlayerType:amountRisked winnings:winnings];
	return [self playerImageOfType:value];
}

+(void)setFontColorForSegment:(UISegmentedControl *)segment values:(NSArray *)values
{
	return;
	if(values==nil)
		values = [NSArray arrayWithObjects:@"All", @"Cash Games", @"Tournaments", nil];
	for (id seg in [segment subviews]) {
		for (id label in [seg subviews])
			if([label isKindOfClass:[UILabel class]]) {
				UILabel *temp = label;
				if(![temp.text isEqualToString:[values stringAtIndex:segment.selectedSegmentIndex]]) {
					[label setTextColor:[UIColor colorWithRed:.9 green:.9 blue:.9 alpha:1]];
					[label setShadowColor:[UIColor blackColor]];
					[label setShadowOffset:CGSizeMake(1.0, 1.0)];
				} else {
					[label setTextColor:[UIColor whiteColor]];
					[label setShadowColor:[UIColor blackColor]];
					[label setShadowOffset:CGSizeMake(2.0, 2.0)];
				}
			}
		
	}
}

+ (UIView *)getViewForHeaderWithText:(NSString *)headerText
{
	UIView* customView = [[UIView alloc] initWithFrame:CGRectMake(0, 0.0, 320.0, 22.0)];
	UILabel * headerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	headerLabel.backgroundColor = [UIColor clearColor];
	headerLabel.opaque = NO;
	headerLabel.textColor = [UIColor whiteColor];
	headerLabel.highlightedTextColor = [UIColor whiteColor];
	headerLabel.font = [UIFont boldSystemFontOfSize:14];
	headerLabel.numberOfLines = 0;
	headerLabel.frame = CGRectMake(10.0, 0.0, 300.0, 22.0);
	headerLabel.text = headerText;
	customView.backgroundColor	= [ProjectFunctions segmentThemeColor];
	[customView addSubview:headerLabel];
	return customView;
}

+(NSString *)convertImgToBase64String:(UIImage *)img height:(int)height
{
	NSData *data = UIImageJPEGRepresentation(img, 1.0);
	return [ProjectFunctions convertDataToBase64String:data height:height];
}

+(NSString *)convertDataToBase64String:(NSData *)data height:(int)height
{
	UIImage *img = [UIImage imageWithData:data];
	CGSize newSize;
	newSize.height=height;
	newSize.width=height;
	
	UIImage *newImg = [ProjectFunctions imageWithImage:img newSize:newSize];
	NSData *imgData = UIImageJPEGRepresentation(newImg, 1.0);
	return [NSString base64StringFromData:imgData length:(int)[imgData length]];
}

+(NSData *)convertBase64StringToData:(NSString *)imgString
{
	NSData *imgData = [NSData base64DataFromString:imgString];
	return imgData;
}

+(UIImage *)convertBase64StringToImage:(NSString *)imgString
{
	NSData *imgData = [ProjectFunctions convertBase64StringToData:imgString];
	UIImage *img = [UIImage imageWithData:imgData];
	return img;
}


+(NSString *)displayLocalFormatDate:(NSDate *)date showDay:(BOOL)showDay showTime:(BOOL)showTime {
	NSDateFormatter* df = [[NSDateFormatter alloc] init];
	if (showDay)
		[df setDateStyle:NSDateFormatterMediumStyle];
	if (showTime)
		[df setTimeStyle:NSDateFormatterShortStyle];
	return [df stringFromDate:date];
}

+(NSString *)getMoneySymbol2 {
	NSNumberFormatter *currencyFormatter = [[NSNumberFormatter alloc] init];
	[currencyFormatter setLocale:[NSLocale currentLocale]];
	[currencyFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
	
	return [currencyFormatter currencySymbol];
}


+(NSString *)getMoneySymbol
{
	return [self getMoneySymbol2];
//	NSString *moneySymbol = [ProjectFunctions getUserDefaultValue:@"moneySymbol"];
//	if([moneySymbol length]==0)
//		return @"$";
//	else
//		return moneySymbol;
}

+(NSArray *)moneySymbols
{
	return [NSArray arrayWithObjects:
					   @"$", @"£", @"€", @"¥", @"฿", @"Br", 
					   @"₵", @"₡", @"ден", @"₫", @"ƒ", 
					   @"Ft", @"₲", @"Kč", @"₭", @"L", 
					   @"₤", @"₥", @"₦", @"₱", @"P", 
					   @"R", @"RM", @"RSD", @"₨", @"৳", 
					   @"₮", @"₩", @"¥", @"zł", @"₴", 
					   @"Q", @"₪", @"TL", nil];
}

+(void)createChipTimeStamp:(NSManagedObjectContext *)managedObjectContext mo:(NSManagedObject *)mo timeStamp:(NSDate *)timeStamp amount:(double)amount rebuyFlg:(BOOL)rebuyFlg
{
	if(timeStamp==nil)
		timeStamp=[NSDate date];

//    if(amount>32000)
  //      amount=32000; // temp code needed until field size is larger
    
	NSArray *a1 = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%f", amount], [timeStamp convertDateToStringWithFormat:nil], nil];
	
	NSManagedObject *m1 = [CoreDataLib insertManagedObjectForEntity:@"CHIPSTACK" valueList:a1 mOC:managedObjectContext];
	
	[m1 setValue:mo forKey:@"game"];
	
	if(rebuyFlg)
		[m1 setValue:[NSNumber numberWithInt:1] forKey:@"rebuyFlg"];

	[managedObjectContext save:nil];
	
}

+(void)showActionSheet:(id)delegate view:(UIView *)view title:(NSString *)title buttons:(NSArray *)buttons
{
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:title delegate:delegate cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
	for(NSString *buttonName in buttons)
		[actionSheet addButtonWithTitle:buttonName];
	[actionSheet addButtonWithTitle:@"Cancel"];
	[actionSheet showInView:view];
	
	//-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
}

+(NSString *)numberWithSuffix:(int)number
{
	NSString *text = [NSString stringWithFormat:@"%d", number];
	if([text length]>1) {
		int lastDigits = [[text substringWithRange:NSMakeRange([text length]-2, 2)] intValue];
		if(lastDigits==11 || lastDigits==12 || lastDigits==13) 
			return [NSString stringWithFormat:@"%dth", number];
	}
	int lastDigit = [[text substringWithRange:NSMakeRange([text length]-1, 1)] intValue];
	if(lastDigit==1)
		return [NSString stringWithFormat:@"%dst", number];
	if(lastDigit==2)
		return [NSString stringWithFormat:@"%dnd", number];
	if(lastDigit==3)
		return [NSString stringWithFormat:@"%drd", number];
	
	return [NSString stringWithFormat:@"%dth", number];
}

+(int)synvLiveUpdateInfo:(NSManagedObjectContext *)MoC
{
	NSLog(@"Sync Live Update");
	NSString *data = @"N";
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"user_id = 0 AND status = %@", @"In Progress"];
	NSArray *items = [CoreDataLib selectRowsFromEntity:@"GAME" predicate:predicate sortColumn:@"name" mOC:MoC ascendingFlg:YES];
	if([items count]>0) {
		NSManagedObject *mo = [items objectAtIndex:0];
		data = [NSString stringWithFormat:@"Y|%@|%@|%@|%@|%@", 
				[mo valueForKey:@"location"], 
				[mo valueForKey:@"cashoutAmount"], 
				[[mo valueForKey:@"startTime"] convertDateToStringWithFormat:nil],
				[mo valueForKey:@"buyInAmount"],
				[mo valueForKey:@"rebuyAmount"]];
	} else {
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"user_id = %d", 0];
		NSArray *items = [CoreDataLib selectRowsFromEntity:@"GAME" predicate:predicate sortColumn:@"startTime" mOC:MoC ascendingFlg:NO];
		if([items count]>0) {
			NSManagedObject *mo = [items objectAtIndex:0];
			data = [NSString stringWithFormat:@"N|%@|%@|%@|%@|%@", 
					[mo valueForKey:@"location"], 
					[mo valueForKey:@"cashoutAmount"], 
					[[mo valueForKey:@"startTime"] convertDateToStringWithFormat:nil],
					[mo valueForKey:@"buyInAmount"],
					[mo valueForKey:@"rebuyAmount"]];
		}
	}

	NSArray *nameList = [NSArray arrayWithObjects:@"Username", @"Password", @"data", nil];
	NSString *userName = @"x";
	NSString *password = @"x";
	if([ProjectFunctions getUserDefaultValue:@"userName"])
		userName = [ProjectFunctions getUserDefaultValue:@"userName"];
	if([ProjectFunctions getUserDefaultValue:@"password"])
		password = [ProjectFunctions getUserDefaultValue:@"password"];

	NSArray *valueList = [NSArray arrayWithObjects:userName, password, data, nil];
	NSString *webAddr = @"http://www.appdigity.com/poker/pokerLiveUpdate.php";
	NSString *responseStr = [WebServicesFunctions getResponseFromServerUsingPost:webAddr fieldList:nameList valueList:valueList];
	int count = [ProjectFunctions updateFriendData:responseStr MoC:MoC];
	return count;
}

+(int)updateFriendData:(NSString *)responseStr MoC:(NSManagedObjectContext *)MoC
{
	NSArray *friends = [responseStr componentsSeparatedByString:@"<br>"];
	int count=0;
	int chips=0;
	for(NSString *friend in friends) {
		NSArray *components = [friend componentsSeparatedByString:@"|"];
		if([components count]>5) {
			int friendId = [[components stringAtIndex:0] intValue];
			if([[components stringAtIndex:1] isEqualToString:@"Y"])
				count++;
			
			NSPredicate *predicate = [NSPredicate predicateWithFormat:@"user_id = %d", friendId];
			NSArray *friendObj = [CoreDataLib selectRowsFromEntity:@"FRIEND" predicate:predicate sortColumn:nil mOC:MoC ascendingFlg:YES];
			if([friendObj count]>0) {
				chips += [[components stringAtIndex:3] intValue];
				NSString *line = [NSString stringWithFormat:@"%@|%@|%@|%@|%@", [components stringAtIndex:2], [components stringAtIndex:3], [components stringAtIndex:5], [components stringAtIndex:6], [components stringAtIndex:7]];
				[friendObj setValue:[components stringAtIndex:1] forKey:@"attrib_08"];
				[friendObj setValue:[components stringAtIndex:4] forKey:@"attrib_09"];
				if([line length]<50)
					[friendObj setValue:line forKey:@"attrib_10"];
				[MoC save:nil];
			}
		}
	}
	[ProjectFunctions setUserDefaultValue:[NSString stringWithFormat:@"%d", chips] forKey:@"FriendChips"];
	return count;
}

+(void)doLiveUpdate:(NSManagedObjectContext *)MoC
{
	@autoreleasepool {
		NSArray *items = [CoreDataLib selectRowsFromEntity:@"FRIEND" predicate:nil sortColumn:nil mOC:MoC ascendingFlg:YES];
		
		if([items count]>0)
			[ProjectFunctions synvLiveUpdateInfo:MoC];
	
	
	}
}

+(NSString *)displayMoney:(NSManagedObject *)mo column:(NSString *)column
{
	return [ProjectFunctions convertNumberToMoneyString:[[mo valueForKey:column] floatValue]];
}

+(NSString *)convertTextToMoneyString:(NSString *)amount
{
	return [ProjectFunctions convertNumberToMoneyString:[amount floatValue]];
}

+(BOOL)shouldSyncGameResultsWithServer:(NSManagedObjectContext *)moc
{
	if([[ProjectFunctions getUserDefaultValue:@"userName"] length]==0)
		return NO;
	
	if([[ProjectFunctions getUserDefaultValue:@"autoSyncValue"] isEqualToString:@"off"])
		return NO;
	
	return YES;
}

+(int)generateUniqueId
{
	int UniqueId = [[ProjectFunctions getUserDefaultValue:@"UniqueId"] intValue];
	UniqueId++;
	[ProjectFunctions setUserDefaultValue:[NSString stringWithFormat:@"%d", UniqueId] forKey:@"UniqueId"];
	return UniqueId;
}

+(void)updateBankroll:(int)winnings bankrollName:(NSString *)bankrollName MOC:(NSManagedObjectContext *)MOC;
{
 	int bankrollAmount = [[ProjectFunctions getUserDefaultValue:@"defaultBankroll"] intValue];
	bankrollAmount += winnings;
	NSLog(@"bankrollAmount: %d %d [%@]", bankrollAmount, winnings, bankrollName);
	[ProjectFunctions setUserDefaultValue:[NSString stringWithFormat:@"%d", bankrollAmount] forKey:@"defaultBankroll"];
 
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"type = 'bankroll' AND name = %@", bankrollName];
    NSArray *items = [CoreDataLib selectRowsFromEntity:@"EXTRA2" predicate:predicate sortColumn:nil mOC:MOC ascendingFlg:NO];
    if([items count]>0) {
        NSManagedObject *mo = [items objectAtIndex:0];
        [mo setValue:[NSNumber numberWithInt:bankrollAmount] forKey:@"attrib_01"];
    }

}


-(void) setReturningValue:(NSString *)value
{
    // This function needed to avoid warning messages
}

+(int)getMinutesPlayedUsingStartTime:(NSDate *)startTime andEndTime:(NSDate *)endTime andBreakMin:(int)breakMinutes
{
	int minutesPlayed = [endTime timeIntervalSinceDate:startTime]/60;
    return minutesPlayed-breakMinutes;
}

+(NSString *)getHoursPlayedUsingStartTime:(NSDate *)startTime andEndTime:(NSDate *)endTime andBreakMin:(int)breakMinutes
{
    int minutesPlayed = [self getMinutesPlayedUsingStartTime:startTime andEndTime:endTime andBreakMin:breakMinutes];
    return [NSString stringWithFormat:@"%.1f hours", (float)minutesPlayed/60];
}

+(int)calculatePprAmountRisked:(double)amountRisked netIncome:(double)netIncome {
    int ppr=100;
    if(amountRisked>0)
        ppr=100*(netIncome+amountRisked)/amountRisked;
    ppr -=100;
    return ppr;
}

+(void)setBankSegment:(UISegmentedControl *)segment
{
    NSString *bankrollDefault = [ProjectFunctions getUserDefaultValue:@"bankrollDefault"];
    if(![@"ALL" isEqualToString:bankrollDefault])
        [segment setTitle:[NSString stringWithFormat:@"%@", bankrollDefault] forSegmentAtIndex:0];
    
    NSString *limitBankRollGames = [ProjectFunctions getUserDefaultValue:@"limitBankRollGames"];
    if([@"YES" isEqualToString:limitBankRollGames])
        segment.selectedSegmentIndex=0;
    else
        segment.selectedSegmentIndex=1;
    
}

+(void)bankSegmentChangedTo:(int)number
{
    if(number==1)
        [ProjectFunctions setUserDefaultValue:@"" forKey:@"limitBankRollGames"];
    else
        [ProjectFunctions setUserDefaultValue:@"YES" forKey:@"limitBankRollGames"];
}

+(void)checkBankrollsForSegment:(UISegmentedControl *)segment moc:(NSManagedObjectContext *)moc
{
    NSPredicate *predicateBank = [NSPredicate predicateWithFormat:@"bankroll <> %@ ", @"Default"];
    NSArray *gamesBank = [CoreDataLib selectRowsFromEntity:@"GAME" predicate:predicateBank sortColumn:@"" mOC:moc ascendingFlg:YES];
    int numBanks = (int)[gamesBank count];
    int oldNumBanks = [[ProjectFunctions getUserDefaultValue:@"numBanks"] intValue];
    if(numBanks != oldNumBanks)
        [ProjectFunctions setUserDefaultValue:[NSString stringWithFormat:@"%d", numBanks] forKey:@"numBanks"];
    
    if(numBanks==0)
        segment.alpha=0;
}

+(void)addColorToButton:(UIButton *)button color:(UIColor *)color {
	CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha =0.0;
	[color getRed:&red green:&green blue:&blue alpha:&alpha];
	
	float colorAmount = red+green+blue;
	
	[button setBackgroundImage:[ProjectFunctions imageFromColor:color]
					  forState:UIControlStateNormal];
	
	if (colorAmount > 1.5)
		[button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
	else
		[button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	
	button.layer.borderColor = [UIColor blackColor].CGColor;
	
	button.layer.masksToBounds = YES;
	button.layer.borderWidth = 1.0f;
    button.layer.cornerRadius = 8.0f;
}

+ (UIImage *) imageFromColor:(UIColor *)color {
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

+(UIBarButtonItem *)navigationButtonWithTitle:(NSString *)title selector:(SEL)selector target:(id)target
{
	if([title isEqualToString:NSLocalizedString(@"Main Menu", nil)])
		return [ProjectFunctions UIBarButtonItemWithIcon:[NSString fontAwesomeIconStringForEnum:FAHome] target:target action:selector];
	
	return [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStylePlain target:target action:selector];

}

+(BOOL)applyBGToNavBar:(UINavigationBar *)navigationBar image:(UIImage *)image {
	if ([navigationBar respondsToSelector:@selector(setBackgroundImage:forBarMetrics:)]) {
		[navigationBar setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
		return YES;
	} else {
		return NO;
	}
}

+(void)tintNavigationBar:(UINavigationBar *)navigationBar {
	[navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName,nil]];
	if([ProjectFunctions getProductionMode]) {
		navigationBar.tintColor = [ProjectFunctions primaryButtonColor]; // button colors
		
		UIImage *navBgImage=nil;
		if([ProjectFunctions appThemeNumber] != 1) {
			if([ProjectFunctions segmentColorNumber]==0 && [ProjectFunctions themeTypeNumber]==0)
				navBgImage = [UIImage imageNamed:@"greenGradient.png"];
			else
				navBgImage = [self gradientImageNavbarOfWidth:navigationBar.frame.size.width];
		}
		
		[self applyBGToNavBar:navigationBar image:navBgImage];
		
		if ([navigationBar respondsToSelector:@selector(setBarTintColor:)]) {
			[navigationBar setBarTintColor:[ProjectFunctions segmentThemeColor]];
		} else {
			navigationBar.opaque=YES;
			navigationBar.backgroundColor = [ProjectFunctions segmentThemeColor];
		}
	} else { // test mode
		[navigationBar setBackgroundImage:[UIImage imageNamed:@"gradPink.png"] forBarMetrics:UIBarMetricsDefault];
		navigationBar.tintColor = [UIColor whiteColor]; // button colors
	}
}

+(void)addGradientToView:(UIView *)view {
	float width = view.frame.size.width;
	float height = view.frame.size.height;
	if(width==0) {
		width = 320;
		height = 44;
	}
	UIColor *colorTop = [ProjectFunctions primaryButtonColor];
	UIColor *colorBottom = [UIColor whiteColor];
	UIView *imageView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
	CAGradientLayer *gradient = [CAGradientLayer layer];
	gradient.frame = imageView.bounds;
	gradient.colors = [NSArray arrayWithObjects:(id)colorTop.CGColor, colorBottom.CGColor, colorBottom.CGColor, nil];
	[imageView.layer insertSublayer:gradient atIndex:0];
	UIImage *image = [self imageFromUIView:imageView];
	view.backgroundColor = [UIColor colorWithPatternImage:image];
}

+(UIColor *)gradientBGColorForWidth:(float)width height:(float)height {
	UIColor *colorTop = [ProjectFunctions primaryButtonColor];
	UIColor *colorBottom = [UIColor whiteColor];
	UIView *imageView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
	CAGradientLayer *gradient = [CAGradientLayer layer];
	gradient.frame = imageView.bounds;
	gradient.colors = [NSArray arrayWithObjects:(id)colorTop.CGColor, colorBottom.CGColor, colorBottom.CGColor, nil];
	[imageView.layer insertSublayer:gradient atIndex:0];
	UIImage *image = [self imageFromUIView:imageView];
	return [UIColor colorWithPatternImage:image];
}

+(UIImage *)gradientImageNavbarOfWidth:(float)width {
	UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 44)];
	CAGradientLayer *gradient = [CAGradientLayer layer];
	gradient.frame = view.bounds;
	gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor blackColor] CGColor], [ProjectFunctions segmentThemeColor].CGColor, [ProjectFunctions segmentThemeColor].CGColor, nil];
	[view.layer insertSublayer:gradient atIndex:0];
	return [self imageFromUIView:view];
}

+ (UIImage *) imageFromUIView:(UIView*)view
{
	UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, 0.0);
	[view.layer renderInContext:UIGraphicsGetCurrentContext()];
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return image;
}

+(int)updateGamesOnDevice:(NSManagedObjectContext *)context {
	NSArray *allGames = [CoreDataLib selectRowsFromEntity:@"GAME" predicate:nil sortColumn:nil mOC:context ascendingFlg:YES];
	NSLog(@"+++gamesOnDevice: %d", (int)allGames.count);
	[ProjectFunctions findMinAndMaxYear:context];
	[ProjectFunctions setUserDefaultValue:[NSString stringWithFormat:@"%d", (int)allGames.count] forKey:@"gamesOnDevice"];
	return (int)allGames.count;
}

+(void)updateGamesOnServer:(NSManagedObjectContext *)context {
	NSArray *allGames = [CoreDataLib selectRowsFromEntity:@"GAME" predicate:nil sortColumn:nil mOC:context ascendingFlg:YES];
	NSLog(@"+++gamesOnServer: %d", (int)allGames.count);
	[ProjectFunctions setUserDefaultValue:[NSString stringWithFormat:@"%d", (int)allGames.count] forKey:@"gamesOnServer"];
}

+(void)makeSegment:(UISegmentedControl *)segment color:(UIColor *)color {
	[self makeSegment:segment color:color size:12];
}

+(void)makeSegment:(UISegmentedControl *)segment color:(UIColor *)color size:(float)size {
	[segment setTintColor:color];
	
	segment.layer.backgroundColor = [UIColor colorWithRed:.9 green:.9 blue:.9 alpha:1].CGColor;
	segment.layer.cornerRadius = 7;
	
	UIFont *font = [UIFont fontWithName:kFontAwesomeFamilyName size:size];
	NSMutableDictionary *attribsNormal;
	attribsNormal = [NSMutableDictionary dictionaryWithObjectsAndKeys:font, UITextAttributeFont, [UIColor blackColor], UITextAttributeTextColor, nil];
	
	NSMutableDictionary *attribsSelected;
	attribsSelected = [NSMutableDictionary dictionaryWithObjectsAndKeys:font, UITextAttributeFont, [UIColor whiteColor], UITextAttributeTextColor, nil];
	
	[segment setTitleTextAttributes:attribsNormal forState:UIControlStateNormal];
	[segment setTitleTextAttributes:attribsSelected forState:UIControlStateSelected];
	
}

+(void)makeFALabel:(UILabel *)label type:(int)type size:(float)size {
	label.font = [UIFont fontWithName:kFontAwesomeFamilyName size:size];
	label.text = [self faStringOfType:type];
}

+(void)makeFAButton:(UIButton *)button type:(int)type size:(float)size {
	button.titleLabel.font = [UIFont fontWithName:kFontAwesomeFamilyName size:size];
	[button setTitle:[self faStringOfType:type] forState:UIControlStateNormal];
}

+(void)makeFAButton2:(UIButton *)button type:(int)type size:(float)size {
	button.titleLabel.font = [UIFont fontWithName:kFontAwesomeFamilyName size:size];
	[button setTitle:[self faStringOfType:type] forState:UIControlStateNormal];
	if(type==0)
		[ProjectFunctions newButtonLook:button mode:3];
	else
		[ProjectFunctions newButtonLook:button mode:0];
}

+(void)makeFAButton:(UIButton *)button type:(int)type size:(float)size text:(NSString *)text {
	button.titleLabel.font = [UIFont fontWithName:kFontAwesomeFamilyName size:size];
	[button setTitle:[NSString stringWithFormat:@"%@ %@", [self faStringOfType:type], text] forState:UIControlStateNormal];
}

+(NSString *)faStringOfType:(int)type {
	NSString *title = nil;
	switch (type) {
  case 0:
			title = [NSString fontAwesomeIconStringForEnum:FAtrash];
			break;
  case 1:
			title = [NSString fontAwesomeIconStringForEnum:FAPlus];
			break;
  case 2:
			title = [NSString fontAwesomeIconStringForEnum:FAPencil];
			break;
  case 3:
			title = [NSString fontAwesomeIconStringForEnum:FAUser];
			break;
  case 4:
			title = [NSString fontAwesomeIconStringForEnum:FAUsers];
			break;
  case 5:
			title = [NSString fontAwesomeIconStringForEnum:FAuserSecret];
			break;
  case 6:
			title = [NSString fontAwesomeIconStringForEnum:FAComment];
			break;
  case 7:
			title = [NSString fontAwesomeIconStringForEnum:FAPause];
			break;
  case 8:
			title = [NSString fontAwesomeIconStringForEnum:FAStop];
			break;
  case 9:
			title = [NSString fontAwesomeIconStringForEnum:FAPlay];
			break;
  case 10:
			title = [NSString fontAwesomeIconStringForEnum:FASquare];
			break;
  case 11:
			title = [NSString fontAwesomeIconStringForEnum:FAlineChart];
			break;
  case 12:
			title = [NSString fontAwesomeIconStringForEnum:FARefresh];
			break;
  case 13:
			title = [NSString fontAwesomeIconStringForEnum:FAGlobe];
			break;
  case 14:
			title = [NSString fontAwesomeIconStringForEnum:FAUsd];
			break;
  case 15:
			title = [NSString fontAwesomeIconStringForEnum:FAStar];
			break;
  case 16:
			title = [NSString fontAwesomeIconStringForEnum:FABarChartO];
			break;
  case 17:
			title = [NSString fontAwesomeIconStringForEnum:FAList];
			break;
  case 18:
			title = [NSString fontAwesomeIconStringForEnum:FAListOl];
			break;
  case 19:
			title = [NSString fontAwesomeIconStringForEnum:FAThumbsUp];
			break;
  case 20:
			title = [NSString fontAwesomeIconStringForEnum:FAInfoCircle];
			break;
  case 21:
			title = [NSString fontAwesomeIconStringForEnum:FAArrowDown];
			break;
  case 22:
			title = [NSString fontAwesomeIconStringForEnum:FACheck];
			break;
  case 23:
			title = [NSString fontAwesomeIconStringForEnum:FATimes];
			break;
  case 24:
			title = [NSString fontAwesomeIconStringForEnum:FAArrowUp];
			break;
  case 25:
			title = [NSString fontAwesomeIconStringForEnum:FARepeat];
			break;
  case 26:
			title = [NSString fontAwesomeIconStringForEnum:FAListAlt];
			break;
  case 27:
			title = [NSString fontAwesomeIconStringForEnum:FACheckCircle];
			break;
  case 28:
			title = [NSString fontAwesomeIconStringForEnum:FAcalculator];
			break;
  case 29:
			title = [NSString fontAwesomeIconStringForEnum:FAhandPaperO];
			break;
  case 30:
			title = [NSString fontAwesomeIconStringForEnum:FAComment];
			break;
  case 31:
			title = [NSString fontAwesomeIconStringForEnum:FAGlobe];
			break;
  case 32:
			title = [NSString fontAwesomeIconStringForEnum:FAFloppyO];
			break;
  case 33:
			title = [NSString fontAwesomeIconStringForEnum:FASearch];
			break;
  case 34:
			title = [NSString fontAwesomeIconStringForEnum:FAdatabase];
			break;
  case 35:
			title = [NSString fontAwesomeIconStringForEnum:FApieChart];
			break;
  case 36:
			title = [NSString fontAwesomeIconStringForEnum:FALink];
			break;
  case 37:
			title = [NSString fontAwesomeIconStringForEnum:FAhandPaperO];
			break;
  case 38:
			title = [NSString fontAwesomeIconStringForEnum:FACog];
			break;
  case 39:
			title = [NSString fontAwesomeIconStringForEnum:FAFilter];
			break;
  case 40:
			title = [NSString fontAwesomeIconStringForEnum:FAPictureO];
			break;
  case 41:
			title = [NSString fontAwesomeIconStringForEnum:FAPencilSquareO];
			break;
  case 42:
			title = [NSString fontAwesomeIconStringForEnum:FAEnvelope];
			break;
  case 43:
			title = [NSString fontAwesomeIconStringForEnum:FAArrowLeft];
			break;
  case 44:
			title = [NSString fontAwesomeIconStringForEnum:FAArrowRight];
			break;
  case 45:
			title = [NSString fontAwesomeIconStringForEnum:FAbank];
			break;
  case 46:
			title = [NSString fontAwesomeIconStringForEnum:FAWrench];
			break;
  case 47:
			title = [NSString fontAwesomeIconStringForEnum:FAMoney];
			break;
  case 48:
			title = [NSString fontAwesomeIconStringForEnum:FATrophy];
			break;

  default:
			title = [NSString fontAwesomeIconStringForEnum:FAQuestionCircle];
			break;
	}
	return title;
}

+(void)populateSegmentBar:(UISegmentedControl *)segmentBar mOC:(NSManagedObjectContext *)mOC
{
	NSArray *games = [CoreDataLib selectRowsFromEntity:@"GAME" predicate:nil sortColumn:@"startTime" mOC:mOC ascendingFlg:NO];
	
	NSString *paddingString = @"%04d";
	NSMutableDictionary *stakesDict = [[NSMutableDictionary alloc] init];
	[stakesDict setValue:[NSString stringWithFormat:paddingString, 1] forKey:@"$1/$2"];
	[stakesDict setValue:[NSString stringWithFormat:paddingString, 1] forKey:@"$1/$3"];
	[stakesDict setValue:[NSString stringWithFormat:paddingString, 1] forKey:@"$3/$5"];
	[stakesDict setValue:[NSString stringWithFormat:paddingString, 1] forKey:@"$3/$6"];
	
	for(NSManagedObject *game in games) {
		NSString *type = [game valueForKey:@"Type"];
		NSString *stakes = [game valueForKey:@"stakes"];
		//		NSString *gametype = [game valueForKey:@"gametype"];
		//		NSString *limit = [game valueForKey:@"limit"];
		//		NSString *tournamentType = [game valueForKey:@"tournamentType"];
		
		int count = [[stakesDict valueForKey:stakes] intValue];
		count++;
		if([@"Cash" isEqualToString:type] && ![@"Single Table" isEqualToString:stakes])
			[stakesDict setValue:[NSString stringWithFormat:paddingString, count] forKey:stakes];
		
	}
	NSArray* sortedValues2 = [ProjectFunctions sortArrayDescending:[stakesDict allValues]];
	NSMutableArray *finalArray = [[NSMutableArray alloc] init];
	for(NSString *stake in sortedValues2) {
		for(NSString *clave in [stakesDict allKeys]){
			if ([stake isEqualToString:[stakesDict valueForKey:clave]]) {
				[finalArray addObject:clave];
			}
		}
	}
	
	int i=0;
	for (NSString *value in finalArray)
		if (i<=3)
			[segmentBar setTitle:value forSegmentAtIndex:i++];
	
}

+(void)ptpLocationAuthorizedCheck:(CLAuthorizationStatus)status {
	if (status == kCLAuthorizationStatusDenied) {
		[ProjectFunctions showAlertPopup:@"Location services not authorized" message:@"PTP needs locations services for some features to work.\n You can enable by exiting PTP and then going to Settings->PokerTrack. Set Location to \"While Using the App.\""];
	}
}

+(void)newButtonLook:(UIButton *)button mode:(int)mode {
	if(mode>=10)
		mode=0;
	int themeNumber = [[ProjectFunctions getUserDefaultValue:@"themeNumber"] intValue];
	
	// all buttons------
	[button setTitleShadowColor:nil forState:UIControlStateNormal];
	// all buttons------

	if(themeNumber == 2)
		[self changeToClassicThemeForButton:button mode:mode];
	else
		[self changeToModernThemeForButton:button mode:mode theme:themeNumber];

}

+(void)changeToClassicThemeForButton:(UIButton *)button mode:(int)mode {
	button.layer.masksToBounds = YES;
	button.backgroundColor=[UIColor clearColor];
	button.layer.borderWidth = 0;
	if(mode==0) {
		[button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
		[button setBackgroundImage:[UIImage imageNamed:@"yellowChromeBut.png"] forState:UIControlStateNormal];
	}
	if(mode==1) {
		[button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
		[button setBackgroundImage:[UIImage imageNamed:@"greenChromeBut.png"] forState:UIControlStateNormal];
	}
	if(mode==2) {
		[button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
		[button setBackgroundImage:[UIImage imageNamed:@"whiteChromeBut.png"] forState:UIControlStateNormal];
	}
	if(mode==3) {
		[button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
		[button setBackgroundImage:[UIImage imageNamed:@"redChromeBut.png"] forState:UIControlStateNormal];
	}
	if(mode==4) {
		[button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
		[button setBackgroundImage:[UIImage imageNamed:@"whiteChromeBut.png"] forState:UIControlStateNormal];
	}
	if(mode==5) {
		[button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
		[button setBackgroundImage:[UIImage imageNamed:@"blueChromeBut.png"] forState:UIControlStateNormal];
	}
}

+(void)changeToModernThemeForButton:(UIButton *)button mode:(int)mode theme:(int)theme {
	//	UIColor *color = [UIColor colorWithRed:1 green:.85 blue:0 alpha:1];
	[button setBackgroundImage:nil forState:UIControlStateNormal];
	
	UIColor *highBgColor = (mode==1)?[ProjectFunctions primaryButtonColor]:[ProjectFunctions themeBGColor];
	UIColor *highTextColor = (mode!=1)?[ProjectFunctions primaryButtonColor]:[ProjectFunctions themeBGColor];
	[button setBackgroundImage:[ProjectFunctions imageFromColor:highBgColor]
					  forState:UIControlStateHighlighted];
	[button setTitleColor:highTextColor forState:UIControlStateHighlighted];
	
	if(theme==0) { // modern
		button.layer.cornerRadius = 7;
		button.layer.masksToBounds = NO;
		button.layer.shadowColor = [UIColor blackColor].CGColor;
		button.layer.shadowOffset = CGSizeMake(4, 4);
		button.layer.shadowRadius = 5;
		button.layer.shadowOpacity = 0.85;
		button.layer.borderWidth = 0;
	} else if (theme==1) { //flat
		button.layer.cornerRadius = 0;
		button.layer.masksToBounds = YES;
		button.layer.shadowOffset = CGSizeMake(0, 0);
		button.layer.shadowRadius = 0;
		button.layer.shadowOpacity = 0;
		button.layer.borderWidth = 0;
	} else { // outline
		button.layer.cornerRadius = 4;
		button.layer.masksToBounds = NO;
		button.layer.shadowOffset = CGSizeMake(2, 2);
		button.layer.shadowRadius = 5;
		button.layer.shadowOpacity = 1;
		button.layer.shadowColor = [UIColor whiteColor].CGColor;
		button.layer.borderColor = [UIColor blackColor].CGColor;
		button.layer.borderWidth = 1;
	}

	if(mode==0) { // yellow
		[button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
		[button setBackgroundColor:[ProjectFunctions primaryButtonColor]];
		
	}
	if(mode==1) { // green
		button.layer.borderColor = [UIColor whiteColor].CGColor;
		button.layer.borderWidth = 1;
		[button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
		[button setBackgroundColor:[ProjectFunctions themeBGColor]];
		//[UIColor colorWithRed:.2 green:.8 blue:.2 alpha:1]
	}
	if(mode==2) { // gray
		[button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
		[button setBackgroundColor:[UIColor colorWithRed:.8 green:.8 blue:.8 alpha:1]];
		
	}
	if(mode==3) { // red
		[button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
		[button setBackgroundColor:[UIColor colorWithRed:1 green:0 blue:0 alpha:1]];
		
	}
	if(mode==4) { // dark gray
		[button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
		[button setBackgroundColor:[UIColor colorWithRed:.6 green:.6 blue:.6 alpha:1]];
		
	}
	if(mode==5) { // blue
		[button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
		[button setBackgroundColor:[UIColor colorWithRed:0 green:.6 blue:1 alpha:1]];
		
	}
	
}

+(float)chartHeightForSize:(float)height {
	float width = [[UIScreen mainScreen] bounds].size.width;
	if(width<320)
		width=320;
	return height*width/320;
}

+(BOOL)isOkToProceed:(NSManagedObjectContext *)context delegate:(id)delegate {
	if([ProjectFunctions isLiteVersion] && [CoreDataLib selectRowsFromTable:@"GAME" mOC:context].count>=5) {
		[ProjectFunctions showConfirmationPopup:@"Upgrade Now?" message:@"Sorry the trial period has ended. You will need to upgrade to use this feature." delegate:delegate tag:104];
		return NO;
	}
	return YES;
}

+(NSString *)scrubFilterValue:(NSString *)value {
	if(value.length>3 && [@"All" isEqualToString:[value substringToIndex:3]])
		return NSLocalizedString(@"All", nil);
	if([@"LifeTime" isEqualToString:value])
		return NSLocalizedString(@"All", nil);
	return value;
}

+(int)appThemeNumber {
	return [[ProjectFunctions getUserDefaultValue:@"themeNumber"] intValue];
}

+(int)themeBGNumber {
	NSArray *colors = [self bgThemeColors];
	int number = [[ProjectFunctions getUserDefaultValue:@"bgThemeColorNumber"] intValue];
	if(number<0) {
		number+=(colors.count*10);
	}
	return number%colors.count;
}

+(UIColor *)themeBGColor {
	if([ProjectFunctions themeTypeNumber]==1) {
		ThemeColorObj *colorObj = [ThemeColorObj objectOfGroup:[self themeGroupNumber] category:[self themeCategoryNumber]];
		return colorObj.themeBGColor;
	}
	NSArray *colors = [self bgThemeColors];
	int number = [[ProjectFunctions getUserDefaultValue:@"bgThemeColorNumber"] intValue];
	if(number<0) {
		number+=(colors.count*10);
	}
	return [colors objectAtIndex:number%colors.count];
}

+(NSArray *)bgThemeColors {
	return [NSArray arrayWithObjects:
			[UIColor colorWithRed:0 green:.6 blue:0 alpha:1],
			[UIColor colorWithRed:0 green:.4 blue:0 alpha:1],
			[UIColor colorWithRed:0 green:.3 blue:0 alpha:1],
			[UIColor colorWithRed:0 green:.2 blue:0 alpha:1],
			[UIColor colorWithRed:0 green:0 blue:0 alpha:1],
			[UIColor colorWithRed:.3 green:.3 blue:.3 alpha:1],
			[UIColor colorWithRed:.5 green:.5 blue:.5 alpha:1],
			[UIColor colorWithRed:.75 green:.75 blue:.75 alpha:1],
			[UIColor colorWithRed:.3 green:0 blue:0 alpha:1],
			[UIColor colorWithRed:0 green:0 blue:.3 alpha:1],
			[UIColor colorWithRed:0 green:.3 blue:.3 alpha:1],
			[UIColor colorWithRed:.3 green:0 blue:.3 alpha:1],
			[UIColor colorWithRed:.3 green:.3 blue:0 alpha:1],
			[UIColor colorWithRed:0 green:.7 blue:0 alpha:1],
			[UIColor colorWithRed:1 green:0 blue:0 alpha:1],
			[UIColor colorWithRed:0 green:0 blue:1 alpha:1],
			[UIColor colorWithRed:0 green:1 blue:1 alpha:1],
			[UIColor colorWithRed:1 green:0 blue:1 alpha:1],
			[UIColor colorWithRed:1 green:1 blue:0 alpha:1],
			[UIColor colorWithRed:0 green:1 blue:0 alpha:1],
			[UIColor colorWithRed:0 green:.7 blue:0 alpha:1],
			nil];
}

+(NSArray *)navBarThemeColors {
	return [NSArray arrayWithObjects:
			[UIColor colorWithRed:0 green:.4 blue:0 alpha:1],
			[UIColor colorWithRed:0 green:.3 blue:0 alpha:1],
			[UIColor colorWithRed:0 green:.2 blue:0 alpha:1],
			[UIColor colorWithRed:0 green:.1 blue:0 alpha:1],
			[UIColor colorWithRed:0 green:0 blue:0 alpha:1],
			[UIColor colorWithRed:.3 green:.3 blue:.3 alpha:1],
			[UIColor colorWithRed:.5 green:.5 blue:.5 alpha:1],
			[UIColor colorWithRed:.75 green:.75 blue:.75 alpha:1],
			[UIColor colorWithRed:.3 green:0 blue:0 alpha:1],
			[UIColor colorWithRed:0 green:0 blue:.3 alpha:1],
			[UIColor colorWithRed:0 green:.3 blue:.3 alpha:1],
			[UIColor colorWithRed:.3 green:0 blue:.3 alpha:1],
			[UIColor colorWithRed:.3 green:.3 blue:0 alpha:1],
			[UIColor colorWithRed:0 green:.7 blue:0 alpha:1],
			[UIColor colorWithRed:1 green:0 blue:0 alpha:1],
			[UIColor colorWithRed:0 green:0 blue:1 alpha:1],
			[UIColor colorWithRed:0 green:1 blue:1 alpha:1],
			[UIColor colorWithRed:1 green:0 blue:1 alpha:1],
			[UIColor colorWithRed:1 green:1 blue:0 alpha:1],
			[UIColor colorWithRed:0 green:1 blue:0 alpha:1],
			[UIColor colorWithRed:0 green:.7 blue:0 alpha:1],
			nil];
}

+(int)primaryColorNumber {
	NSArray *colors = [self primaryButtonColors];
	int number = [[ProjectFunctions getUserDefaultValue:@"primaryColorNumber"] intValue];
	if(number<0) {
		number+=colors.count;
	}
	int primaryColorNumber = number%colors.count;
	return primaryColorNumber;
}

+(UIColor *)primaryButtonColor {
	if([ProjectFunctions themeTypeNumber]==1) {
		ThemeColorObj *colorObj = [ThemeColorObj objectOfGroup:[self themeGroupNumber] category:[self themeCategoryNumber]];
		return colorObj.primaryColor;
	}
	NSArray *colors = [self primaryButtonColors];
	int number = [self primaryColorNumber];
	return [colors objectAtIndex:number%colors.count];
}

+(NSArray *)primaryButtonColors {
	return [NSArray arrayWithObjects:
			[UIColor colorWithRed:1 green:.94 blue:.25 alpha:1],
			[UIColor colorWithRed:1 green:.9 blue:.1 alpha:1],
			[UIColor colorWithRed:1 green:.8 blue:0 alpha:1],
			[UIColor colorWithRed:1 green:1 blue:.2 alpha:1],
			[UIColor colorWithRed:1 green:1 blue:.8 alpha:1],
			[UIColor colorWithRed:1 green:1 blue:1 alpha:1],
			[UIColor colorWithRed:.9 green:.9 blue:.9 alpha:1],
			[UIColor colorWithRed:.7 green:.7 blue:.7 alpha:1],
			[UIColor colorWithRed:1 green:.8 blue:.8 alpha:1],
			[UIColor colorWithRed:.8 green:1 blue:.8 alpha:1],
			[UIColor colorWithRed:.8 green:.8 blue:1 alpha:1],
			[UIColor colorWithRed:.8 green:1 blue:1 alpha:1],
			[UIColor colorWithRed:1 green:.8 blue:1 alpha:1],
			[UIColor colorWithRed:1 green:1 blue:.8 alpha:1],
			[UIColor colorWithRed:1 green:.5 blue:.5 alpha:1],
			[UIColor colorWithRed:.2 green:.7 blue:1 alpha:1],
			[UIColor colorWithRed:0 green:1 blue:1 alpha:1],
			[UIColor colorWithRed:1 green:0 blue:1 alpha:1],
			[UIColor colorWithRed:1 green:1 blue:0 alpha:1],
			[UIColor colorWithRed:0 green:1 blue:0 alpha:1],
			nil];
}

+(int)segmentColorNumber {
	NSArray *colors = [self navBarThemeColors];
	int number = [[ProjectFunctions getUserDefaultValue:@"segmentColorNumber"] intValue];
	if(number<0) {
		number+=(colors.count*10);
	}
	return number%colors.count;
}

+(UIColor *)segmentThemeColor { // navbar
	if([ProjectFunctions themeTypeNumber]==1) {
		ThemeColorObj *colorObj = [ThemeColorObj objectOfGroup:[self themeGroupNumber] category:[self themeCategoryNumber]];
		return colorObj.navBarColor;
	}
	NSArray *colors = [self navBarThemeColors];
	int number = [[ProjectFunctions getUserDefaultValue:@"segmentColorNumber"] intValue];
	if(number<0) {
		number+=(colors.count*10);
	}
	return [colors objectAtIndex:number%colors.count];
}

+(int)themeTypeNumber {
	return [[ProjectFunctions getUserDefaultValue:@"themTypeNumber"] intValue];
}

+(int)themeGroupNumber {
	return [[ProjectFunctions getUserDefaultValue:@"themeGroupNumber"] intValue];
}

+(int)themeCategoryNumber {
	return [[ProjectFunctions getUserDefaultValue:@"themeCategoryNumber"] intValue];
}

+(NSString *)nameOfTheme {
	ThemeColorObj *colorObj = [ThemeColorObj objectOfGroup:[self themeGroupNumber] category:[self themeCategoryNumber]];
	return colorObj.name;
}

+(UIColor *)grayThemeColor {
	if([ProjectFunctions themeTypeNumber]==1) {
		ThemeColorObj *colorObj = [ThemeColorObj objectOfGroup:[self themeGroupNumber] category:[self themeCategoryNumber]];
		return colorObj.grayColor;
	}
	return [UIColor colorWithRed:180.0/255 green:180.0/255 blue:180.0/255 alpha:1];
}

+(UIColor *)colorForPlayerType:(int)type {
	NSArray *colors = [NSArray arrayWithObjects:
					   [UIColor redColor], // fish
					   [UIColor colorWithRed:1 green:.7 blue:0 alpha:1], //
					   [UIColor yellowColor], //
					   [UIColor colorWithRed:.75 green:1 blue:0 alpha:1], // rounder (orange)
					   [UIColor colorWithRed:0 green:.7 blue:0 alpha:1], // rounder (orange)
					   [UIColor greenColor], //
					   [UIColor colorWithRed:.7 green:.7 blue:.7 alpha:1],
					   nil];
	if(type<colors.count)
		return [colors objectAtIndex:type];
	else
		return [UIColor blackColor];
}

+(BOOL)getThemeBGImageFlg {
	return [[ProjectFunctions getUserDefaultValue:@"themBGImageFlg"] isEqualToString:@"Y"];
}

+(int)getThemeBGImageColor {
	return [[ProjectFunctions getUserDefaultValue:@"themeBGImageColor"] intValue];
}

+(UIImage *)bgThemeImage {
	int number = [self getThemeBGImageColor];
	NSArray *images = [NSArray arrayWithObjects:
					   @"greenFelt5.jpg",
					   @"bluefelt.jpg",
					   @"redfelt.jpg",
					   nil];
	return [UIImage imageNamed:[images objectAtIndex:number]];
}



@end
