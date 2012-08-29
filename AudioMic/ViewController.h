//
//  ViewController.h
//  AudioMic
//
//  Created by Cass Pangell on 8/28/12.
//  Copyright (c) 2012 Cass Pangell. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController : UIViewController <AVAudioPlayerDelegate, AVAudioRecorderDelegate>{
    AVAudioPlayer *audioPlayer;
    AVAudioPlayer *audioPlayerRecord;
    AVAudioRecorder *audioRecorder;
    
    //    NSMutableDictionary *recordSetting;
    //    NSString *recorderFilePath;
    
    int recordEncoding;
    
    enum
    {
        ENC_AAC = 1,
        ENC_ALAC = 2,
        ENC_IMA4 = 3,
        ENC_ILBC = 4,
        ENC_ULAW = 5,
        ENC_PCM = 6,
    } encodingTypes;
}

- (IBAction)startRecordClicked:(id)sender;
- (IBAction)stopRecordClicked:(id)sender;
- (IBAction)playRecordClicked:(id)sender;
@end
