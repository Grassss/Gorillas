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
//  PanningLayer.h
//  Gorillas
//
//  Created by Maarten Billemont on 15/02/09.
//  Copyright, lhunath (Maarten Billemont) 2008. All rights reserved.
//

#import "Resettable.h"
#import "MovingTo.h"


@interface PanningLayer : CCLayer <Resettable> {

@private
    CGFloat initialScale;
    CGFloat initialDist;
    AutoTween *tween;
}

-(void) scaleTo:(CGFloat)newScale;
-(void) scaleTo:(CGFloat)newScale limited:(BOOL)limited;
-(void) scrollToCenter:(CGPoint)r horizontal:(BOOL)horizontal;

@end
