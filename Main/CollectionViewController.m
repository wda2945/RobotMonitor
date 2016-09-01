//
//  CollectionViewController.m
//  Monitor
//
//  Created by Martin Lane-Smith on 4/13/14.
//  Copyright (c) 2014 Martin Lane-Smith. All rights reserved.
//

#import "CollectionViewController.h"
#import "MasterViewController.h"


@interface CollectionViewController () {
    
    UIViewController *currentController;
    
    CGRect startFrame;
}

@end

@implementation CollectionViewController

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
    // Do any additional setup after loading the view.
    self.definesPresentationContext = YES;

    UIViewController *vc =[[MasterViewController getMasterViewController].viewControllers objectForKey:@"List"];
    [self addChildViewController: vc];
    
    startFrame = self.view.bounds;
    startFrame.origin.x += startFrame.size.width;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self firstView: @"List"];
    });
    
}

- (void) addViewController: (UIViewController*) controller
{
    [self addChildViewController: controller];
}

- (void) firstView: (NSString*) name
{
    UIViewController *vc = [[MasterViewController getMasterViewController].viewControllers objectForKey:name];
    
    if (vc)
    {
        CGRect rect = self.view.bounds;
        vc.view.frame = rect;
        [self.view addSubview: vc.view];
        currentController = vc;
    }
}
- (bool) presentView: (NSString*) name
{
    UIViewController *controller = [[MasterViewController getMasterViewController].viewControllers objectForKey:name];
    if (controller && controller != currentController) {        
        
        controller.title = name;
        controller.view.frame = startFrame;
       
        [self transitionFromViewController: currentController toViewController: controller 
                                  duration: 0.25 options:0
                                animations:^{
                                    controller.view.frame = self.view.bounds;
                                }
                                completion:nil];
        currentController = controller;
        return YES;
    }
    else return NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Split view

//- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
//{
//    barButtonItem.title = NSLocalizedString(@"Monitor", @"Monitor");
//    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
//    self.masterPopoverController = popoverController;
//}
//- (BOOL)splitViewController:(UISplitViewController *)svc shouldHideViewController:(UIViewController *)vc inOrientation:(UIInterfaceOrientation)orientation
//{
//    if (vc == [MasterViewController getMasterViewController])
//        return YES;
//    else
//        return NO;
//}
//- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
//{
//    // Called when the view is shown again in the split view, invalidating the button and popover controller.
//    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
//    self.masterPopoverController = nil;
//}
//

@end
