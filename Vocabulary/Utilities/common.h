
/*
 *  This file is part of 记词助手.
 *
 *	记词助手 is free software: you can redistribute it and/or modify
 *	it under the terms of the GNU General Public License Version 2 as 
 *  published by the Free Software Foundation.
 *
 *	记词助手 is distributed in the hope that it will be useful,
 *	but WITHOUT ANY WARRANTY; without even the implied warranty of
 *	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *	GNU General Public License for more details.
 *
 *	You should have received a copy of the GNU General Public License
 *	along with 记词助手.  If not, see <http://www.gnu.org/licenses/>.
 */

//
//  Constants.h
//  Vocabulary
//
//  Created by 缪和光 on 12-10-27.
//  Copyright (c) 2012年 缪和光. All rights reserved.
//

#ifndef Vocabulary_Common_h
#define Vocabulary_Common_h

#define RGBA(r,g,b,a) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a]

//constants
#define kPerformSoundAutomatically @"performSound"

#define kTodaysPlanWordListIdURIRepresentation @"todaysPlanWordListIdURIRepresentation"
#define kDayNotificationTime @"dayNotificationTime"
#define kNightNotificationTime @"nightNotificationTime"
#define kAutoIndex @"autoIndex"

// 当PlanningViewController收到shouldRefreshTodaysPlanNotificationKey后，刷新plan
#define kShouldRefreshTodaysPlanNotificationKey @"shouldRefreshTodaysPlanNotificationKey"

// 当PlanMaker收到kWordListDidChangeNotificationKey后，强制新建一个plan
#define kWordListWillChangeNotificationKey @"kWordListWillChangeNotificationKey"
#define kWordListDidChangeNotificationKey @"kWordListDidChangeNotificationKey"

extern NSString * WordListManagerDomain;
extern int WordListCreatorEmptyWordSetError;
extern int WordListCreatorNoTitleError;

extern NSString *CibaEngineDomain;
extern int FillWordError;
extern int FillWordPronError;
extern int ParseJSONError;


#define GlobalBackgroundColor RGBA(227,227,227,1)

#define kChannelId @"91Store"

#define IS_WIDESCREEN ( fabs((double)[[UIScreen mainScreen ] bounds ].size.height -(double)568)< DBL_EPSILON )
#define IS_IPHONE ([[[UIDevice currentDevice ] model ] isEqualToString:@"iPhone"])
#define IS_IPOD   ([[[UIDevice currentDevice ] model ] isEqualToString:@"iPod touch"])
#define IS_IPHONE_5 ( IS_IPHONE && IS_WIDESCREEN )
#define IS_IPAD [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad
#define GRATER_THAN_IOS_7 ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0f)
#define IOS6_7_DELTA(V,X,Y,W,H) if (GRATER_THAN_IOS_7) {CGRect f = V.frame;f.origin.x += X;f.origin.y += Y;f.size.width += W;f.size.height += H;V.frame=f;}

@class Word;

// block define
typedef void (^HKVProgressCallback)(float progress);
typedef void (^HKVVoidBlock)(void);
typedef void (^HKVErrorBlock)(NSError *error);

typedef void (^CompleteBlockWithStr)(NSDictionary *parsedDict);
typedef void (^CompleteBlockWithData)(NSData *data);
typedef void (^CompleteBlockWithWord)(Word *word);

#endif
