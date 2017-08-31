//
//  DisplayRewardsViewController.h
//  EddystoneScannerSample
//
//  Created by MBenHajla on 30.08.17.
//  Copyright © 2017 Google, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DisplayRewardsViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *beaconnameLabel;
@property (weak, nonatomic) IBOutlet UILabel *rewardLabel;
@property (weak, nonatomic) IBOutlet UILabel *weatherDataLabel;
@property (weak, nonatomic) IBOutlet UITextField *walletAddressTextView;
@property (weak, nonatomic) IBOutlet UIButton *colletcRewardButton;
- (IBAction)collectRewardButtonTapped:(UIButton *)sender;

@property (strong, nonatomic) NSString *wikipediaURLString;
@property (strong, nonatomic) NSString *beaconName;
@property (strong, nonatomic) NSNumber *beaconReward;
@property (strong, nonatomic) NSNumber *beaconWeahterDataTempC;
@property (weak, nonatomic) IBOutlet UIButton *exploreButton;

@property (strong, nonatomic) NSDictionary *jsonDict;

- (IBAction)exploreButtonTapped:(UIButton *)sender;


@end
