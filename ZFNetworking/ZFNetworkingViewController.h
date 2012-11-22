//
//  ZFNetworkingViewController.h
//  ZFNetworking
//
//  Created by zaab on 11/20/12.
//  Copyright (c) 2012 Zampounis Filippos. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AFNetworking.h"


@interface ZFNetworkingViewController : UIViewController{
    NSArray *files;
    NSDictionary *filesDict;
    NSMutableArray *productsArray;
    NSMutableArray *resourcesArray;
    AFHTTPRequestOperation *op;
    BOOL cancelOp;
    

}

@property (nonatomic,retain)NSArray *files;
@property (nonatomic,retain)NSDictionary *filesDict;
@property (nonatomic,retain) NSMutableArray *productsArray;
@property (nonatomic,retain) NSMutableArray *resourcesArray;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;

-(IBAction)cancelPressed:(id)sender;

@end
