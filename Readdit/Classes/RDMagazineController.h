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
  id __unsafe_unretained currentCell;
  int currentIndex;
}

@property(nonatomic) NSArray *items;
@property(nonatomic) id dataSource;
@property(nonatomic) RDBrowserController *browserController;
@property(nonatomic, unsafe_unretained) id currentCell;
@property(nonatomic, assign) int currentIndex;

@end


@interface RDMagazineColumn : UITableViewCell
{
  NSArray *imageViews, *labelViews, *smokeViews;
  id __unsafe_unretained delegate;
  SEL selectAction;
  id userData;
}

@property(nonatomic, unsafe_unretained) id delegate;
@property(nonatomic) id userData;
@property(nonatomic, assign) SEL selectAction;
@property(nonatomic, readonly) NSArray *imageViews, *labelViews, *smokeViews;

@end


@interface RDMagazineImage : UIImageView <UIGestureRecognizerDelegate>
{
  id __unsafe_unretained delegate;
  SEL touchAction;
}

@property(nonatomic, unsafe_unretained) id delegate;
@property(nonatomic, assign) SEL touchAction;

@end

