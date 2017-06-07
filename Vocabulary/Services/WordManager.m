
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
//  ConfusingWordsIndexer.m
//  Vocabulary
//
//  Created by 缪 和光 on 12-11-22.
//  Copyright (c) 2012年 缪和光. All rights reserved.
//

#import "WordManager.h"
#import "CoreData+MagicalRecord.h"
#import "Word.h"

@interface WordManager ()

@property (nonatomic, strong) NSOperationQueue *queryOperationQueue;

@end

@implementation WordManager

+ (WordManager *)sharedInstance {
    static WordManager *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[WordManager alloc]init];
    });
    return _sharedInstance;
}

- (instancetype)init
{
    if (self = [super init]) {
        _queryOperationQueue = [[NSOperationQueue alloc]init];
        _queryOperationQueue.maxConcurrentOperationCount = 1;
    }
    return self;
}

+ (void)indexNewWordsWithoutSaving:(NSArray *)newWords inContext:(NSManagedObjectContext *)context progressBlock:(HKVProgressCallback)progressBlock completion:(HKVErrorBlock)completion; {
    BOOL needIndex = [[NSUserDefaults standardUserDefaults]boolForKey:kAutoIndex];
    if (!needIndex) {
        if (completion) {
            completion(nil);
        }
        return;
    }
    
    if (newWords.count == 0) {
        if (completion != NULL) {
            completion(nil);
        }
        return;
    }
    
    NSArray *allWords = [Word MR_findAllInContext:context];
    NSUInteger totalNum = newWords.count;
    NSUInteger finishedNum = 0;
    for (Word *anNewWord in newWords) {
        NSString *key1 = anNewWord.key;
        for (Word *anExistingWord in allWords) {
            NSString *key2 = anExistingWord.key;
            if (![key1 isEqualToString:key2]) {
                @autoreleasepool {
                    float similarity = [self similarityOfString:key1 toString:key2];
                    if (similarity > 60) {
                        [anNewWord addSimilarWordsObject:anExistingWord];
                    }
                }
            }
            finishedNum ++;
            float progress = ((float)finishedNum)/totalNum;
            dispatch_async(dispatch_get_main_queue(), ^{
                if (progressBlock != NULL) progressBlock(progress);
            });
        }
        
    }
    if (completion) {
        completion(nil);
    }
}

+ (void)reIndexForAllWithProgressCallback:(HKVProgressCallback)progressBlock completion:(HKVVoidBlock)completion
{
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        NSArray *allWords = [Word MR_findAllInContext:localContext];
        for (Word *aWord in allWords) {
            // remove all similar words
            [aWord removeSimilarWords:aWord.similarWords];
        }
        NSUInteger totalNum = allWords.count;
        NSUInteger finishedNum = 0;
        for (int i = 0; i < allWords.count; i++) {
            Word *w1 = allWords[i];
            for (int j = i; j < allWords.count; j++) {
                Word *w2 = allWords[j];
                if (i != j) {
                    @autoreleasepool {
                        float similarity = [self similarityOfString:w1.key toString:w2.key];
                        if (similarity > 60) {
                            [w1 addSimilarWordsObject:w2];
                            [w2 addSimilarWordsObject:w1];
                        }
                    }
                }
            }
            
            finishedNum ++;
            float progress = ((float)finishedNum)/totalNum;
            dispatch_async(dispatch_get_main_queue(), ^{
                if (progressBlock) {
                    progressBlock(progress);
                }
            });
        }
    } completion:^(BOOL success, NSError *error) {
        if (completion) {
            completion();
        }
    }];
    
        
}

+ (void)searchWord:(NSString *)key completion:(void(^)(NSArray *words))completion
{
    [[self sharedInstance]searchWord:key completion:completion];
}

- (void)searchWord:(NSString *)key completion:(void(^)(NSArray *words))completion
{
    
    [self.queryOperationQueue cancelAllOperations];

    NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(key CONTAINS[cd] %@)",key];
        NSArray *results = [Word MR_findAllSortedBy:@"key" ascending:YES withPredicate:predicate];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(results);
            }
        });
    }];
    [self.queryOperationQueue addOperation:operation];
}

/**
 Calculate the similarity.
 
 @param ori  string1
 @param dest string2
 
 @return similarity in percentage
 */
+ (float)similarityOfString:(NSString *)ori toString:(NSString *)dest {
    float editDistance = [self compareString:ori withString:dest];
    return (1 - (2 * editDistance / (ori.length + dest.length))) * 100;
}

+ (float)compareString:(NSString *)originalString withString:(NSString *)comparisonString
{
    // Normalize strings
    [originalString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [comparisonString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    originalString = [originalString lowercaseString];
    comparisonString = [comparisonString lowercaseString];
    
    // Step 1 (Steps follow description at http://www.merriampark.com/ld.htm)
    NSInteger k, i, j, cost, * d, distance;
    
    NSInteger n = [originalString length];
    NSInteger m = [comparisonString length];
    
    if( n++ != 0 && m++ != 0 ) {
        
        d = malloc( sizeof(NSInteger) * m * n );
        
        // Step 2
        for( k = 0; k < n; k++)
            d[k] = k;
        
        for( k = 0; k < m; k++)
            d[ k * n ] = k;
        
        // Step 3 and 4
        for( i = 1; i < n; i++ )
            for( j = 1; j < m; j++ ) {
                
                // Step 5
                if( [originalString characterAtIndex: i-1] ==
                   [comparisonString characterAtIndex: j-1] )
                    cost = 0;
                else
                    cost = 1;
                
                // Step 6
                d[ j * n + i ] = [self smallestOf: d [ (j - 1) * n + i ] + 1
                                            andOf: d[ j * n + i - 1 ] + 1
                                            andOf: d[ (j - 1) * n + i - 1 ] + cost ];
                
                // This conditional adds Damerau transposition to Levenshtein distance
                if( i>1 && j>1 && [originalString characterAtIndex: i-1] ==
                   [comparisonString characterAtIndex: j-2] &&
                   [originalString characterAtIndex: i-2] ==
                   [comparisonString characterAtIndex: j-1] )
                {
                    d[ j * n + i] = [self smallestOf: d[ j * n + i ]
                                               andOf: d[ (j - 2) * n + i - 2 ] + cost ];
                }
            }
        
        distance = d[ n * m - 1 ];
        
        free( d );
        
        return distance;
    }
    return 0.0;
}

// Return the minimum of a, b and c - used by compareString:withString:
+ (NSInteger)smallestOf:(NSInteger)a andOf:(NSInteger)b andOf:(NSInteger)c
{
    NSInteger min = a;
    if ( b < min )
        min = b;
    
    if( c < min )
        min = c;
    
    return min;
}

+ (NSInteger)smallestOf:(NSInteger)a andOf:(NSInteger)b
{
    NSInteger min=a;
    if (b < min)
        min=b;
    
    return min;
}

#pragma mark - lcs
+ (NSInteger)longestCommonSubstringWithStr1:(NSString *)str1 str2:(NSString *)str2
{
    NSInteger m, n, *d, maxLen;
    m = str1.length;
    n = str2.length;
    
    maxLen = 0;
    d = malloc( sizeof(NSInteger) * m * n );
    
    for (int i = 0; i<n; i++) {
        for (int j = 0; j<m; j++) {
            if ([str1 characterAtIndex:j] != [str2 characterAtIndex:i]) {
                d[j*n+i] = 0;
            }else{
                if (i==0 || j==0) {
                    d[j*n+i] = 1;
                }else{
                    d[j*n+i] = 1 + d[(j-1)*n+i-1];
                }
                if (d[j*n+i] > maxLen) {
                    maxLen = d[j*n+i];
                }
            }
        }
    }
    free(d);
    return maxLen;
}

@end
