//
//  ViewController.m
//  AKNetworkOperations
//
//  Created by Anand A. Kore on 17/9/15.
//  Copyright © 2015 Anand Kore. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property(strong,nonatomic)NSMutableArray *arrTest;
@end

typedef enum : NSUInteger {
    GET_Example,
    POST_Example,
    POST_With_SOAP_Example,
} requestType;

@implementation ViewController

#pragma mark- Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"viewDidLoad");
    
   //--- Initialise array.
    _arrTest=[[NSMutableArray alloc] initWithObjects:@"GET_Example",@"POST_Example",@"POST_With_SOAP_Example", nil];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark- UITableView Delegate methods
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _arrTest.count;
}
-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID=@"CellID";
    UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell)
    {
        cell=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    }
    cell.textLabel.text=_arrTest[indexPath.row];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"didSelectRowAtIndexPath :%@",_arrTest[indexPath.row]);
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self sendRequest:indexPath.row];
}

#pragma mark- AKNetworkOperations Methods
-(void)sendRequest:(requestType)type
{
    NSURL *serviceURL=[NSURL URLWithString:[NSString stringWithFormat:@"YourURL"]];

    NSMutableDictionary *dictPara=[[NSMutableDictionary alloc]init];
    [dictPara setValue:@"PARA_1_VALUE" forKey:@"PARA_1_KEY"];
    [dictPara setValue:@"PARA_2_VALUE" forKey:@"PARA_2_KEY"];
    [dictPara setValue:@"PARA_3_VALUE" forKey:@"PARA_3_KEY"];
    [dictPara setValue:@"PARA_4_VALUE" forKey:@"PARA_4_KEY"];
    //NSLog(@"WebService :\n%@\n%@",serviceURL,dictPara);
        
    switch (type)
    {
        case GET_Example:
            /*   This is simple GET kind of method and will return response in delegate method.     */
            [[NetworkOperations sharedInstance]sendRequestWithURL:serviceURL parameters:dictPara parameterType:PARA_TYPE_STRING HttpMethod:GET_METHOD taskType:DATA_TASK uploadData:nil inBackground:NO userInfo:@"Anthing that you want back in delegate response method." delegate:self];
            break;
            
        case POST_Example:
            /*   This uses POST kind of method and will append parameter data in JSON format, and return response in delegate method.     */
            [[NetworkOperations sharedInstance]sendRequestWithURL:serviceURL parameters:dictPara parameterType:PARA_TYPE_JSON HttpMethod:POST_METHOD taskType:DATA_TASK uploadData:nil inBackground:NO userInfo:@"Anthing that you want back in delegate response method." delegate:self];
            break;
            
        case POST_With_SOAP_Example:
            /*   This uses POST kind of method and will append parameter data in SOAP format, and return response in delegate method.     */
            [[NetworkOperations sharedInstance]sendRequestWithURL:serviceURL parameters:dictPara parameterType:PARA_TYPE_SOAP HttpMethod:POST_METHOD taskType:DATA_TASK uploadData:nil inBackground:NO userInfo:@"Anthing that you want back in delegate response method." delegate:self];
            break;
            
        default:
            NSLog(@"Invalid Type.");
            break;
    }
}

-(void)akNetworkOperationDidFinishRequestWithResponse:(NSMutableDictionary *)response error:(NSError *)error
{
    NSString *strRes=[NSString stringWithFormat:@"Response :%@\nError :%@",[response valueForKey:AK_Response_JSON],error.localizedDescription];
    NSLog(@"Response :%@\nError :%@",[response valueForKey:AK_Response_JSON],error.localizedDescription);
    
    UIAlertController *alert=[UIAlertController alertControllerWithTitle:@"Response" message:strRes preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [alert dismissViewControllerAnimated:alert completion:nil];
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
    
}


@end
