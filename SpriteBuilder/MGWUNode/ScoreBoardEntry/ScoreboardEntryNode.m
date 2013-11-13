//
//  ScoreboardEntryNode.m
//  _MGWU-SideScroller-Template_
//
//  Created by Benjamin Encz on 5/16/13.
//  Copyright (c) 2013 MakeGamesWithUs Inc. Free to use for all purposes.
//

#import "ScoreboardEntryNode.h"

@implementation ScoreboardEntryNode {
    CCSprite *_scoreIcon;
}

@synthesize score = _score;

- (id)init {
    return [self initWithScoreImage:@"coin.png" fontFile:@"avenir.fnt"];
}

- (id)initWithScoreImage:(NSString *)scoreImage fontFile:(NSString *)fontFile
{
    self = [super init];
    
    if (self)
    {        
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        
        [[CCFileUtils sharedFileUtils] setBundle:bundle];
        
        self.scoreStringFormat = @"%d";
        _scoreLabel = [CCLabelBMFont labelWithString:@"" fntFile:fontFile];
        _scoreLabel.string = [NSString stringWithFormat:_scoreStringFormat, _score];
        _scoreLabel.anchorPoint = ccp(0,0.5);
        [self addChild:_scoreLabel];
        
        self.scoreAnimationSteps = 3;
        
        if (scoreImage)
        {
            _scoreIcon = [CCSprite spriteWithFile:scoreImage];
            [self addChild:_scoreIcon];
            _scoreIcon.position = ccp(_scoreIcon.position.x, _scoreLabel.position.y);
            
            // move the score label to the right of the icon
            _scoreLabel.position = ccp(_scoreLabel.position.x + _scoreIcon.contentSize.width, _scoreLabel.position.y);
        }
        
        [[CCFileUtils sharedFileUtils] setBundle:[NSBundle mainBundle]];
//        [self scheduleUpdate];
//        [self pauseSchedulerAndActions];
    }
    
    return self;
}

- (void)setScore:(NSNumber*)score {
    _score = score;
    
    _displayScore = score;
    _scoreLabel.string = [NSString stringWithFormat:_scoreStringFormat, [score intValue]];
}


- (void)setSpriteFrame:(CCSpriteFrame *)spriteFrame {
    if (spriteFrame != nil) {
        _scoreIcon.spriteFrame = spriteFrame;
    } else {
        CCSpriteFrame *spriteFrame = [CCSpriteFrame frameWithImageNamed:@"coin.png"];
        _scoreIcon.spriteFrame = spriteFrame;
    }
}

- (CCSpriteFrame *)spriteFrame {
    return _scoreIcon.spriteFrame;
}

//- (void)update:(ccTime)delta {
//    _timeElapsed += delta;
//    
//    if ( (_displayScore != _score) && (_timeElapsed >= 0.02f))
//    {
//        _timeElapsed = 0.f;
//        
//        if (_displayScore < _score)
//        {
//            _displayScore += self.scoreAnimationSteps;
//            
//            if (_displayScore > _score)
//            {
//                _displayScore = _score;
//            }
//        } else if (_displayScore > _score)
//        {
//            _displayScore -= self.scoreAnimationSteps;
//
//            if (_displayScore < _score)
//            {
//                _displayScore = _score;
//            }
//        }
//        
//        _scoreLabel.string = [NSString stringWithFormat:_scoreStringFormat, _displayScore];
//    } else if (_displayScore == _score)
//    {
//        //[self pauseSchedulerAndActions];
//    }
//}

@end
