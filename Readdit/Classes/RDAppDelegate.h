//
//  ReadditAppDelegate.h
//  Readdit
//
//  Created by Samuel Sutch on 9/5/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <UIKit/UIKit.h>


@class RDRedditsController;
@class RDBrowserController;
@class MGSplitViewController;

@interface RDAppDelegate : NSObject <UIApplicationDelegate>
{
    UIWindow *window;
    
    MGSplitViewController *splitViewController;
    
    RDRedditsController *rootViewController;
    RDBrowserController *detailViewController;
}

@property (nonatomic) IBOutlet UIWindow *window;

@property (nonatomic) IBOutlet MGSplitViewController *splitViewController;
@property (nonatomic) IBOutlet RDRedditsController *rootViewController;
@property (nonatomic) IBOutlet RDBrowserController *detailViewController;

@end
