//
//  ViewController.m
//  MAGNudityDetectorDemo
//
//  Created by Andrew Petrus on 02.03.15.
//  Copyright (c) 2015 MadAppGang. All rights reserved.
//

#import "ViewController.h"
#import "MAGNudityDetector.h"

@interface ViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *resultLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

- (IBAction)chooseImageButtonTapped:(id)sender;

@end


@implementation ViewController


#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


#pragma mark - Custom actions

- (IBAction)chooseImageButtonTapped:(id)sender {
    UIImagePickerController *picker = [UIImagePickerController new];
    picker.delegate = self;
    [self presentViewController:picker
                       animated:YES
                     completion:nil];
}

- (void)showResult:(NSDictionary *)result {
    self.resultLabel.hidden = NO;
    self.resultLabel.text = [NSString stringWithFormat:@"Potential nudity result: %@ (%f%%)",
                             [result[kPotentialNudityResultKey] boolValue] ? @"YES" : @"NO",
                             [result[kPotentialNudityPixelPercentageKey] floatValue]];
    [self.activityIndicator stopAnimating];
}

#pragma mark - UIImagePickerController delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    if (info[UIImagePickerControllerOriginalImage]) {
        [self dismissViewControllerAnimated:YES completion:^{
            self.imageView.image = info[UIImagePickerControllerOriginalImage];
            [self.activityIndicator startAnimating];
            [[MAGNudityDetector sharedInstance] analyzeImage:self.imageView.image
                                         withCompletionBlock:^(NSDictionary *result) {
                                             [self showResult:result];
                                         }];
        }];
    }
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
}
@end
