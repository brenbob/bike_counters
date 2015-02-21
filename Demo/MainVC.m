//
//  MainVC.m
//  Demo
//
//  Created by Brenden West on 2/13/15.
//  Copyright (c) 2015 brisksoft. All rights reserved.
//

#import "MainVC.h"
#import "TimePlotVC.h"

@interface MainVC ()

@property (nonatomic, strong) NSArray *config;

@end

@implementation MainVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
  
    // load configuration file and sort alphabetically for table display
    NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES];
    self.config = [[self loadConfig] sortedArrayUsingDescriptors:@[sd]];
    
}

-(NSArray*)loadConfig
{
    NSString *configFilePath = [[NSBundle mainBundle] pathForResource:@"config" ofType:@"plist"];
    
    return [NSArray arrayWithContentsOfFile:configFilePath];
}


#pragma mark - UITableViewController

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
    cell.textLabel.text = self.config[indexPath.row][@"title"];
    
    return cell;
}
-(NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.config.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier: @"showChart" sender:indexPath];
}


#pragma mark - segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showChart"]) {
        
        NSIndexPath *indexPath = (NSIndexPath*)sender;
        
        TimePlotVC *vc = segue.destinationViewController;
        vc.counterDict = self.config[indexPath.row];
        
    }
}


@end
