# AKNetworkOperations#
AKNetworkOperation provides easy way to request web services and handle response in simple way. It offers multiple kind of request types and data parsers like XML and JSON etc.


##Usage##

**Step 1 :**
>#import "NetworkOperations.h"\n

>**Step 2 :** Define delegate \n
>@interface ViewController : UIViewController<NetworkOperationDelegate>

>**Step 3 :** Build URL
>NSURL *serviceURL=[NSURL URLWithString:[NSString stringWithFormat:@"YourURL"]];

>**Step 4 :** Build Parameter dictionary

NSMutableDictionary *dictPara=[[NSMutableDictionary alloc]init];
    [dictPara setValue:@"PARA_1_VALUE" forKey:@"PARA_1_KEY"];
    [dictPara setValue:@"PARA_2_VALUE" forKey:@"PARA_2_KEY"];
    [dictPara setValue:@"PARA_3_VALUE" forKey:@"PARA_3_KEY"];
    [dictPara setValue:@"PARA_4_VALUE" forKey:@"PARA_4_KEY"];
    

**Step 5 :** Implement NetworkOpertation request method
-(void)sendRequestWithURL:(NSURL *)URL parameters:(NSMutableDictionary *)parameters parameterType:(NSString *)parameterType HttpMethod:(NSString *)method taskType:(NSString *)taskType uploadData:(NSData *)uploadData inBackground:(BOOL)inBackground userInfo:(id)userInfo delegate:(id)delegate;

Example :
[[NetworkOperations sharedInstance]sendRequestWithURL:serviceURL parameters:dictPara parameterType:PARA_TYPE_STRING HttpMethod:GET_METHOD taskType:DATA_TASK uploadData:nil inBackground:NO userInfo:@"Anthing that you want back in delegate response method." delegate:self];

Note : Parameters
1.RequestWithURL  : Your service URL in NSURL type.
2.Parameters      : Should be in NSMutableDictionary format.
3.ParameterType   : Parameter type is your kind of format in which you want to send the parameter to server.
  Example :
  a)PARA_TYPE_SOAP - For SOAP Request parameters.
  b)PARA_TYPE_JSON - For JSON Request parameters.
  c)PARA_TYPE_STRING - For normal string (GET Method) request parameter.
4.HttpMethod      : GET OR POST
5.TaskType        : The operation you want to perform, example : normal JSON or String response request or Data upload or Data download.
  Types :
    a)DATA_TASK
    b)DATA_UPLOAD_TASK
    c)DATA_DOWNLOAD_TASK
6.UploadData      : When data task is DATA_UPLOAD_TASK you need to provide data/bytes in NSData format to be uploaded on server.
  Usage example - When you want to upload a photo to server, simply all you need to do is, convert that image into NSData and choose TaskType as DATA_UPLOAD_TASK and provide that data with "UploadData" parameter.
7.InBackground    : BOOL value to select in which thread you want to perform the action.
8.UserInfo        : Any data or info which you want back in response delegate method.
9.delegate        : Where you want to handle the response delegate method

Step 6 Delegate method    : Implement the delegate method to handle the response 
-(void)akNetworkOperationDidFinishRequestWithResponse:(NSMutableDictionary*)response error:(NSError*)error;
Response Dictionary structure / Defined Keys for acces data :
    a)AK_Response_Bytes   - Contains reposnse in NSData format.
    b)AK_Response_Error   - Contains NSError if occured.
    c)AK_Response_String  - Contains response in NSString format.
    d)AK_Response_JSON    - Contain response in JSON formar (if Valid JSON).  
    e)AK_Response_UserInfo- Contain same UserInfo as passed in Request method.
    f)AK_Request_URL      - Contain NSURL of request and response is for.
    
  




