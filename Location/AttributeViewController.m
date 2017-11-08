//
//  AttributeViewController.m
//  Seekrbot
//
//  Created by Andy on 11/7/16.
//  Copyright © 2016 Seekr. All rights reserved.
//

#import "AttributeViewController.h"
#import "SacredCell.h"
#import "LocationTracker.h"

@interface AttributeViewController ()<UITableViewDelegate, UITableViewDataSource>
@property IBOutlet UITableView *tableView;
@property NSMutableArray *cellArray;
@end

//NSString *attributeNames[5] = {@"presence", @"peace", @"joy", @"strength", @"love"};

@implementation AttributeViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    _cellArray = [[NSMutableArray alloc] init];
    self.title = @"What are you in need of today?";
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];
    [self.navigationController.navigationBar setTitleTextAttributes:
     @{NSFontAttributeName:[UIFont fontWithName:@"Existence-Light" size:21]}];

}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *simpleTableIdentifier = @"SacredCell";
    
    SacredCell *cell = (SacredCell *)[tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SacredCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    
    cell.sacredName.text = attributeNames[indexPath.row];
//    if (indexPath.row == 0) {
//        [cell.radioButtonImage setHighlighted:YES];
//        attributeName = cell.sacredName.text;
//    }

    if ([attributeName isEqualToString:attributeNames[indexPath.row]]) {
        [cell.radioButtonImage setHighlighted:YES];
    }
    
    [_cellArray addObject:cell];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    for (int i = 0; i < _cellArray.count; i++) {
        SacredCell *cell = [_cellArray objectAtIndex:i];
        [cell.radioButtonImage setHighlighted:NO];
        if (i == indexPath.row) {
            [cell.radioButtonImage setHighlighted:YES];
            attributeName = cell.sacredName.text;
            
        }
    }
    
}

- (IBAction)onBack:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
