//
//  TimePlotVC.m
//  Demo
//
//  Created by Brenden West on 2/13/15.
//  Copyright (c) 2015 brisksoft. All rights reserved.
//

#import "TimePlotVC.h"
#import "Chart.h"
#import "AFNetworking.h"

@interface TimePlotVC ()

 @property (nonatomic, weak) IBOutlet UIActivityIndicatorView *loading;
 @property (nonatomic, weak) IBOutlet Chart *chart;
 @property (nonatomic, weak) IBOutlet UISegmentedControl *timeUnits;
 @property (nonatomic, weak) IBOutlet UILabel *stats1;
 @property (nonatomic, weak) IBOutlet UILabel *stats2;
 @property (nonatomic, strong) NSArray *bikeCounts;

@end

@implementation TimePlotVC

typedef NS_ENUM(NSInteger, dateUnit)
{
    month,
    day,
    year
};

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // enable pan gesture to drag chart on x-axis
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragChart:)];
    panRecognizer.maximumNumberOfTouches = 1;

    self.title = [self.counterDict objectForKey:@"title"];
    
    [self.chart addGestureRecognizer:panRecognizer];
    
    // load chart data
    [self requestData:[self.timeUnits selectedSegmentIndex]];
    
    self.stats1.textColor = [UIColor magentaColor];
    self.stats2.textColor = [UIColor greenColor];

}


#pragma mark data handling

-(void)configureData
{
    // format data for charting and display of summary stats
    self.chart.data = [NSMutableArray new];
    int i = 0;
    int max1 = 0;
    int min1 = 10000;
    int max2 = 0;
    int min2 = 10000;
    for (NSMutableDictionary *d in self.bikeCounts)
    {
        // get string to time increments
        NSString *dateStr = [self stringFromDate:[d objectForKey:@"date_str"] for:month];
        
        int value1 = [[d objectForKey:@"total_1"] intValue];
        if (value1 > max1) { max1 = value1; }
        if (value1 < min1) { min1 = value1; }
        
        int value2 = [[d objectForKey:@"total_2"] intValue];
        if (value2 > max2) { max2 = value2; }
        if (value2 < min2) { min2 = value2; }
        
        self.chart.data[i++] = @{@"x":dateStr, @"y_1":[d objectForKey:@"total_1"], @"y_2":[d objectForKey:@"total_2"]};
    }

    NSNumber *average1 = [self.bikeCounts valueForKeyPath:@"@avg.total_1"];
    NSNumber *average2 = [self.bikeCounts valueForKeyPath:@"@avg.total_2"];
    
    self.chart.columns = @[@"y_1",@"y_2"];
    self.chart.xAxis = [Axis axisWithDictionary:@{@"offset":@75, @"majorTick":@0, @"minorTick":@1, @"label":@"date", @"low":@0, @"high":@10 }];
    
    int yMax = [self roundInt:MAX(max1, max2) toNearest:100];
    int yTick = [self tickForRange:yMax];

    self.chart.yAxis = [Axis axisWithDictionary:@{@"offset":@50, @"majorTick":[NSNumber numberWithInt:yTick], @"minorTick":[NSNumber numberWithInt:yTick], @"label":@"", @"low":@0, @"high":[NSNumber numberWithInt:yMax]}];
    
    [self.chart setNeedsDisplay];
    
    // display summary statistics
    self.stats1.text = [NSString stringWithFormat:@"%@: min=%d, max=%d, avg.=%@",[[self.counterDict objectForKey:@"col_1"] objectForKey:@"title"],min1, max1, average1];
    self.stats2.text = [NSString stringWithFormat:@"%@: min=%d, max=%d, avg.=%@",[[self.counterDict objectForKey:@"col_2"] objectForKey:@"title"], min2, max2, average2];

}

-(int)roundInt:(int)value toNearest:(int)increment
{
    return increment * ceil((value/increment)+0.5);
}

-(int)tickForRange:(int)value
{
    // calculate useable increments based on range of y-values
    if (value <= 100) {
        return 10;
    }
    else if (value <= 1000) {
        return 100;
    }
    else if (value <= 5000) {
        return 500;
    }
    else if (value <= 10000) {
        return 1000;
    }
    else {
        return 5000;
    }

}

-(NSString*)stringFromDate:(NSString*)dateStr for:(dateUnit*)dateUnit
{
    // Convert input string to date object
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
    NSDate *date = [dateFormat dateFromString:dateStr];
    
    NSString *userVisibleDateTimeString;
    if (date != nil) {
        // return a formatted date string
        NSDateFormatter *userVisibleDateFormatter = [[NSDateFormatter alloc] init];
        assert(userVisibleDateFormatter != nil);
        
        [userVisibleDateFormatter setDateStyle:NSDateFormatterShortStyle];
        
        userVisibleDateTimeString = [userVisibleDateFormatter stringFromDate:date];
    }
    return userVisibleDateTimeString;
}

#pragma mark data requests

- (void)requestData:(NSInteger)timeUnit
{
    
    [self.loading startAnimating];
    self.chart.alpha = 0.5;

    // url-ecode spaces and other invalid characters
    NSString *encodedString = [[self urlForTimeUnit:timeUnit] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSURL *url = [NSURL URLWithString:encodedString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]
                                         initWithRequest:request];
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        self.bikeCounts = (NSArray *)responseObject;
        [self configureData];
        [self.loading stopAnimating];
        self.chart.alpha = 1;
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self.loading stopAnimating];
        NSLog(@"Failed: Status Code: %ld", (long)operation.response.statusCode);
    }];
    [operation start];
    
}

- (NSString*)urlForTimeUnit:(NSInteger)timeUnit
{
    
    // if timeUnit is not 0, group by day. Otherwise group by month
    NSString *unitKey = (timeUnit) ? @"ymd": @"ym";
    NSString *dataUrl = [self.counterDict objectForKey:@"dataUrl"];
    
    NSString *col_1 = [[self.counterDict objectForKey:@"col_1"] objectForKey:@"key"];
    NSString *col_2 = [[self.counterDict objectForKey:@"col_2"] objectForKey:@"key"];
    
    NSString *queryParams = [NSString stringWithFormat:@"$select=date_trunc_%@(date) AS date_str,sum(%@) AS total_1,sum(%@) AS total_2&$group=date_str",unitKey,col_1,col_2];

    return [NSString stringWithFormat:@"%@?%@",dataUrl,queryParams];
    
}

#pragma mark - input handlers

-(IBAction)onTapTimeUnit:(id)sender
{
    [self requestData:[self.timeUnits selectedSegmentIndex]];
}

-(void)dragChart:(UIPanGestureRecognizer *)recognizer
{
    CGPoint translation = [recognizer translationInView:self.chart];
    
    /*
     If drag distance >= 10% of plot width, and plot extends beyond visible frame, shift axis by 1 tick mark.
     */
    
    // calculate drag amount relative to plot frame
    CGFloat change = translation.x/(self.chart.frame.size.width-self.chart.xAxis.offset);
    if (change <= -0.1 || change >= 0.1)
    {
        int increment = (translation.x > 0) ? -1 : 1;
        NSInteger upperBound = self.chart.data.count;
        if ((increment < 0 && self.chart.xAxis.low > 0) || (increment > 0 && self.chart.xAxis.high < upperBound))
        {
            [self.chart shiftXAxisBy:increment];
            [self.chart setNeedsDisplay];
            
            // reset pan gesture starting point
            [recognizer setTranslation:CGPointMake(0, 0) inView:self.chart];
        }
    }
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [self.chart setNeedsDisplay];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
