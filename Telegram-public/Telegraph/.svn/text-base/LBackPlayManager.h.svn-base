//
//  LBackPlayManager.h
//  Telegraph
//
//  Created by Leo on 2019/7/1.
//

#import <Foundation/Foundation.h>

@class AVAudioPlayer;


@interface LBackPlayManager : NSObject


#pragma mark -
#pragma mark Properties

@property (nonatomic, retain) AVAudioPlayer *audioPlayer;
@property (nonatomic, retain) NSTimer       *preventSleepTimer;

#pragma mark -
#pragma mark Public Methods

+ (LBackPlayManager *)shared;

- (void)startPreventSleep;
- (void)stopPreventSleep;

@end

