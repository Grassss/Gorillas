/*
 * This file is part of Gorillas.
 *
 *  Gorillas is open software: you can use or modify it under the
 *  terms of the Java Research License or optionally a more
 *  permissive Commercial License.
 *
 *  Gorillas is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 *  You should have received a copy of the Java Research License
 *  along with Gorillas in the file named 'COPYING'.
 *  If not, see <http://stuff.lhunath.com/COPYING>.
 */

//
//  MainMenuLayer.m
//  Gorillas
//
//  Created by Maarten Billemont on 28/02/09.
//  Copyright 2008-2009, lhunath (Maarten Billemont). All rights reserved.
//

#import <CoreGraphics/CoreGraphics.h>
#import "MainMenuLayer.h"
#import "GorillasAppDelegate.h"
#import "PearlCCMenuItemSpacer.h"
#import "PearlCCMenuItemTitle.h"


@interface MainMenuLayer ()
@property (nonatomic, retain) CCMenu *appMenu;

@end

@implementation MainMenuLayer
@synthesize playersToInvite = _playersToInvite;
@synthesize appMenu = _appMenu;


- (id) init {

    if (!(self = [super initWithDelegate:self logo:nil items:
                  [PearlCCMenuItemSpacer spacerSmall],
#ifndef LITE
                  [multiPlayerI     = [PearlCCMenuItemBlock itemWithSize:(NSUInteger)(100.0f * [PearlDeviceUtils uiScale]) target:self selector:@selector(startMulti:)] retain],
#endif
                  [singlePlayerI    = [PearlCCMenuItemBlock itemWithSize:(NSUInteger)(100.0f * [PearlDeviceUtils uiScale]) target:self selector:@selector(startSingle:)] retain],
#ifndef LITE
                  [hotSeatI         = [PearlCCMenuItemBlock itemWithSize:(NSUInteger)(100.0f * [PearlDeviceUtils uiScale]) target:self selector:@selector(startHotSeat:)] retain],
#endif
                  [configurationI   = [CCMenuItemToggle itemWithTarget:self selector:@selector(gameConfiguration:)] retain],
                  [descriptionT     = [PearlCCMenuItemTitle itemWithString:@"description"] retain],
                  [PearlCCMenuItemSpacer spacerNormal],
#ifdef LITE
                  [PearlCCMenuItemBlock itemWithSize:(NSUInteger)(50.0f * [PearlDeviceUtils uiScale]) target:self selector:@selector(upgrade:)],
                  [PearlCCMenuItemBlock itemWithSize:(NSUInteger)(50.0f * [PearlDeviceUtils uiScale]) target:self selector:@selector(scores:)],
#else
                  [PearlCCMenuItemBlock itemWithSize:(NSUInteger)(50.0f * [PearlDeviceUtils uiScale]) target:self selector:@selector(settings:)],
                  [PearlCCMenuItemBlock itemWithSize:(NSUInteger)(50.0f * [PearlDeviceUtils uiScale]) target:self selector:@selector(scores:)],
#endif
                  nil]))
        return self;

    self.itemCounts = [NSArray arrayWithObjects:
                                       [NSNumber numberWithInt:1],
#ifdef LITE
                       [NSNumber numberWithInt:1],
#else
                       [NSNumber numberWithInt:3],
#endif
                       [NSNumber numberWithInt:1],
                       [NSNumber numberWithInt:1],
                       [NSNumber numberWithInt:1],
#ifdef LITE
                       [NSNumber numberWithInt:2],
#else
                       [NSNumber numberWithInt:2],
#endif
                       nil];
    self.layout = PearlCCMenuLayoutCustomColumns;

    self.background = [CCSprite spriteWithFile:@"menu-main.png"];

    // Game Configuration.
    NSMutableArray * configurationMenuItems = [NSMutableArray arrayWithCapacity:4];
    for (GameConfiguration *configuration in [GorillasConfig get].gameConfigurations)
        [configurationMenuItems addObject:[CCMenuItemFont itemWithString:configuration.name]];
    configurationI.subItems = configurationMenuItems;
    [configurationI setSelectedIndex:1];

    self.appMenu = [CCMenu menuWithItems:
                               [PearlCCMenuItemBlock itemWithSize:(NSUInteger)(35.0f * [PearlDeviceUtils uiScale])
                                                           target:self selector:@selector(appDeBlock:)],
                               [PearlCCMenuItemBlock itemWithSize:(NSUInteger)(35.0f * [PearlDeviceUtils uiScale])
                                                           target:self selector:@selector(appMasterPassword:)],
                               nil];
    [self.appMenu alignItemsVerticallyWithPadding:15 * [PearlDeviceUtils uiScale]];
    [self.appMenu setPosition:CGPointMake([CCDirector sharedDirector].winSize.width * 0.91f,
                                          [CCDirector sharedDirector].winSize.height / 2 - 85.0f * [PearlDeviceUtils uiScale])];

    return self;
}


- (void)reset {

    NSUInteger gameConfigurationIndex = [[GorillasConfig get].activeGameConfigurationIndex unsignedIntValue];
    GameConfiguration *gameConfiguration = [[GorillasConfig get].gameConfigurations objectAtIndex:gameConfigurationIndex];

    if ([GorillasAppDelegate get].gameLayer.running)
        [self setBackButtonTarget:self selector:@selector(back)];
    else
        [self setBackButtonTarget:nil selector:nil];

    if ([[configurationI subItems] count] > gameConfigurationIndex)
        [configurationI setSelectedIndex:gameConfigurationIndex];
    [descriptionT setString:gameConfiguration.description];
    singlePlayerI.isEnabled = gameConfiguration.singleplayerAICount;
    multiPlayerI.isEnabled = gameConfiguration.multiplayerHumanCount && [GKLocalPlayer localPlayer].authenticated;
    hotSeatI.isEnabled = gameConfiguration.multiplayerHumanCount;
}


-(void) onEnter {

    [self reset];

    [super onEnter];

    [self.parent addChild:self.appMenu];
}

- (void)onExit {

    [super onExit];

    [self.appMenu removeFromParentAndCleanup:NO];
}


-(void) startSingle: (id) sender {

    NSUInteger gameConfigurationIndex = [[GorillasConfig get].activeGameConfigurationIndex unsignedIntValue];
    GameConfiguration *gameConfiguration = [[GorillasConfig get].gameConfigurations objectAtIndex:gameConfigurationIndex];

    [[GorillasAppDelegate get].gameLayer configureGameWithMode:gameConfiguration.mode randomCity:NO
                                                     playerIDs:nil localHumans:1 ais:gameConfiguration.singleplayerAICount];
    [[GorillasAppDelegate get].gameLayer startGame];
}


-(void) startMulti: (id) sender {

#ifndef LITE
    NSUInteger gameConfigurationIndex = [[GorillasConfig get].activeGameConfigurationIndex unsignedIntValue];
    GameConfiguration *gameConfiguration = [[GorillasConfig get].gameConfigurations objectAtIndex:gameConfigurationIndex];

    if (!gameConfiguration.multiplayerHumanCount || ![GKLocalPlayer localPlayer].authenticated)
        // Multiplayer is not supported or game center is unavailable.
        return;

    GKMatchRequest *matchRequest = [[GKMatchRequest new] autorelease];
    matchRequest.minPlayers = 2;
    matchRequest.maxPlayers = gameConfiguration.multiplayerHumanCount;
    matchRequest.playerGroup = gameConfiguration.mode;
    matchRequest.playersToInvite = self.playersToInvite;

    [[GorillasAppDelegate get].netController beginRequest:matchRequest];
#endif
}


-(void) startHotSeat: (id) sender {

    NSUInteger gameConfigurationIndex = [[GorillasConfig get].activeGameConfigurationIndex unsignedIntValue];
    GameConfiguration *gameConfiguration = [[GorillasConfig get].gameConfigurations objectAtIndex:gameConfigurationIndex];

    [[GorillasAppDelegate get].gameLayer configureGameWithMode:gameConfiguration.mode randomCity:NO
                                                     playerIDs:nil localHumans:2 ais:gameConfiguration.multiplayerAICount];
    [[GorillasAppDelegate get].gameLayer startGame];
}


- (void)gameConfiguration:(id)sender {

    [GorillasConfig get].activeGameConfigurationIndex = [NSNumber numberWithUnsignedInt:
                                                         ([[GorillasConfig get].activeGameConfigurationIndex unsignedIntValue] + 1)
                                                         % [[GorillasConfig get].gameConfigurations count]];
}


- (void)upgrade:(id)sender {

    [[UIApplication sharedApplication] openURL:
     [NSURL URLWithString:@"http://itunes.apple.com/app/id302275459"]];
}


- (void)settings:(id)sender {

    [[GorillasAppDelegate get] showConfiguration];
}

- (void)scores:(id)sender {

    GKLeaderboardViewController *leaderboardController = [[[GKLeaderboardViewController alloc] init] autorelease];
    if (leaderboardController != nil) {
        leaderboardController.leaderboardDelegate = self;
        [[[UIApplication sharedApplication] keyWindow].rootViewController presentModalViewController:leaderboardController animated:YES];
        [[CCDirector sharedDirector] pause];
    }
}

- (void)leaderboardViewControllerDidFinish:(GKLeaderboardViewController *)viewController {

    [[[UIApplication sharedApplication] keyWindow].rootViewController dismissModalViewControllerAnimated:YES];
    [[CCDirector sharedDirector] resume];
}


- (void)moreGames:(id)sender {

}


- (void)back:(id) sender {

    [[GorillasAppDelegate get] popLayer];
}


- (void)appDeBlock:(id) sender {

    [[UIApplication sharedApplication] openURL:
     [NSURL URLWithString:@"http://itunes.apple.com/app/id325058485"]];
}


- (void)appMasterPassword:(id) sender {

    [[UIApplication sharedApplication] openURL:
     [NSURL URLWithString:@"http://itunes.apple.com/app/id510296984"]];
}


-(void) dealloc {

    self.appMenu = nil;
    [super dealloc];
}


@end
