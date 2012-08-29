//
//  ViewController.m
//  AudioMic
//
//  Created by Cass Pangell on 8/28/12.
//  Copyright (c) 2012 Cass Pangell. All rights reserved.
//

#import "ViewController.h"
#import <AudioToolbox/AudioServices.h>
@interface ViewController ()

@end

@implementation ViewController

- (IBAction)startRecordClicked:(id)sender {
    NSLog(@"start record");
    [audioRecorder release];
    audioRecorder = nil;
    
    //Initialize audio session
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryRecord error:nil];
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    
    //Override record to mix with other app audio, background audio not silenced on record
    OSStatus propertySetError = 0;
    UInt32 allowMixing = true;
    propertySetError = AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryMixWithOthers, sizeof(allowMixing), &allowMixing);
    
    UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
    AudioSessionSetProperty (kAudioSessionProperty_OverrideAudioRoute,sizeof (audioRouteOverride),&audioRouteOverride);
    
    NSLog(@"Mixing: %lx", propertySetError); // This should be 0 or there was an issue somewhere
    
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] initWithCapacity:0];
    
    if (recordEncoding == ENC_PCM) {
        [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatLinearPCM]  forKey:AVFormatIDKey];
        [recordSetting setValue:[NSNumber numberWithFloat:44100.0]              forKey:AVSampleRateKey];
        [recordSetting setValue:[NSNumber numberWithInt:2]                      forKey:AVNumberOfChannelsKey];
        
        [recordSetting setValue:[NSNumber numberWithInt:16]                     forKey:AVLinearPCMBitDepthKey];
        [recordSetting setValue:[NSNumber numberWithBool:NO]                    forKey:AVLinearPCMIsBigEndianKey];
        [recordSetting setValue:[NSNumber numberWithBool:NO]                    forKey:AVLinearPCMIsFloatKey];
    } else {
        
        NSNumber *formatObject;
        
        switch (recordEncoding) {
            case ENC_AAC:
                formatObject = [NSNumber numberWithInt:kAudioFormatMPEG4AAC];
                break;
                
            case ENC_ALAC:
                formatObject = [NSNumber numberWithInt:kAudioFormatAppleLossless];
                break;
                
            case ENC_IMA4:
                formatObject = [NSNumber numberWithInt:kAudioFormatAppleIMA4];
                break;
                
            case ENC_ILBC:
                formatObject = [NSNumber numberWithInt:kAudioFormatiLBC];
                break;
                
            case ENC_ULAW:
                formatObject = [NSNumber numberWithInt:kAudioFormatULaw];
                break;
                
            default:
                formatObject = [NSNumber numberWithInt:kAudioFormatAppleIMA4];
                break;
        }
        
        [recordSetting setValue:formatObject                                forKey:AVFormatIDKey];
        [recordSetting setValue:[NSNumber numberWithFloat:44100.0]          forKey:AVSampleRateKey];
        [recordSetting setValue:[NSNumber numberWithInt:2]                  forKey:AVNumberOfChannelsKey];
        [recordSetting setValue:[NSNumber numberWithInt:12800]              forKey:AVEncoderBitRateKey];
        
        [recordSetting setValue:[NSNumber numberWithInt:16]                 forKey:AVLinearPCMBitDepthKey];
        [recordSetting setValue:[NSNumber numberWithInt:AVAudioQualityHigh] forKey:AVEncoderAudioQualityKey];
        
    }
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *recDir = [paths objectAtIndex:0];
    NSURL *url = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/recordTest.caf", recDir]];
    
    NSError *error = nil;
    audioRecorder = [[ AVAudioRecorder alloc] initWithURL:url settings:recordSetting error:&error];
    
    if (!audioRecorder) {
        NSLog(@"audioRecorder: %@ %d %@", [error domain], [error code], [[error userInfo] description]);
        return;
    }
    
    //    audioRecorder.meteringEnabled = YES;
    //
    BOOL audioHWAvailable = audioSession.inputIsAvailable;
    if (! audioHWAvailable) {
        UIAlertView *cantRecordAlert =
        [[UIAlertView alloc] initWithTitle: @"Warning"
                                   message: @"Audio input hardware not available"
                                  delegate: nil
                         cancelButtonTitle:@"OK"
                         otherButtonTitles:nil];
        [cantRecordAlert show];
        [cantRecordAlert release];
        return;
    }
    
    if ([audioRecorder prepareToRecord]) {
        [audioRecorder record];
        NSLog(@"recording");
    } else {
        //        int errorCode = CFSwapInt32HostToBig ([error code]);
        //        NSLog(@"Error: %@ [%4.4s])" , [error localizedDescription], (char*)&errorCode);
        NSLog(@"recorder: %@ %d %@", [error domain], [error code], [[error userInfo] description]);
    }
}

- (IBAction)stopRecordClicked:(id)sender {
    
    NSLog(@"Stop recording");
    [audioRecorder stop];
    
    if (audioPlayer) [audioPlayer stop];
    
}

- (IBAction)playRecordClicked:(id)sender {
    NSLog(@"play Record");
    if (audioPlayerRecord) {
        if (audioPlayerRecord.isPlaying) [audioPlayerRecord stop];
        else [audioPlayerRecord play];
        
        return;
    }
    
    //Initialize playback audio session
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *recDir = [paths objectAtIndex:0];
    NSURL *url = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/recordTest.caf", recDir]];
    
    NSError *error;
    audioPlayerRecord = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    [audioPlayerRecord play];
    NSLog(@"Recoder file >");
}

#pragma mark -
- (void)viewDidLoad
{
    [super viewDidLoad];

    recordEncoding = ENC_PCM;

#pragma mark - GUI
    UIImageView* imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 460)];
    imgView.image = [UIImage imageNamed:@"background.jpeg"];
    [self.view addSubview:imgView];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(10, 50, 300, 40)];
    title.text = @"All your audio belong to us.";
    UIFont *myFont = [ UIFont fontWithName: @"ArialBold-MT" size: 20.0];
    title.font = myFont;
    [title setTextAlignment:UITextAlignmentCenter];
    [title setBackgroundColor:[UIColor clearColor]];
    [title setTextColor:[UIColor whiteColor]];
    [self.view addSubview:title];
    
    UIButton *startButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    startButton.frame = CGRectMake(84, 150, 155, 50);
    [startButton setTitle:@"Start Recording" forState:UIControlStateNormal];
    [startButton addTarget:self action:@selector(startRecordClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:startButton];
    
    UIButton *stopButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    stopButton.frame = CGRectMake(84, 250, 155, 50);
    [stopButton setTitle:@"Stop Recording" forState:UIControlStateNormal];
    [stopButton addTarget:self action:@selector(stopRecordClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:stopButton];
    
    UIButton *playbackButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    playbackButton.frame = CGRectMake(62, 375, 200, 50);
    [playbackButton setTitle:@"Playback" forState:UIControlStateNormal];
    [playbackButton addTarget:self action:@selector(playRecordClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:playbackButton];

    
}

- (void)dealloc {
    [super dealloc];
    
    [audioPlayer release];
    [audioRecorder release];
    [audioPlayerRecord release];
}

#pragma mark - AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    [player release];
}

#pragma mark - AVAudioRecorderDelegate

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *) aRecorder successfully:(BOOL)flag
{
    NSLog (@"audioRecorderDidFinishRecording:successfully:");
    
}


@end