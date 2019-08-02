//
//  LBackPlayManager.h
//  Telegraph
//
//  Created by Leo on 2019/7/1.
//

#import "LBackPlayManager.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

#pragma mark -
#pragma mark MMPDeepSleepPreventer Private Interface

@interface LBackPlayManager ()
{
    NSDate *startDate;
}


- (void)playPreventSleepSound;
- (void)setUpAudioSession;

@end


@implementation LBackPlayManager


+ (LBackPlayManager *)shared
{
    static LBackPlayManager * _sharedSingleton = nil;
    @synchronized([LBackPlayManager class]){
        if (_sharedSingleton == nil) {
            _sharedSingleton = [[LBackPlayManager alloc] init];
        }
    }
    return _sharedSingleton;
}

#pragma mark -
#pragma mark Creation and Destruction

- (id)init
{
    if ( !(self = [super init]) )
        return nil;
    
    [self setUpAudioSession];
    
    NSString *soundFilePath = [[NSBundle mainBundle] pathForResource:@"Silence"
                                                              ofType:@"wav"];
    NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:soundFilePath];
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL
                                                              error:nil];
    [self.audioPlayer prepareToPlay];
    [self.audioPlayer setVolume:0.0];
    self.audioPlayer.numberOfLoops = -1;
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioSessionWasInterrupted:) name:AVAudioSessionInterruptionNotification object:nil];
    
    return self;
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark -
#pragma mark Public Methods

- (void)startPreventSleep
{
    startDate = [NSDate date];
    NSTimer *preventSleepTimer = [[NSTimer alloc] initWithFireDate:[NSDate date]
                                                          interval:20
                                                            target:self
                                                          selector:@selector(playPreventSleepSound)
                                                          userInfo:nil
                                                           repeats:YES];
    self.preventSleepTimer = preventSleepTimer;
    
    [[NSRunLoop currentRunLoop] addTimer:self.preventSleepTimer
                                 forMode:NSDefaultRunLoopMode];
    
    
    
    
}


- (void)stopPreventSleep
{
    [self.preventSleepTimer invalidate];
    self.preventSleepTimer = nil;
}


#pragma mark -
#pragma mark Private Methods

- (void)playPreventSleepSound
{
    
    //获取当前的系统时间
    NSDate *date = [NSDate date];
    //计算时间差间隔
    NSTimeInterval timeBetween = [date timeIntervalSinceDate:startDate];
    if (timeBetween >= 2.5 * 60) {
        [self.audioPlayer play];
    }
    if (timeBetween > 5*60) {//5分钟
        exit(0);
    }
}


- (void)setUpAudioSession
{
    
    NSError *categorySetError = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback
                                     withOptions:AVAudioSessionCategoryOptionMixWithOthers
                                           error:&categorySetError];
    if (categorySetError) {
//        NSLog(@"Error setting AVAudioSession category: %@", categorySetError);
    }
    
    
    NSError *activeSetError = nil;
    [[AVAudioSession sharedInstance] setActive:YES
                                         error:&activeSetError];
    
    if (activeSetError) {
//        NSLog(@"Error activating AVAudioSession: %@", activeSetError);
    }else {
        OSStatus activationResult = 0;
        activationResult          = AudioSessionSetActive(true);
        if (activationResult)
        {
//            NSLog(@"AudioSession is active");
        }
    }
    
    
    // Initialize audio session
    AudioSessionInitialize
    (
     NULL, // Use NULL to use the default (main) run loop.
     NULL, // Use NULL to use the default run loop mode.
     NULL, // A reference to your interruption listener callback function.
     // See “Responding to Audio Session Interruptions” in Apple's "Audio Session Programming Guide" for a description of how to write
     // and use an interruption callback function.
     NULL  // Data you intend to be passed to your interruption listener callback function when the audio session object invokes it.
     );
    
    // Activate audio session
    OSStatus activationResult = 0;
    activationResult          = AudioSessionSetActive(true);
    
    if (activationResult)
    {
//        NSLog(@"AudioSession is active");
    }
    
    // Set up audio session category to kAudioSessionCategory_MediaPlayback.
    // While playing sounds using this session category at least every 10 seconds, the iPhone doesn't go to sleep.
    UInt32 sessionCategory = kAudioSessionCategory_MediaPlayback; // Defines a new variable of type UInt32 and initializes it with the identifier
    // for the category you want to apply to the audio session.
    AudioSessionSetProperty
    (
     kAudioSessionProperty_AudioCategory, // The identifier, or key, for the audio session property you want to set.
     sizeof(sessionCategory),             // The size, in bytes, of the property value that you are applying.
     &sessionCategory                     // The category you want to apply to the audio session.
     );
    
    // Set up audio session playback mixing behavior.
    // kAudioSessionCategory_MediaPlayback usually prevents playback mixing, so we allow it here. This way, we don't get in the way of other sound playback in an application.
    // This property has a value of false (0) by default. When the audio session category changes, such as during an interruption, the value of this property reverts to false.
    // To regain mixing behavior you must then set this property again.
    
    // Always check to see if setting this property succeeds or fails, and react appropriately; behavior may change in future releases of iPhone OS.
    OSStatus propertySetError = 0;
    UInt32 allowMixing        = true;
    
    propertySetError = AudioSessionSetProperty
    (
     kAudioSessionProperty_OverrideCategoryMixWithOthers, // The identifier, or key, for the audio session property you want to set.
     sizeof(allowMixing),                                 // The size, in bytes, of the property value that you are applying.
     &allowMixing                                         // The value to apply to the property.
     );
    
    if (propertySetError)
    {
//        NSLog(@"Error setting kAudioSessionProperty_OverrideCategoryMixWithOthers: %d", propertySetError);
    }
}


#pragma mark - not
- (void)audioSessionWasInterrupted:(NSNotification *)notification
{
    //防止打电话和闹钟响后音乐会恢复播放，后台任务可继续运行。
    if ([notification.userInfo count] == 0)
    {
        return;
    }
    
    if (AVAudioSessionInterruptionTypeEnded == [notification.userInfo[AVAudioSessionInterruptionTypeKey] intValue])
    {
//        NSLog(@"received AVAudioSessionInterruptionTypeEnded -------------------");
        dispatch_async(dispatch_get_main_queue(), ^{
            [self startPreventSleep];
        });
    }
}

@end
