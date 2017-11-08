//
//  BackgroundTaskManager.h
//  Seekr
//
//  Created by Andy on 11/1/16.
//  Copyright (c) 2016 Seekr. All rights reserved.
//


#import <Foundation/Foundation.h>

@interface BackgroundTaskManager : NSObject

+(instancetype)sharedBackgroundTaskManager;

-(UIBackgroundTaskIdentifier)beginNewBackgroundTask;
-(void)endAllBackgroundTasks;

@end
