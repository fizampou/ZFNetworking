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
    NSMutableArray *productsArray;      //Will keep all the urls of the items fow download, also their hashes.It's items are dictionaries with keys url and hash.
    NSMutableArray *resourcesArray;     //Will keep the op objects.
    AFHTTPRequestOperation *op;         //all assets fow download will be  an op.
    AFHTTPClient * apiClient;           //the client that handles the items for downloading.
    NSMutableArray *productsArrayCopy;  //keeps a copy of the JSON items for download.
    NSMutableDictionary *schema;        //will hold the schema plist file.
    NSString *ZFRemoteHostUrl;          //will hold JSON link.
    
}
@property (nonatomic,retain) NSMutableArray *productsArray;
@property (nonatomic,retain) NSMutableArray *resourcesArray;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;
@property (nonatomic, retain) NSMutableArray *productsArrayCopy;
@property (nonatomic, assign) BOOL cancelButtonPressed;
@property (nonatomic,retain) IBOutlet UIImageView *backgroundView;
@property (nonatomic, retain) IBOutlet UIButton *cancelButton;

-(IBAction)cancelPressed:(id)sender;
-(void)willGoBackground;
-(void)willComeForeground;

@end
