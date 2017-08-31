// Copyright 2015 Google Inc. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "ViewController.h"

#import "ESSBeaconScanner.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "DisplayRewardsViewController.h"

@interface ViewController () <ESSBeaconScannerDelegate> {
  ESSBeaconScanner *_scanner;
   BOOL canRestartReward ;
    NSDictionary *responseDict;
    NSDictionary *jsonDict; //request
}

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  _scanner = [[ESSBeaconScanner alloc] init];
  _scanner.delegate = self;
  [_scanner startScanning];
    canRestartReward = false;
    self.labelURL.text = @"";
    [self.earnRewardButton setTitle:@"Earn Reward....." forState:UIControlStateNormal];
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
    _scanner.delegate = nil;
  [_scanner stopScanning];
  _scanner = nil;
}

- (void)beaconScanner:(ESSBeaconScanner *)scanner
        didFindBeacon:(id)beaconInfo {
  NSLog(@"I Saw an Eddystone!: %@", beaconInfo);
}

- (void)beaconScanner:(ESSBeaconScanner *)scanner didUpdateBeacon:(id)beaconInfo {
  NSLog(@"I Updated an Eddystone!: %@", beaconInfo);
}

- (void)beaconScanner:(ESSBeaconScanner *)scanner didFindURL:(NSURL *)url peripheralData:(NSString *)peripheralData peripheralIdentifier:(NSString *)peripheralIdentifier advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
  //NSLog(@"I Saw a URL!: %@ , advertisementData: %@", url, advertisementData);
  
    //NSLog(@">>I Saw Beacon with Identifier: %@, RSSI: %i", peripheralIdentifier, [RSSI intValue]);
    
    // Only near by filters
    
    if (!([RSSI intValue] > -50 & [RSSI intValue] < 0 )){
        /*
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.earnRewardButton setTitle:@"Earn Reward...." forState:UIControlStateNormal];
            });
        */
        return;
    }else{
        NSLog(@">>I Saw Beacon with Identifier: %@, RSSI: %i", peripheralIdentifier, [RSSI intValue]);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if(![self.earnRewardButton.titleLabel.text isEqualToString:@"Earn Reward" ] ){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.earnRewardButton setTitle:@"Earn Reward" forState:UIControlStateNormal];
                });
            }
          
        });
        
    }
 
  // generate  JSON Structure
   NSString* urlString = [url absoluteString];
    
  // Call WebService and Transmit Data
    
    NSDictionary*  serviceDataDict = [advertisementData objectForKey:@"kCBAdvDataServiceData"];
    NSArray*  serviceUUIDDict = [advertisementData objectForKey:@"kCBAdvDataServiceUUIDs"];
    
    NSData* advData  = [serviceDataDict allValues][0] ;
    
    
    
    NSString *serviceData = [[NSString alloc] initWithData:advData encoding:NSASCIIStringEncoding];
    
    CBUUID  *serviceCBUUID = serviceUUIDDict[0];

    NSData *data = [serviceCBUUID data];
    
    NSUInteger bytesToConvert = [data length];
    const unsigned char *uuidBytes = [data bytes];
    NSMutableString *outputString = [NSMutableString stringWithCapacity:16];
    
    for (NSUInteger currentByteIndex = 0; currentByteIndex < bytesToConvert; currentByteIndex++)
    {
        switch (currentByteIndex)
        {
            case 3:
            case 5:
            case 7:
            case 9:[outputString appendFormat:@"%02x-", uuidBytes[currentByteIndex]]; break;
            default:[outputString appendFormat:@"%02x", uuidBytes[currentByteIndex]];
        }
        
    }
    
    NSString *serviceUUID = outputString ;
    
    if(canRestartReward ){
        canRestartReward = NO;
        self.earnRewardButton.enabled = false;

       
        if(!peripheralData){
            peripheralData =@"";
        }
        
       
        
       jsonDict = [NSDictionary
                                  dictionaryWithObjectsAndKeys:
                                  peripheralData,@"peripheralData", peripheralIdentifier,@"peripheralIdentifier",urlString ,@"urlString",
                                  serviceData,@"serviceData",
                                  serviceUUID,@"serviceUUID",
                                  nil];
        NSError *error;
        NSData* jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict
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
               
                self.earnRewardButton.enabled = true;
                NSLog(@">>>Reward from Beacon with Identifier: %@", peripheralIdentifier);
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.labelURL.text = urlString;
                    self.labelServiceData.text =  peripheralIdentifier;
                    if(error){
                        self.labelServiceUUID.text =  error;
                        
                    }
                    [self performSegueWithIdentifier:@"showRewards" sender:self];
                    
                });
                
                
                // handle response
                /*
                 {
                 “peripheralIdentifier”: “9F76EE86-872D-407D-9C73-BA4DB6F4C468",
                 “beaconowner”: “Enrique”,
                 “beaconname”: “Cabo Quintres, La Atalaya”,
                 “wikipediaurl”: “https://ceb.wikipedia.org/wiki/Cabo_Quintres“,
                 “reward”: 4,
                 “urlString”: “https://ruu.vi/#BEQgAMO0D”,
                 “weatherData”: {
                 “tempC”: 17,
                 “tempF”: 63,
                 “humidityPercent”: 1,
                 “airPressure”: 677
                 }
                 }
                */
                NSLog(@"res---%@", response);
                responseDict=[NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
                
                NSLog(@"the value is dictionary is %@",responseDict);
            }] resume];
    
    
    }

    
    
    
    
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([[segue identifier] isEqualToString:@"showRewards"])
    {
        // Get reference to the destination view controller
        DisplayRewardsViewController *displayRewardsViewController = [segue destinationViewController];
        
        displayRewardsViewController.jsonDict = jsonDict;
        
        // Pass any objects to the view controller here
        if(responseDict && [responseDict count] >0){
            displayRewardsViewController.beaconName= [responseDict valueForKey:@"beaconName"];
             displayRewardsViewController.wikipediaURLString = [responseDict valueForKey:@"beaconUrl"];
             displayRewardsViewController.beaconReward = [responseDict valueForKey:@"beaconReward"];
            NSDictionary *weatherDataDict = [responseDict valueForKey:@"weatherData"];
            if(weatherDataDict && [weatherDataDict count]> 0){
                displayRewardsViewController.beaconWeahterDataTempC= [weatherDataDict valueForKey:@"tempC"];
            }
            
            
        }
        
        
        
    }


}


- (IBAction)earnButtonTapped:(UIButton *)sender {
    canRestartReward = YES;
    self.labelURL.text = @"";
    self.labelServiceData.text =  @"";
    self.labelServiceUUID.text =  @"";
     [self.earnRewardButton setTitle:@"Earn Reward....." forState:UIControlStateNormal];
}
@end
