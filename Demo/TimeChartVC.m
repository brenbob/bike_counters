//
//  TimeChartVC.m
//  compassview
//
//  Created by Brenden West on 12/30/14.
//  Copyright (c) 2014 mirador. All rights reserved.
//

#import "TimeChartVC.h"
#import "Chart.h"
#import "BTManager.h"
#import "SampleData.h"
#import "Common.h"
#import "Export.h"

@interface TimeChartVC ()

@property (nonatomic, weak) IBOutlet Chart *chartTime;
@property (nonatomic, weak) IBOutlet UISegmentedControl *controls;

@property (nonatomic, weak) IBOutlet UIView *notesView;
@property (nonatomic, weak) IBOutlet UITextView *notes;
@property (nonatomic) NSInteger editItem;

@property (nonatomic, strong) BTManager  *bt;
@property (nonatomic, strong) Export  *exporter;

@property (nonatomic) CGFloat previousHighX;

@end

@implementation TimeChartVC

// chart scale boundaries
static float minX = 1;
static float maxX = 240;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // instance settings for pressure-by-time chart
    self.chartTime.xAxis = [Axis axisWithDictionary:@{@"offset":@44, @"majorTick":@0, @"minorTick":@1, @"label":@"TIME (sec)", @"low":@0, @"high":@10 }];
    
    self.chartTime.yAxis = [Axis axisWithDictionary:@{@"majorTick":@5, @"minorTick":@5, @"label":@"PRESSURE (cmH20)", @"low":@-30, @"high":@30 }];
    self.chartTime.markPoints = notations;
    self.previousHighX = 10;
    
    self.bt = [BTManager instance];
    self.chartTime.data = [NSMutableArray new];
    
    [Common addBorder:self.notesView];
    
    // enable pinch gesture to scale chart
    UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(scaleChart:)];
    [pinchRecognizer setDelegate:self];
    [self.view addGestureRecognizer:pinchRecognizer];

    // enable pan gesture to drag chart on x-axis
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragChart:)];
    panRecognizer.maximumNumberOfTouches = 1;
    [self.chartTime addGestureRecognizer:panRecognizer];

    // enable tap gesture for editing of chart annotations
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapChart:)];
    [self.chartTime addGestureRecognizer:tapRecognizer];

    // notification handler for case where app enters background
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(viewWillDisappear:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(noPeripheralConnection) name:@"lostPeripheralConnection" object:nil];

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:NO];
    // need this method to balance viewWillDisappear call when app is paused
    NSLog(@"viewWillAppear - %@",self.class);
}

- (void)viewWillDisappear:(BOOL)animated
{
    NSLog(@"viewWillDisappear - %@",self.class);

    // pause data reception and reset play/pause button
    [self pauseChart];
    [super viewWillDisappear:animated];
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    // set graphHeight=0 to trigger update of chart dimensions
    [self.chartTime setNeedsDisplay];
    
    // disable tab bar while in landscape orientation to prevent navigation to screens
    // without landscape design
    self.tabBarController.tabBar.userInteractionEnabled = (size.width < 400);
}

#pragma mark - notification handler

-(void)noPeripheralConnection
{
    [self pauseChart];
}

#pragma mark - chart gestures

-(void)scaleChart:(id)sender {
    
    CGFloat pinchScale = [(UIPinchGestureRecognizer*)sender scale];
    
    // velocity sign indicates zoom direction. Negative value means increasing axis scale
    CGFloat pinchVelocity = [(UIPinchGestureRecognizer*)sender velocity];
    CGFloat xHigh = self.chartTime.xAxis.high;
    
    // scale chart only witin min/max boundaries
    if ((xHigh >= minX && xHigh <= maxX) || (xHigh >= maxX && pinchVelocity > 0) || (xHigh <= minX && pinchVelocity < 0)) {
        
        /* 
         - Multiply diff. between current and original scale by 1/20 to reduce scale sensitivity
         - If reversing direction, use reciprocal of recognized scale.
         - Axis scaling is reverse of zoom effect - zooming out reduces range of values shown on axis and magnifies plot.
         */
        CGFloat scaleFactor = 1+0.05*(1-pinchScale);
        if ((pinchScale > 1.0 && pinchVelocity < 0) || (pinchScale <= 1.0 && pinchVelocity > 0))
        {
            scaleFactor = 1/scaleFactor;
        }
        
        [self.chartTime rescaleByFactor:scaleFactor];

    }

}

-(void)dragChart:(UIPanGestureRecognizer *)recognizer
{
    CGPoint translation = [recognizer translationInView:self.chartTime];
    
    /*
     If drag distance >= 10% of plot width, and plot extends beyond visible frame, shift axis by 1 tick mark.
    */
    
    // calculate drag amount relative to plot frame
    CGFloat change = translation.x/(self.chartTime.frame.size.width-self.chartTime.xAxis.offset);
    if (change <= -0.1 || change >= 0.1)
    {
        int increment = (translation.x > 0) ? -1 : 1;
        if ((increment < 0 && self.chartTime.xAxis.low > 0) || (increment > 0 && self.chartTime.xAxis.high < self.chartTime.data.count/updatesPerSecond))
        {
            [self.chartTime shiftXAxisBy:increment];
            [self.chartTime setNeedsDisplay];
            
            // reset pan gesture starting point
            [recognizer setTranslation:CGPointMake(0, 0) inView:self.chartTime];
        }
    }
}

-(void)tapChart:(UITapGestureRecognizer *)recognizer
{
    CGPoint point = [recognizer locationInView:self.chartTime];

    // create 20x20 bounding box with tapped point at center
    CGRect box = CGRectMake ( point.x-10, point.y-10, 20.0, 20.0 );
    
    NSArray *chartData = self.chartTime.data;

    for (int i =0; i < chartData.count; i++)
    {
        if (![chartData[i][@"notes"] isEqualToString:@""]) {
            CGPoint marker = [self.chartTime pointForX:[chartData[i][@"x"] floatValue] andY:[chartData[i][@"y"] floatValue]];
            if (CGRectContainsPoint(box,marker)) {
                [self showNotes:i];
            }
        }
        
    }    
}


#pragma mark user input

-(IBAction)onTapControls:(id)sender
{
    UISegmentedControl *control = (UISegmentedControl*)sender;
    switch (control.selectedSegmentIndex)
    {
        case 0: // play or pause chart display
        {
            if ([[control imageForSegmentAtIndex:0] isEqual:[UIImage imageNamed:@"icon_play"]] && self.bt.state == Ready)
            {
                // TODO: add handler for device data
                [self.chartTime startAutoUpdate];
                [control setImage:[UIImage imageNamed:@"icon_pause"] forSegmentAtIndex:0];
            } else
            {
                [self pauseChart];
            }
            break;
        }
        case 1: // annotate chart data
        {
            [self pauseChart];
            if (self.chartTime.data.count > 0) {
                [self showNotes:self.chartTime.data.count-1];
            }
            break;
        }
        case 2:// take screenshot of chart
        {
            [Export saveImageOfView:self.chartTime];
            break;
        }
        case 3: // export data
        {
            [self pauseChart];
            [self sendMail];
            break;
        }
        case 4: // toggle chart scale
        {
            CGFloat currentHighX = self.chartTime.xAxis.high;
            if (currentHighX != self.previousHighX) {
                // toggle chart scale between original and last changed
                CGFloat scaleFactor = (float)self.previousHighX/currentHighX;
                self.previousHighX = currentHighX;
                [self.chartTime rescaleByFactor:scaleFactor];
            }
            break;
        }

    }
    // reset control to allow touch event on same segment
    control.selectedSegmentIndex = -1;
    
}

-(void)pauseChart
{
    [self.chartTime pauseAutoUpdate]; // BT data paused here
    [self.controls setImage:[UIImage imageNamed:@"icon_play"] forSegmentAtIndex:0];

}

#pragma mark export methods

- (void)sendMail
{
    [self exportChartData];
    self.exporter = [[Export alloc] init];
    self.exporter.callingController = self;
    [self.exporter composeEmail];
}

- (void)exportChartData
{
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];

    // compile data as tab-delimited string
    NSMutableString *dataAsTsv = [NSMutableString stringWithFormat:@"Patient: %@",[settings objectForKey:@"currentPatientID"]];
    
    [dataAsTsv appendFormat:@"\nDate:\t%@\n",[Common dateTimeFull]];
    [dataAsTsv appendString:@"\ntime\tpressure\tnotes"];
    
    // write each chart data point to string
    for (NSUInteger i=0; i<self.chartTime.data.count; i++ ) {
        NSDictionary *item = [self.chartTime.data objectAtIndex:i];
        [dataAsTsv appendFormat:@"\n\"%@\"\t%@\t\"%@\"",
         [item valueForKey:@"x"],
         [item valueForKey:@"y"],
         [item valueForKey:@"notes"]
         ];
    }
    
    NSString *fileName = [NSString stringWithFormat:@"%@/%@_thora_data.tsv", [settings objectForKey:@"currentPatientID"], [Common userDocumentsPath]];
    
    BOOL success = [dataAsTsv writeToFile:fileName
              atomically:NO
                encoding:NSStringEncodingConversionAllowLossy
                   error:nil];
    
    NSError *error;
    if (!success) {
        NSLog(@"Error %@ while writing to file %@", [error localizedDescription], fileName );
    }

}

#pragma mark - annotation

-(IBAction)showNotes:(NSInteger)item
{
    // show notes field, if currently hidden
    self.notesView.hidden = !self.notesView.hidden;
    
    // disable controls while notes field is visible
    self.controls.enabled = !self.controls.enabled;
    
    // because textfield was closed, save entry for associated data point
    if (self.notesView.hidden)
    {
        // when user closes the editing view, reference the item currently being edited
        item = self.editItem;
        self.chartTime.data[item][@"notes"] = self.notes.text;
        [self.chartTime setNeedsDisplay];
        self.notes.text = @""; // clear text field
        [self.view endEditing:YES];
    }
    else
    {
        // store current item index for re-use when closing view
        self.editItem = item;
        self.notes.text = self.chartTime.data[item][@"notes"];
        [self.notes becomeFirstResponder];
    }
}

#pragma mark - orientation

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}


@end
