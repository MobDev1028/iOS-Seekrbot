//
//  LocationViewController.h
//  Seekr
//
//  Created by Andy on 11/1/16.
//  Copyright (c) 2016 Seekr. All rights reserved.
//


#import "LocationViewController.h"
#import "SacredCell.h"
#import "LocationTracker.h"
#import "AttributeViewController.h"
#import "Flurry.h"

@interface LocationViewController ()<UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate>
@property IBOutlet UITableView *sacredTableView;
@property IBOutlet UITableView *attributeTableView;
@property NSMutableArray *sacredCellArray;
@property NSMutableArray *attributeCellArray;
@property IBOutlet UIScrollView *container;
@property IBOutlet UIView *sacredEntityView;
@property IBOutlet UIView *attributeView;
@property IBOutlet UIView *aboutView;
@property IBOutlet UIPageControl *pagecontrol;
@property IBOutlet UILabel *attributeTitle;


@end

@implementation LocationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _sacredCellArray = [[NSMutableArray alloc] init];
    _attributeCellArray = [[NSMutableArray alloc] init];
    

}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [Flurry logEvent:@"Seekr is running"];

}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == _sacredTableView) {
        return 6;
    }
    else
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
    if (tableView == _sacredTableView) {
        cell.sacredName.text = sacredNames[indexPath.row];
        if (indexPath.row == 0) {
            [cell.radioButtonImage setHighlighted:YES];
            sacredName = cell.sacredName.text;
            sacredName = [sacredName stringByReplacingOccurrencesOfString:[sacredName substringFromIndex:1] withString:[[sacredName substringFromIndex:1] lowercaseString]];
            
            attributeName = attributeNames[0];
        }
        [_sacredCellArray addObject:cell];

    }

    if (tableView == _attributeTableView) {
        cell.sacredName.text = attributeNames[indexPath.row];
        if (indexPath.row == 0) {
            [cell.radioButtonImage setHighlighted:YES];
            attributeName = cell.sacredName.text;
        }
        
        [_attributeCellArray addObject:cell];
        
    }

    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == _sacredTableView) {
        for (int i = 0; i < _sacredCellArray.count; i++) {
            SacredCell *cell = [_sacredCellArray objectAtIndex:i];
            [cell.radioButtonImage setHighlighted:NO];
            
            if (i == indexPath.row) {
                [cell.radioButtonImage setHighlighted:YES];
                sacredName = cell.sacredName.text;
                sacredName = [sacredName stringByReplacingOccurrencesOfString:[sacredName substringFromIndex:1] withString:[[sacredName substringFromIndex:1] lowercaseString]];

            }
        }
    }
    
    if (tableView == _attributeTableView) {
        for (int i = 0; i < _attributeCellArray.count; i++) {
            SacredCell *cell = [_attributeCellArray objectAtIndex:i];
            [cell.radioButtonImage setHighlighted:NO];
            if (i == indexPath.row) {
                [cell.radioButtonImage setHighlighted:YES];
                attributeName = cell.sacredName.text;
                
            }
        }

    }
}

#pragma mark UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGSize size = _sacredEntityView.frame.size;
    int page = scrollView.contentOffset.x / size.width;
    _pagecontrol.currentPage = page;
    
    if (page == 1) {
        _attributeTitle.text = [NSString stringWithFormat:@"what are you seeking %@", sacredName];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
