//
//  AppDelegate.h
//  GBitcoinTest
//
//  Created by TokenView_GD on 2019/10/25.
//  Copyright © 2019 北京芯智引擎科技有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end

