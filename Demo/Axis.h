//
//  Axis.h
//  compassview
//
//  Created by Brenden West on 1/15/15.
//  Copyright (c) 2015 mirador. All rights reserved.
//

#import <Foundation/Foundation.h>
@interface Axis : NSObject

@property (nonatomic) int offset;
@property (nonatomic) float majorTick;
@property (nonatomic) float minorTick;
@property (nonatomic) float scaleTick;
@property (nonatomic) float low;
@property (nonatomic) float high;
@property (nonatomic, readonly) float range;
@property (nonatomic) NSString *label;

+ (Axis *)axisWithDictionary:(NSDictionary *)dictionary;

@end
