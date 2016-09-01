//
//  SettingsDetailViewController.m
//  Monitor
//
//  Created by Martin Lane-Smith on 4/12/14.
//  Copyright (c) 2014 Martin Lane-Smith. All rights reserved.
//

#import "SettingsDetailViewController.h"
#import "PubSubMsg.h"
#import "ps.h"

@interface SettingsDetailViewController ()
{
    float fMinimum, fMaximum, fCurrent, fNewValue;
    int iMinimum, iMaximum, iCurrent, iNewValue;
    NSString *text;
    int type;
    
    NSString *name;
    NSString *domain;
    NSMutableDictionary * settingsDict;
}
@property (weak, nonatomic) IBOutlet UITextField *txtText;
@property (weak, nonatomic) IBOutlet UILabel *lblTitle;
@property (weak, nonatomic) IBOutlet UILabel *lblCurrent;
@property (weak, nonatomic) IBOutlet UILabel *lblNew;
@property (weak, nonatomic) IBOutlet UILabel *lblMinimum;
@property (weak, nonatomic) IBOutlet UILabel *lblMaximum;
- (IBAction)sliderChanged:(UISlider *)sender;
@property (weak, nonatomic) IBOutlet UISlider *slider;
- (IBAction)btnSend:(UIButton *)sender;
- (IBAction)btnCancel:(id)sender;

@end

@implementation SettingsDetailViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) settingsDict: (NSMutableDictionary *) dict{
    settingsDict = dict;
    name    = [dict objectForKey:@"name"];
    domain  = [dict objectForKey:@"domain"];
    type    = [[dict objectForKey:@"type"] intValue];
    
    switch(type)
    {
        case PS_REGISTRY_INT_TYPE:
        {
            iMinimum         = [(NSNumber*)[dict objectForKey:@"min"] intValue];
            iMaximum         = [(NSNumber*)[dict objectForKey:@"max"] intValue];
            iCurrent         = [(NSNumber*)[dict objectForKey:@"value"] intValue];
            iNewValue        = iCurrent;
        }
            break;
        case PS_REGISTRY_REAL_TYPE:
        {
            fMinimum         = [(NSNumber*)[dict objectForKey:@"min"] floatValue];
            fMaximum         = [(NSNumber*)[dict objectForKey:@"max"] floatValue];
            fCurrent         = [(NSNumber*)[dict objectForKey:@"value"] floatValue];
            fNewValue        = fCurrent;
        }
            break;
        default:
            break;
    }

}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}
- (void)viewWillAppear:(BOOL)animated {
    _lblTitle.text = name;
    
    switch(type)
    {
        case PS_REGISTRY_INT_TYPE:
        {
            _slider.minimumValue = iMinimum;
            _slider.maximumValue = iMaximum;
            _slider.value = iCurrent;
            
            _lblMinimum.text = [NSString stringWithFormat:@"%i",iMinimum];
            _lblMaximum.text = [NSString stringWithFormat:@"%i",iMaximum];
            _lblCurrent.text = [NSString stringWithFormat:@"Current Value: %i",iCurrent];
            _lblNew.text = [NSString stringWithFormat:@"New Value: %i",iNewValue];
            
            _slider.hidden = false;
            _lblMinimum.hidden = false;
            _lblMaximum.hidden = false;
            _lblCurrent.hidden = false;
            _lblNew.hidden = false;
        }
            break;
        case PS_REGISTRY_REAL_TYPE:
        {
            _slider.minimumValue = fMinimum;
            _slider.maximumValue = fMaximum;
            _slider.value = fCurrent;
            
            if (fMaximum > 100){
                _lblMinimum.text = [NSString stringWithFormat:@"%.0f",fMinimum];
                _lblMaximum.text = [NSString stringWithFormat:@"%.0f",fMaximum];
                _lblCurrent.text = [NSString stringWithFormat:@"Current Value: %.0f",fCurrent];
                _lblNew.text = [NSString stringWithFormat:@"New Value: %.0f",fNewValue];
            }else if (fMaximum >1){
                _lblMinimum.text = [NSString stringWithFormat:@"%.1f",fMinimum];
                _lblMaximum.text = [NSString stringWithFormat:@"%.1f",fMaximum];
                _lblCurrent.text = [NSString stringWithFormat:@"Current Value: %.1f",fCurrent];
                _lblNew.text = [NSString stringWithFormat:@"New Value: %.1f",fNewValue];
            }
            else if (fMaximum > 0.1f){
                _lblMinimum.text = [NSString stringWithFormat:@"%.2f",fMinimum];
                _lblMaximum.text = [NSString stringWithFormat:@"%.2f",fMaximum];
                _lblCurrent.text = [NSString stringWithFormat:@"Current Value: %.2f",fCurrent];
                _lblNew.text = [NSString stringWithFormat:@"New Value: %.2f",fNewValue];
            } else{
                _lblMinimum.text = [NSString stringWithFormat:@"%.3f",fMinimum];
                _lblMaximum.text = [NSString stringWithFormat:@"%.3f",fMaximum];
                _lblCurrent.text = [NSString stringWithFormat:@"Current Value: %.3f",fCurrent];
                _lblNew.text = [NSString stringWithFormat:@"New Value: %.3f",fNewValue];
            }
            _slider.hidden = false;
            _lblMinimum.hidden = false;
            _lblMaximum.hidden = false;
            _lblCurrent.hidden = false;
            _lblNew.hidden = false;
        }
            break;
        default:
            break;
    }
    
    [super viewWillAppear:animated];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)sliderChanged:(UISlider *)sender {

    if (type == PS_REGISTRY_INT_TYPE)
    {
        iNewValue = sender.value;
        _lblNew.text = [NSString stringWithFormat:@"New Value: %i",iNewValue];
    }
    else
    {
        fNewValue = sender.value;
        if (fMaximum > 100){
            _lblNew.text = [NSString stringWithFormat:@"New Value: %.0f",fNewValue];
        }else if (fMaximum >1){
            _lblNew.text = [NSString stringWithFormat:@"New Value: %.1f",fNewValue];
        }
        else if (fMaximum > 0.1f){
            _lblNew.text = [NSString stringWithFormat:@"New Value: %.2f",fNewValue];
        } else{
            _lblNew.text = [NSString stringWithFormat:@"New Value: %.3f",fNewValue];
        }
    }
}
- (IBAction)btnSend:(UIButton *)sender {
    
    switch(type)
    {
        case PS_REGISTRY_INT_TYPE:
        {
            ps_registry_set_int([domain UTF8String], [name  UTF8String], iNewValue);
        }
            break;
        case PS_REGISTRY_REAL_TYPE:
        {
            ps_registry_set_real([domain UTF8String], [name  UTF8String], fNewValue);
        }
            break;
        default:
            break;
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)btnCancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
