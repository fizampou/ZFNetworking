//
//  ZFNetworkingViewController.m
//  ZFNetworking
//
//  Created by zaab on 11/20/12.
//  Copyright (c) 2012 Zampounis Filippos. All rights reserved.
//

#import "ZFNetworkingViewController.h"

#define ZFREMOTEHOST @"http://endoman.customedialabs.com/endomanjsongenerator.aspx"

@interface ZFNetworkingViewController ()

@end

@implementation ZFNetworkingViewController
@synthesize files;
@synthesize filesDict;
@synthesize productsArray;
@synthesize resourcesArray;
@synthesize progressView;
@synthesize progressLabel;


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    cancelOp = NO;
    
    self.productsArray = [NSMutableArray array];
    self.resourcesArray = [NSMutableArray array];
    //getting the main JSON FILE ON A DICTIONARY
    self.filesDict = [[NSDictionary alloc]init];
    NSURL *url = [[NSURL alloc]initWithString:ZFREMOTEHOST];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSDictionary *jsonDict = (NSDictionary *) JSON;
        NSArray *products = [jsonDict objectForKey:@"products"];
        [products enumerateObjectsUsingBlock:^(id obj,NSUInteger idx, BOOL *stop){
            //getting the products links on productsArray
            [self.productsArray addObject:[obj objectForKey:@"icon_url"]];
            [self.productsArray addObject:[obj objectForKey:@"thumbnail_url"]];
        }];
        
        NSArray *resources = [jsonDict objectForKey:@"resources"];
        [resources enumerateObjectsUsingBlock:^(id obj,NSUInteger idx,BOOL *stop){
            //getting the product_categories links on product_categoriesArray
            [self.productsArray addObject:[obj objectForKey:@"file_url"]];
            [self.productsArray addObject:[obj objectForKey:@"thumbnail_url"]];
            
        }];
       [self parser];
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) { NSLog(@"Request Failure Because %@",[error userInfo]); }];
    
    [operation start];
 
    
        
    
}

-(void)parser{
    
    for (NSString *element in self.productsArray) {
        if (!cancelOp) {
            NSURL *url = [NSURL URLWithString:element];
            NSURLRequest *request = [NSURLRequest requestWithURL:url];
            
            
            op = [[AFHTTPRequestOperation alloc] initWithRequest:request];
            
            NSString *documentsDirectory = nil;
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            documentsDirectory = [paths objectAtIndex:0];
            
            NSString *targetFilename = [url lastPathComponent];
            NSString *targetPath = [documentsDirectory stringByAppendingPathComponent:targetFilename];
            
            op.outputStream = [NSOutputStream outputStreamToFileAtPath:targetPath append:NO];
            
            [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSLog(@"ZaaB  File Saved %@", targetPath);
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                //failure case
                NSLog(@"BaaZ  File NOT Saved %@", targetPath);
            }];
            
            [op setDownloadProgressBlock:^(NSInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
                if (totalBytesExpectedToRead > 0) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.progressView.alpha = 1;
                        self.progressView.progress = (float)totalBytesRead / (float)totalBytesExpectedToRead;
                        NSString *label = [NSString stringWithFormat:@"Downloaded %lld of %lld bytes", totalBytesRead,totalBytesExpectedToRead];
                        self.progressLabel.text = label;
                    });
                }
            }];
            
            [self.resourcesArray addObject:op];
            [op start];
            
        }
        
    }
}

-(IBAction)cancelPressed:(id)sender{
    //we loop through the operations and cancel them
    //we don't have a global queue but an array of request operations.
    cancelOp=YES;
    for (AFHTTPRequestOperation *ap in self.resourcesArray) {
        //[ap.outputStream close];
        if (ap.isExecuting) {
            [ap waitUntilFinished];
        }else{
            [ap cancel];
        }
    }
}






- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
