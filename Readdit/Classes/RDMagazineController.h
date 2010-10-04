//
//  RDMagazineController.h
//  Readdit
//
//  Created by Samuel Sutch on 9/26/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@class RDBrowserController;


@interface RDMagazineController : UIViewController 
<UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource>
{
  IBOutlet UIScrollView *scrollView;
  NSArray *columns;
  NSArray *items;
  NSMutableArray *reusableColums;
  UITableView *tableView;
  id<DKKeyedPool> loadingPool, cachePool;
  RDBrowserController *browserController;
  id dataSource;
  BOOL loadingMore;
  id currentCell;
  int currentIndex;
}

@property(nonatomic, retain) NSArray *items;
@property(nonatomic, retain) id dataSource;
@property(nonatomic, retain) RDBrowserController *browserController;
@property(nonatomic, assign) id currentCell;
@property(nonatomic, assign) int currentIndex;

@end


@interface RDMagazineColumn : UITableViewCell
{
  NSArray *imageViews, *labelViews, *smokeViews;
  id delegate;
  SEL selectAction;
  id userData;
}

@property(nonatomic, assign) id delegate;
@property(nonatomic, retain) id userData;
@property(nonatomic, assign) SEL selectAction;
@property(nonatomic, readonly) NSArray *imageViews, *labelViews, *smokeViews;

@end


@interface RDMagazineImage : UIImageView <UIGestureRecognizerDelegate>
{
  id delegate;
  SEL touchAction;
}

@property(nonatomic, assign) id delegate;
@property(nonatomic, assign) SEL touchAction;

@end

