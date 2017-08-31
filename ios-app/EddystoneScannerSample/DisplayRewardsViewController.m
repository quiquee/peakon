//
//  DisplayRewardsViewController.m
//  EddystoneScannerSample
//
//  Created by MBenHajla on 30.08.17.
//  Copyright © 2017 Google, Inc. All rights reserved.
//

#import "DisplayRewardsViewController.h"

@interface DisplayRewardsViewController ()

@end

@implementation DisplayRewardsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
   
    self.beaconnameLabel.text = self.beaconName;
    self.rewardLabel.text = [NSString stringWithFormat:@"Reward: %@ IOTA", [self.beaconReward stringValue]] ;
    self.weatherDataLabel.text = [NSString stringWithFormat:@"Temperature: %@ °", [self.beaconWeahterDataTempC stringValue]] ;
    ;
    
    
    


}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)exploreButtonTapped:(UIButton *)sender {
    if(self.wikipediaURLString){
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.wikipediaURLString]];
    }
    
    
}
- (IBAction)collectRewardButtonTapped:(UIButton *)sender {
    
   
    
    NSString* targetWallet = self.walletAddressTextView.text;
    NSMutableDictionary *collectRewardDict;
    if(targetWallet && self.jsonDict && [self.jsonDict count]>0){
        
         collectRewardDict = [NSMutableDictionary dictionaryWithDictionary:self.jsonDict];
    
    }else{
        NSLog(@"collectRewardButtonTapped: targetWallet or json is empty");
        return;
    }
    
    [self.colletcRewardButton setTitle:@"Collecting....." forState:UIControlStateNormal];
    
    [collectRewardDict setObject:targetWallet forKey:@"targetWallet"];
    NSError *error;
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:collectRewardDict
                                                       options:NSJSONWritingPrettyPrinted error:&error];
    
    
    
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:@"http://207.154.208.91"]];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:jsonData];
    
    
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithRequest:request
                completionHandler:^(NSData *data,
                                    NSURLResponse *response,
                                    NSError *error) {
                    
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        [self.colletcRewardButton setTitle:@"Collect Reward" forState:UIControlStateNormal];
                    });
                    
                    
                   
                    NSLog(@"res---%@", response);
                    NSDictionary *responseDict=[NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
                    
                    NSLog(@"the value is dictionary is %@",responseDict);
                }] resume];

}
@end
