//
//  DemoTests.m
//  DemoTests
//
//  Created by Brenden West on 2/13/15.
//  Copyright (c) 2015 brisksoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "AppDelegate.h"
#import "MainVC.h"


@interface MainTests : XCTestCase {

    UIView *mainView;
}

@property (nonatomic) MainVC *mainVC;

@end

@interface MainVC (Test)

    - (NSArray *)loadConfig;

@end

@implementation MainTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.mainVC = [MainVC new];

}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void) testMainView {
    // setup
    mainView             = self.mainVC.view;
    
    XCTAssertNotNil(mainView, @"Cannot find mainView instance");
    // no teardown needed
}

- (void) testConfigFile {
//    self.mainVC = [MainVC new];
    NSArray *config = [self.mainVC loadConfig];
    

    XCTAssertNotNil(config, @"Cannot find config array instance");
    XCTAssertGreaterThan(config.count, 1, @"Config array missing values");
    
    for (NSDictionary *d in config) {
        XCTAssertNotNil([d objectForKey:@"dataUrl"], @"Missing data url");
        XCTAssertNotNil([[d objectForKey:@"col_1"] objectForKey:@"key"], @"Missing key for col_1 ");
        XCTAssertNotNil([[d objectForKey:@"col_2"] objectForKey:@"key"], @"Missing key for col_2 ");
    }
    
    // no teardown needed
}


- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
