//
//  Axis.m
//  compassview
//
//  Created by Brenden West on 1/15/15.
//  Copyright (c) 2015 mirador. All rights reserved.
//

#import "Axis.h"

@implementation Axis

+ (Axis *)axisWithDictionary:(NSDictionary *)dictionary
{
    Axis *axis = [Axis new];
    axis.label = dictionary[@"label"];
    axis.offset = [dictionary[@"offset"] floatValue];
    if (!axis.offset)
    {
        axis.offset = ([axis.label length] > 0) ? 44 : 26;
    }
    axis.majorTick = [dictionary[@"majorTick"] floatValue];
    axis.minorTick = [dictionary[@"minorTick"] floatValue];
    axis.scaleTick = [dictionary[@"scaleTick"] floatValue];
    axis.low = [dictionary[@"low"] floatValue];
    axis.high = [dictionary[@"high"] floatValue];
    
    return axis;
}

-(float)range
{
    return self.high - self.low;
}

@end
