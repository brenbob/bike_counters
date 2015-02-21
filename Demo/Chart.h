//
//  Chart.h
//  compassview
//
//  Created by Brenden West on 12/1/14.
//  Copyright (c) 2014 Mirador. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Axis.h"

@interface Chart : UIView

typedef NS_ENUM(NSInteger, axisType)
{
    xAxis,
    yAxis
};

// options for marking points on the chart line
typedef NS_OPTIONS(NSInteger, markPoints)
{
    none,
    values,
    notations
};

typedef NS_OPTIONS(NSUInteger, DrawOptions) {
    kDrawGrid     = 1 << 0,
    kDrawAxes     = 1 << 1
};

@property (nonatomic, readwrite) NSMutableArray *data;
@property (nonatomic, readwrite) NSInteger markPoints;
@property (nonatomic, readwrite) BOOL drawOptions;
@property (nonatomic, readwrite) int startIndex;
@property (nonatomic, readwrite) NSArray *columns;

// chart axes
@property (nonatomic, readwrite) Axis *xAxis;
@property (nonatomic, readwrite) Axis *yAxis;


-(void)reset;
-(void)drawLineGraphWithContext:(CGContextRef)context;
-(void)shiftXAxisBy:(float)increment;
-(void)rescaleByFactor:(float)scaleFactor;
-(CGPoint)pointForX:(float)x andY:(float)y;

@end
