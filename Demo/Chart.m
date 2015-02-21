//
//  Chart.m
//
//  Created by Brenden West on 12/1/14.
//  Copyright (c) 2014 Mirador. All rights reserved.
//

#import "Chart.h"

@interface Chart ()

@property (nonatomic) CGFloat graphTop;
@property (nonatomic) CGFloat graphHeight;
@property (nonatomic) CGFloat graphWidth;
@property (nonatomic) BOOL isPaused;

// store original boundary values of x-axis
@property (nonatomic) CGFloat originalXLow;
@property (nonatomic) CGFloat originalXHigh;

@property (nonatomic) float sampleTime; // time counter for chart auto-update

@end


// inset top and right grid lines to allow alignment with tick labels
static const CGFloat kChartMargin = 8;

@implementation Chart

#pragma mark - draw methods

- (void)drawLineGraphWithContext:(CGContextRef)context
{

    // draw chart line for data points
    CGContextSetLineWidth(context, 2.0);
    CGContextSetStrokeColorWithColor(context, [[UIColor colorWithRed:1.0 green:0.5 blue:0 alpha:1.0] CGColor]);
    CGContextBeginPath(context);
    
    int marginLeft = self.yAxis.offset;
    if (!self.startIndex) { self.startIndex = 0; }
    
    int xValue = 0;
    int lineCount = 0;
    
    for (NSString *k in self.columns)
    {
        CGContextSetStrokeColorWithColor(context, [[self lineColors][lineCount++] CGColor]);

        float yCoord = self.graphHeight - [self coordinateForValue:[[self.data[0] valueForKey:k] floatValue] withAxis:yAxis];
        
        CGContextMoveToPoint(context, marginLeft, yCoord);
        
        for (int i = self.startIndex; i < self.data.count; i++)
        {
            
    //        xValue = [[self.data[i] valueForKey:@"x"] floatValue];
            xValue = i;
            float xCoord = marginLeft + [self coordinateForValue:xValue withAxis:xAxis];
            float yCoord = self.graphHeight - [self coordinateForValue:[[self.data[i] valueForKey:k] floatValue] withAxis:yAxis];
            
            CGContextAddLineToPoint(context, xCoord, yCoord);

        }
        CGContextDrawPath(context, kCGPathStroke);
    }
    
}

- (void)drawAxis:(axisType)axisType withContext:(CGContextRef)context
{
    CGContextSetTextDrawingMode(context, kCGTextFill);
    CGContextSetFillColorWithColor(context, [[UIColor lightGrayColor] CGColor]);
    Axis *axisData = (axisType == xAxis ) ? self.xAxis : self.yAxis;
    
    int minorTick = axisData.minorTick;
    int tickCount = axisData.range/minorTick;
    int marginLeft = self.yAxis.offset;
    
    NSUInteger numDecimals = [self numberOfDecimals:minorTick];
    
    if (axisType == xAxis ) {
        
        // get x-coordinate for initial tick
        CGFloat minorTickCoord = [self coordinateForValue:(axisData.low+minorTick) withAxis:xAxis];
        
//        float scaleTick = (axisData.scaleTick) ? axisData.scaleTick : 1;
        
        // draw tick labels
        float yCoord = self.graphHeight+kChartMargin+10;
        for (int i = 0; i <= tickCount; i++)
        {
            NSString *tickText = [self.data[i] objectForKey:@"x"];
//            NSString *tickText = [self formattedNumber:(axisData.low*scaleTick + i * minorTick * scaleTick) withDecimals:numDecimals];
            UILabel *tickLabel = [self labelForText:tickText xPos:i * minorTickCoord+marginLeft yPos:yCoord width:0];
            
            // rotate labels by 45 degrees counter-clockwise
            [tickLabel setTransform:CGAffineTransformMakeRotation(-M_PI / 3)];
            [self addSubview:tickLabel];
        }
        
        UILabel *axisLabel = [self labelForText:axisData.label xPos:self.graphWidth/2 + marginLeft yPos:self.graphHeight+48 width:0];
        [self addSubview:axisLabel];
        
    }
    else if (axisType == yAxis ) {
        
        for (int i = 0; i <= tickCount; i++)
        {
            CGFloat yCoord = [self coordinateForValue:(axisData.high - i * minorTick) withAxis:yAxis];
            
            NSString *tickText = [self formattedNumber:(axisData.low + i * minorTick) withDecimals:numDecimals];
            UILabel *tickLabel = [self labelForText:tickText xPos:0 yPos:yCoord width:marginLeft-6];
            [self addSubview:tickLabel];
            
        }
        
        UILabel *axisLabel = [self labelForText:axisData.label xPos:0 yPos:self.graphHeight/2 width:0];
        
        // rotate label -90 degrees
        [axisLabel setTransform:CGAffineTransformMakeRotation(-M_PI / 2)];
        [self addSubview:axisLabel];
        
    }
    
}

- (void)drawRect:(CGRect)rect {

    int marginLeft = self.yAxis.offset;

    // calculate expected width
    int chartWidth = rect.size.width-marginLeft - kChartMargin;
    // perform one-time setup when chart first drawn or on orientation change
    if (self.graphWidth != chartWidth) {
        
        /* calculate space for drawing data points and gridlines
         kChartMargin is spacing on top and right of chart
         y-offset is horizontal spacing from rect left edge
         x-offset is vertical spacing from rect bottom
         */
        self.graphTop = rect.origin.y+kChartMargin;
        self.graphHeight = rect.size.height-marginLeft - kChartMargin;
        self.graphWidth = rect.size.width-marginLeft - kChartMargin;
        
        // retain original x-axis values to restore chart state
        self.originalXLow = self.xAxis.low;
        self.originalXHigh = self.xAxis.high;
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // set line styles lines
    CGContextSetLineWidth(context, 1.0);
    CGContextSetStrokeColorWithColor(context, [[UIColor lightGrayColor] CGColor]);
    
    // add vertical grid lines
    float majorTickX = self.xAxis.majorTick;
    if (!majorTickX) { majorTickX = self.xAxis.high; }
    
    int verticalLines = round(self.xAxis.range/majorTickX) + 1;
    
    for (int i = self.startIndex; i < verticalLines; i++)
    {
        CGFloat xCoordinate = [self coordinateForValue:(i * majorTickX) withAxis:xAxis]+marginLeft-1;
        CGContextMoveToPoint(context, xCoordinate, self.graphTop);
        CGContextAddLineToPoint(context, xCoordinate, self.graphHeight);
    }
    
    // add horizontal grid lines
    float majorTickY = self.yAxis.majorTick;
    if (!majorTickY) { majorTickY = self.yAxis.high; }
    
    int horizontalLines =  round(self.yAxis.range/majorTickY) + 1;
    
    float highY = self.yAxis.high;
    
    for (int i = 0; i < horizontalLines; i++)
    {
        CGFloat yCoordinate = [self coordinateForValue:(highY - i * majorTickY) withAxis:yAxis];
        if (yCoordinate < 0)  { yCoordinate = 0; }
        
        CGContextMoveToPoint(context, marginLeft, self.graphHeight - yCoordinate);
        CGContextAddLineToPoint(context, self.graphWidth+marginLeft, self.graphHeight - yCoordinate);
    }
    
    CGContextStrokePath(context);
    
    if (self.subviews.count > 0) {
        // remove existing axis labels to avoid redraw artefacts
        [self.subviews makeObjectsPerformSelector: @selector(removeFromSuperview)];
    }
    [self drawAxis:xAxis withContext:context];
    [self drawAxis:yAxis withContext:context];
    
    if (self.data.count > 0) {
        [self drawLineGraphWithContext:context];
    }
    
}

#pragma mark - helper methods

- (UILabel *)labelForText:(NSString *)text xPos:(int)xCoord yPos:(int)yCoord width:(int)width
{
    // configure label
    // y-axis labels need fixed width for positioning
    // vertical & x-axis labels are resized before final positioning
    
    UILabel *tmpLabel = [[UILabel alloc] initWithFrame:CGRectMake(xCoord, yCoord, width, 16)];
    tmpLabel.text = text;
    tmpLabel.font = [UIFont systemFontOfSize:12.0];
    tmpLabel.textColor = [UIColor grayColor];
    tmpLabel.textAlignment = NSTextAlignmentRight;
    if (!width) {
        [tmpLabel sizeToFit];
        tmpLabel.frame = CGRectMake(xCoord-tmpLabel.frame.size.width/2,
                                    yCoord,tmpLabel.frame.size.width,
                                    tmpLabel.frame.size.height);
    }
    
    return tmpLabel;
}

-(CGPoint)pointForX:(float)x andY:(float)y;
{
    /**
     convert x/y values for data point into screen
     coordinates for comparison with touch location.
     - touch rect includes the x-axis offset 
     - touch rect y values start from upper left, while plot coordinates start from lower left. So coordinate value has to be inverted.
    */
    CGFloat newX = self.yAxis.offset + [self coordinateForValue:x withAxis:xAxis];
    CGFloat newY = self.graphHeight - [self coordinateForValue:y withAxis:yAxis];
    
    return CGPointMake (newX, newY );
}

- (CGFloat)coordinateForValue:(CGFloat)data withAxis:(axisType)axis
{
    // convert data value to screen coordinate based on chart size and data range
    float dataRange;
    float dataLow;
    float screenRange;
    
    // convert range to absolute value
    if (axis == yAxis) {
        screenRange = self.graphHeight-kChartMargin;
        dataLow = self.yAxis.low;
        dataRange = self.yAxis.range;
    } else {
        screenRange = self.graphWidth;
        dataLow = self.xAxis.low;
        dataRange = self.xAxis.range;
    }
    
    float dataAbsPos = data-dataLow;
    float scaleFactor = (float)dataAbsPos/dataRange;
    
    return screenRange*scaleFactor;
}


- (NSUInteger)numberOfDecimals:(CGFloat)number {
    NSString *strValue = [NSString stringWithFormat:@"%f",number];
    
    // If nil, return -1
    if (!strValue) return -1;
    
    // Count digits after decimal point in original input
    NSRange range = [strValue rangeOfString:@"."];
    if (NSNotFound == range.location) return 0;
    
    // start at end of string and reduce string length for each trailing zero
    NSUInteger newLength = strValue.length-1;
    while (newLength > range.location+1) {
        if ([strValue characterAtIndex:newLength] == 48) {
            newLength--;
        } else {
            break;
        }
    }

    return newLength - range.location;
}

- (NSString*)formattedNumber:(CGFloat)number withDecimals:(NSUInteger)digits {
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [formatter setMaximumFractionDigits:digits];
    return [formatter stringFromNumber:[NSNumber numberWithFloat:number]];
    
}


-(void)reset
{
    self.data = [NSMutableArray new];
    self.startIndex = 0;
    self.sampleTime = 0;
    if (self.originalXHigh > 0) {
        self.xAxis.low = self.originalXLow;
        self.xAxis.high = self.originalXHigh;
    }
    [self rescaleByFactor:1]; // triggers a redraw

}

#pragma mark - scale chart

-(void)rescaleByFactor:(float)scaleFactor
{
    self.xAxis.high = self.xAxis.high * scaleFactor;
    self.xAxis.minorTick = [self newMinorTick:self.xAxis.range];
    [self setNeedsDisplay];
}

-(void)shiftXAxisBy:(float)increment
{
    // reset high and low axis values as chart view shifts
    self.xAxis.low += increment;
    self.xAxis.high += increment;
    self.startIndex += increment;
    self.drawOptions = 2; // redraw axes
}

-(float)newMinorTick:(float)range
{
    // set x-axis tick values as chart is scaled
    if (range >= 1000)
    {
        return round(range/10);
    }
    else if (range >= 100)
    {
        return 25;
    }
    else if (range >= 60)
    {
        return 10;
    }
    else if (range > 5)
    {
        return round(range/10);
    }
    else if (range > 2)
    {
        return 0.5;
    }
    else
    {
        return 0.2;
    }
}

-(NSArray*)lineColors
{
    return @[[UIColor magentaColor], [UIColor greenColor]];
    
}

@end
