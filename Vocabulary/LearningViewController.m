//
//  LearningViewController.m
//  Vocabulary
//
//  Created by 缪和光 on 12-10-21.
//  Copyright (c) 2012年 缪和光. All rights reserved.
//

#import "LearningViewController.h"
#import "CoreDataHelper.h"
#import "MBProgressHUD.h"
#import "CibaEngine.h"

@interface LearningViewController ()

@end

@implementation LearningViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (_shouldHideInfo) {
        self.acceptationTextView.hidden = YES;
    }else{
        self.acceptationTextView.hidden = NO;
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [self refreshView];
}

-(void)viewWillDisappear:(BOOL)animated
{
    NSLog(@"view will disappear");
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    [self.downloadOp cancel];
    [self.voiceOp cancel];
    self.downloadOp = nil;
    self.voiceOp = nil;
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    self.acceptationTextView.text = @"";
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (id)initWithWord:(Word *)word
{
    self = [super initWithNibName:@"LearningViewController" bundle:nil];
    if (self) {
        _word = word;
        _shouldHideInfo = NO;
    }
    return self;
}



- (void)refreshView
{
    self.lblKey.text = self.word.key;
    [self.lblKey sizeToFit];
    if (self.word.hasGotDataFromAPI) {
        NSString *jointStr = [NSString stringWithFormat:@"英[%@] 美[%@]\n%@%@",self.word.psEN,self.word.psUS,self.word.acceptation,self.word.sentences];
        self.acceptationTextView.text = jointStr;
        self.player = [[AVAudioPlayer alloc]initWithData:self.word.pronounceUS error:nil];
        [self.player play];
    }else{
        Reachability *reachability = [Reachability reachabilityForInternetConnection];
        if ([reachability currentReachabilityStatus] == NotReachable) {
            self.acceptationTextView.text = @"无网络连接，首次访问需要通过网络。";
            return;
        }
        if (self.downloadOp == nil || self.downloadOp.isCancelled) {
//            NSLog(@"iscancelled:%d,isfinished:%d",self.downloadOp.isFinished,self.downloadOp.isFinished);
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.labelText = @"正在取词";
            CibaEngine *engine = [CibaEngine sharedInstance];
            self.downloadOp = [engine infomationForWord:self.word.key onCompletion:^(NSDictionary *parsedDict) {
                if (parsedDict == nil) {
                    // error on parsing
                    hud.labelText = @"词义加载失败";
                    [hud hide:YES afterDelay:1];
                }
                self.word.acceptation = [parsedDict objectForKey:@"acceptation"];
                self.word.psEN = [parsedDict objectForKey:@"psEN"];
                self.word.psUS = [parsedDict objectForKey:@"psUS"];
                self.word.sentences = [parsedDict objectForKey:@"sentence"];
                //self.word.hasGotDataFromAPI = [NSNumber numberWithBool:YES];
                [[CoreDataHelper sharedInstance]saveContext];
                //load voice
                NSString *pronURL = [parsedDict objectForKey:@"pronounceUS"];
                if (pronURL == nil) {
                    pronURL = [parsedDict objectForKey:@"pronounceEN"];
                }
                if (pronURL && (self.voiceOp == nil || self.voiceOp.isCancelled)) {
                    self.voiceOp = [engine getPronWithURL:pronURL onCompletion:^(NSData *data) {
                        NSLog(@"voice succeed");
                        if (data == nil) {
                            NSLog(@"data nil");
                            return;
                        }
                        self.word.pronounceUS = data;
                        self.word.hasGotDataFromAPI = [NSNumber numberWithBool:YES];
                        [[CoreDataHelper sharedInstance]saveContext];
                        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                        [self refreshView];
                        
                    } onError:^(NSError *error) {
                        NSLog(@"VOICE ERROR");
                        [self refreshView];
                        self.word.hasGotDataFromAPI = [NSNumber numberWithBool:NO];
                        [[CoreDataHelper sharedInstance]saveContext];
                        hud.labelText = @"语音加载失败";
                        [hud hide:YES afterDelay:1];
                    }];
                }else{
                    hud.labelText = @"语音加载失败";
                    [hud hide:YES afterDelay:1];
                    [self refreshView];
                }
                
            } onError:^(NSError *error) {
                hud.labelText = @"词义加载失败";
                [hud hide:YES afterDelay:1];
                NSLog(@"ERROR");
            }];
        }
    }
}
- (IBAction)btnReadOnPressed:(id)sender
{
    if (self.player != nil) {
        [self.player play];
    }
}

- (void)showInfo
{
    self.shouldHideInfo = NO;
    self.acceptationTextView.hidden = NO;
}

- (void)hideInfo
{
    self.shouldHideInfo = YES;
    self.acceptationTextView.hidden = YES;
}
@end