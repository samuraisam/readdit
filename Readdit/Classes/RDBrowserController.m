//
//  DetailViewController.m
//  Readdit
//
//  Created by Samuel Sutch on 9/5/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "RDBrowserController.h"
#import "RDRedditsController.h"


@interface RDBrowserController (PrivateParts)

@property (nonatomic, retain) UIPopoverController *popoverController;

- (void)configureView;

@end



@implementation RDBrowserController

@synthesize toolbar, popoverController, detailItem, detailDescriptionLabel, splitController;

#pragma mark -
#pragma mark Managing the detail item

- (void)setDetailItem:(id)newDetailItem 
{
  if (detailItem != newDetailItem) {
    [detailItem release];
    detailItem = [newDetailItem retain];

    [self configureView];
  }

  if (popoverController != nil) {
    [popoverController dismissPopoverAnimated:YES];
  }        
}


- (void)configureView 
{
  detailDescriptionLabel.text = [detailItem description];   
}


#pragma mark -
#pragma mark Split view support

- (void)splitViewController: (UISplitViewController*)svc 
     willHideViewController:(UIViewController *)aViewController 
          withBarButtonItem:(UIBarButtonItem*)barButtonItem 
       forPopoverController: (UIPopoverController*)pc 
{    
  barButtonItem.title = @"Root List";
  NSMutableArray *items = [[toolbar items] mutableCopy];
  [items insertObject:barButtonItem atIndex:0];
  [toolbar setItems:items animated:YES];
  [items release];
  self.popoverController = pc;
}

- (void)splitViewController: (UISplitViewController*)svc 
     willShowViewController:(UIViewController *)aViewController 
  invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem 
{    
  NSMutableArray *items = [[toolbar items] mutableCopy];
  [items removeObjectAtIndex:0];
  [toolbar setItems:items animated:YES];
  [items release];
  self.popoverController = nil;
}


#pragma mark -
#pragma mark Rotation support

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    return YES;
}


#pragma mark -
#pragma mark View lifecycle

/*
 // Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
 */

/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}
*/

- (void)viewDidUnload {
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.popoverController = nil;
}


#pragma mark -
#pragma mark Memory management

/*
- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}
*/

- (void)dealloc {
    [popoverController release];
    [toolbar release];
    
    [detailItem release];
    [detailDescriptionLabel release];
    [super dealloc];
}

@end
