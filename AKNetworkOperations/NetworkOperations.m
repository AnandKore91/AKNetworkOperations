//
//  AKNetworkOperations.m
//  MyCompleteLib
//
//  Created by Anand A. Kore on 17/9/15.
//  Copyright © 2015 Anand Kore. All rights reserved.
//

#import "NetworkOperations.h"

NSString *const kXMLReaderTextNodeKey		= @"text";
NSString *const kXMLReaderAttributePrefix	= @"@";

#pragma mark- Properties Declarations
@interface NetworkOperations()
@property(strong,nonatomic)NSMutableData *receivedData;
@property(strong,nonatomic)NSString *strURL;
@property(strong,nonatomic)id userInfo;

@property(strong,nonatomic)NSMutableArray *dictionaryStack;
@property(strong,nonatomic)NSMutableString *textInProgress;
@end

#pragma mark- Implementation
@implementation NetworkOperations

+(id)sharedInstance
{
    static NetworkOperations *selfInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        selfInstance=[[NetworkOperations alloc]init];
    });
    return selfInstance;
}

#pragma mark-
-(void)sendRequestWithURL:(NSURL *)URL parameters:(NSMutableDictionary *)parameters parameterType:(NSString *)parameterType HttpMethod:(NSString *)method taskType:(NSString *)taskType uploadData:(NSData *)uploadData inBackground:(BOOL)inBackground userInfo:(id)userInfo delegate:(id)delegate
{
    //---------------------------------------------------------//
    self.delegate=delegate;
    self.userInfo=userInfo?userInfo:@"";
    NSLog(@"\nRequest URL :%@ \nParameters  :%@",[URL absoluteString],parameters);
    
    
    //----------- Validate required parameters -------------- //
    if (URL==nil || method==nil || taskType==nil || delegate==nil)
    {
        NSLog(@"AKNetworkOperation : Required para should not be nil.");
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"Required parameter should not be nil." forKey:NSLocalizedDescriptionKey];//-- Create an localized user info.
        
        //--- Check delegate method is implemented or not.
        if ([self.delegate respondsToSelector:@selector(akNetworkOperationDidFinishRequestWithResponse:error:)])
        {
            [self.delegate akNetworkOperationDidFinishRequestWithResponse:nil error:[NSError errorWithDomain:@"Nil Parameter" code:00 userInfo:details]];
        }
        return;
    }
    //-----------Validate paramter and parameter type --------//
    if (parameters && (parameterType==nil || (![parameters isKindOfClass:[NSDictionary class]] || ![parameters isKindOfClass:[NSMutableDictionary class]])))
    {
        NSLog(@"AKNetworkOperation : Parameter type not defined.");
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"Nil or invalid parameter data type. Parameter should be in dictionary format." forKey:NSLocalizedDescriptionKey];//-- Create an localized user info.
        
        //--- Check delegate method is implemented or not.
        if ([self.delegate respondsToSelector:@selector(akNetworkOperationDidFinishRequestWithResponse:error:)])
        {
            [self.delegate akNetworkOperationDidFinishRequestWithResponse:nil error:[NSError errorWithDomain:@"Nil or invalid parameter data type. Parameter should be in dictionary format." code:00 userInfo:details]];
        }
        return;
    }
    
    //----------- Validate Upload data task ------------------//
    if (uploadData && ![taskType isEqualToString:DATA_UPLOAD_TASK])
    {
        NSLog(@"AKNetworkOperation : Upload data task not defined.");
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"Upload data task not defined." forKey:NSLocalizedDescriptionKey];//-- Create an localized user info.
        
        //--- Check delegate method is implemented or not.
        if ([self.delegate respondsToSelector:@selector(akNetworkOperationDidFinishRequestWithResponse:error:)])
        {
            [self.delegate akNetworkOperationDidFinishRequestWithResponse:nil error:[NSError errorWithDomain:@"Data task type mismatch." code:00 userInfo:details]];
        }
        return;
    }
    //---------------------------------------------------------//
    
    //-------------- append GET parameter to URL --------------//
    if([method isEqualToString:GET_METHOD] && parameters.count>0)
    {
        NSString *param=[self convertDictionaryToGETkindString:parameters];
        NSString *rebuildURL=[NSString stringWithFormat:@"%@",[URL absoluteString]];
        rebuildURL=[rebuildURL stringByAppendingString:[NSString stringWithFormat:@"?%@",param]];
        rebuildURL=[rebuildURL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
        
        URL =[NSURL URLWithString:rebuildURL];
        NSLog(@"Rebuilt URL :%@",[URL absoluteString]);
    }
    
    //-------------- Build URL Request ------------------------//
    NSMutableURLRequest *requestURL=[[NSMutableURLRequest alloc]initWithURL:URL cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:60];
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    //NSURLSessionConfiguration * backgroundConfig = [NSURLSessionConfiguration backgroundSessionConfiguration:@"backgroundtask1"];//-- While download operation in background thread
    
    //--- Create session with configuration, delegate and queue.--//
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration: defaultConfigObject delegate:(id)self delegateQueue: [NSOperationQueue mainQueue]];
    
    //-------------- Build POST parameters with request -----------//
    if ([method isEqualToString:POST_METHOD])
    {
        NSString * params;
        if ( parameters!=nil)
        {
            if ([parameterType isEqualToString:PARA_TYPE_JSON])
            {
                params=[self convertDictionaryToJSONkindString:parameters];
            }
            else if ([parameterType isEqualToString:PARA_TYPE_SOAP])
            {
                params=[self convertDictionaryToSOAPKindString:parameters];
            }
            else if ([parameterType isEqualToString:PARA_TYPE_STRING])
            {
                params=[self convertDictionaryToGETkindString:parameters];
            }
        }
        
        [requestURL setHTTPMethod:POST_METHOD];//---  Set HTTP method type.
        [requestURL setHTTPBody:[params dataUsingEncoding:NSUTF8StringEncoding]];//--- Append parameter data to HTTP body.
    }
    
    
    
    
    //--------------- On background thread------------------------//
    if (inBackground == YES)
    {
        if ([taskType isEqualToString:DATA_TASK])//--- JSON Data or plain request.
        {
            NSURLSessionDataTask *dataTask=[defaultSession dataTaskWithRequest:requestURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
            {
                if ([self.delegate respondsToSelector:@selector(akNetworkOperationDidFinishRequestWithResponse:error:)])
                {
                    [self.delegate akNetworkOperationDidFinishRequestWithResponse:[self buildResponseDictionaryForRequest:[URL absoluteString] data:data userInfo:self.userInfo error:error] error:error];
                }
            }];
            [dataTask resume];
        }
        else if ([taskType isEqualToString:DATA_UPLOAD_TASK])//--- Data upload task
        {
            //--- Create upload task instance with session, upload data.
            NSURLSessionUploadTask *uploadTask=[defaultSession uploadTaskWithRequest:requestURL fromData:uploadData completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
            {
                if ([self.delegate respondsToSelector:@selector(akNetworkOperationDidFinishRequestWithResponse:error:)])
                {
                    [self.delegate akNetworkOperationDidFinishRequestWithResponse:[self buildResponseDictionaryForRequest:[URL absoluteString] data:data userInfo:self.userInfo error:error] error:error];
                }
            }];
            [uploadTask resume];
        }
        else if ([taskType isEqualToString:DATA_DOWNLOAD_TASK])//--- Data download task
        {
            //--- Create upload task instance with session.
            NSURLSessionDownloadTask *downloadTask=[defaultSession downloadTaskWithRequest:requestURL completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error)
            {
                if(error == nil)
                {
                    NSLog(@"File Location :%@",location);
                    
                    NSError *err = nil;
                    NSFileManager *fileManager = [NSFileManager defaultManager];
                    NSString *docsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
                    NSURL *docsDirURL = [NSURL fileURLWithPath:[docsDir stringByAppendingPathComponent:@"out.zip"]];
                    if ([fileManager moveItemAtURL:location toURL:docsDirURL error: &err])
                    {
                        NSLog(@"File is saved at =%@",docsDir);
                        if ([self.delegate respondsToSelector:@selector(akNetworkOperationDidFinishRequestWithResponse:error:)])
                        {
                            NSMutableDictionary *dictReponse =[[NSMutableDictionary alloc]init];
                            [dictReponse setObject:@"" forKey:@"Response_Bytes"];
                            [dictReponse setObject:error?error:@"" forKey:@"Response_Error"];
                            [dictReponse setObject:docsDir?docsDir:@"" forKey:@"Response_String"];
                            [dictReponse setObject:@"" forKey:@"Response_JSON"];
                            [dictReponse setObject:self.userInfo?self.userInfo:@"" forKey:@"UserInfo"];
                            [dictReponse setObject:[URL absoluteString] forKey:@"Request_URL"];
                            
                            [self.delegate akNetworkOperationDidFinishRequestWithResponse:dictReponse error:error];
                        }
                    }
                    else
                    {
                        NSLog(@"AKNetworkOperation : Failed to move/save file %@",[err userInfo]);
                        NSMutableDictionary* details = [NSMutableDictionary dictionary];
                        [details setValue:[NSString stringWithFormat:@"Failed to move/save file :%@",[err userInfo]] forKey:NSLocalizedDescriptionKey];//-- Create an localized user info.
                        
                        if ([self.delegate respondsToSelector:@selector(akNetworkOperationDidFinishRequestWithResponse:error:)])
                        {
                            [self.delegate akNetworkOperationDidFinishRequestWithResponse:nil error:[NSError errorWithDomain:[NSString stringWithFormat:@"Failed to move/save file :%@",[err userInfo]] code:00 userInfo:details]];
                        }
                    }
                }
                else
                {
                    if ([self.delegate respondsToSelector:@selector(akNetworkOperationDidFinishRequestWithResponse:error:)])
                    {
                        [self.delegate akNetworkOperationDidFinishRequestWithResponse:nil error:error];
                    }
                }
            }];
            [downloadTask resume];
        }
    }
    else //----- On main thread
    {
        self.userInfo=userInfo;
        self.strURL=[URL absoluteString];

        if ([taskType isEqualToString:DATA_TASK])
        {
            NSURLSessionDataTask *dataTask= [defaultSession dataTaskWithRequest:requestURL];
            [dataTask resume];
        }
        else if ([taskType isEqualToString:DATA_UPLOAD_TASK])
        {
            NSURLSessionUploadTask *uploadTask=[defaultSession uploadTaskWithRequest:requestURL fromData:uploadData];
            [uploadTask resume];
        }
        else if ([taskType isEqualToString:DATA_DOWNLOAD_TASK])
        {
            NSURLSessionDownloadTask *downloadTask=[defaultSession downloadTaskWithRequest:requestURL];
            [downloadTask resume];
        }
    }
}

#pragma mark- NSURLSessionDataTask Delegate & NSURLSessionUploadTask Delegate OR common delegate methods
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    NSLog(@"URLSession: didReceiveResponse and initializing data..");
    _receivedData=nil;
    _receivedData=[[NSMutableData alloc] init];
    [_receivedData setLength:0];
    
    completionHandler(NSURLSessionResponseAllow);
}

-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
   didReceiveData:(NSData *)data
{
    _receivedData?[_receivedData appendData:data]:(_receivedData=[[NSMutableData alloc]initWithData:data]);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(akNetworkOperationDidFinishRequestWithResponse:error:)])
    {
        [self.delegate akNetworkOperationDidFinishRequestWithResponse:[self buildResponseDictionaryForRequest:self.strURL data:_receivedData userInfo:self.userInfo error:error] error:error];
    }
}

#pragma mark-
-(void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error
{
    NSLog(@"URLSession Error :%@",error.localizedDescription);
    if ([self.delegate respondsToSelector:@selector(akNetworkOperationDidFinishRequestWithResponse:error:)])
    {
        [self.delegate akNetworkOperationDidFinishRequestWithResponse:[self buildResponseDictionaryForRequest:self.strURL data:_receivedData userInfo:self.userInfo error:error] error:error];
    }
}
-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler
{
}

#pragma mark- NSURLSessionDownloadTask Delegate

-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
}

-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    NSError *err = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *docsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSURL *docsDirURL = [NSURL fileURLWithPath:[docsDir stringByAppendingPathComponent:@"out.zip"]];
    if ([fileManager moveItemAtURL:location toURL:docsDirURL error: &err])
    {
        NSLog(@"File is saved at =%@",docsDir);
        if ([self.delegate respondsToSelector:@selector(akNetworkOperationDidFinishRequestWithResponse:error:)])
        {
            NSMutableDictionary *dictReponse =[[NSMutableDictionary alloc]init];
            [dictReponse setObject:@"" forKey:@"Response_Bytes"];
            [dictReponse setObject:@"" forKey:@"Response_Error"];
            [dictReponse setObject:docsDir forKey:@"Response_String"];
            [dictReponse setObject:@"" forKey:@"Response_JSON"];
            [dictReponse setObject:self.userInfo forKey:@"UserInfo"];
            [dictReponse setObject:self.strURL forKey:@"Request_URL"];
            
            [self.delegate akNetworkOperationDidFinishRequestWithResponse:dictReponse error:err];
        }
    }
    else
    {
        NSLog(@"AKNetworkOperation : Failed to move/save file %@",[err userInfo]);
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:[NSString stringWithFormat:@"Failed to move/save file :%@",[err userInfo]] forKey:NSLocalizedDescriptionKey];
        
        if ([self.delegate respondsToSelector:@selector(akNetworkOperationDidFinishRequestWithResponse:error:)])
        {
            [self.delegate akNetworkOperationDidFinishRequestWithResponse:nil error:[NSError errorWithDomain:[NSString stringWithFormat:@"Failed to move/save file :%@",[err userInfo]] code:00 userInfo:details]];
        }
    }
}
-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes
{
}




#pragma mark- Converter methods
-(NSString*)convertDictionaryToSOAPKindString:(NSMutableDictionary*)dictionary
{
    NSString *strPara=@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
    "<SOAP-ENV:Envelope xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:ns1=\"urn:localhost-catalog\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:SOAP-ENC=\"http://schemas.xmlsoap.org/soap/encoding/\" SOAP-ENV:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\">\n"
    "<SOAP-ENV:Body>/n"
    "<ns1:getCatalogEntry>/n";
    
    for (NSString *key in dictionary)
    {   strPara =[strPara stringByAppendingString:[self createTagElementForKey:key value:[dictionary valueForKey:key]]];    }
    strPara=[strPara stringByAppendingString:@"</ns1:getCatalogEntry>\n</SOAP-ENV:Body>\n</SOAP-ENV:Envelope>"];
    NSLog(@"Final SOAP string :%@",strPara);
    return strPara;
}

-(NSString*)convertDictionaryToGETkindString:(NSMutableDictionary*)dictionary
{
    NSString *strPara=[NSString new];
    for (NSString *key in dictionary)
    {   strPara =[strPara stringByAppendingString:[NSString stringWithFormat:@"%@=%@&",key,[dictionary valueForKey:key]]];    }
    strPara = [strPara substringToIndex:[strPara length]-1];//--- Remove extra "&"
    NSLog(@"Final string :%@",strPara);
    return strPara;
}

-(NSString*)convertDictionaryToJSONkindString:(NSMutableDictionary*)dictionary
{
    NSError *error;NSString *jsonString;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:&error];// Pass 0 if you don't care about the readability of the generated string
    if (! jsonData) {
        NSLog(@"Got an error: %@", error);
    } else {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    //NSLog(@"JSON String :%@",jsonString);
    return jsonString;
}



#pragma mark- Utility methods
-(NSString*)createTagElementForKey:(NSString*)key value:(NSString*)value
{
    NSString *strElement=[NSString new];
    strElement=[NSString stringWithFormat:@"<%@ xsi:type=\"xsd:string\">%@</%@>\n",key,value,key];
    return strElement;
}
-(NSMutableDictionary *)buildResponseDictionaryForRequest:(NSString*)url data:(NSData*)data userInfo:(id)userInfo error:(NSError*)error
{
    NSMutableDictionary *dictReponse =[[NSMutableDictionary alloc]init];
    if (data)
    {
        NSString * strResponseText = [[NSString alloc] initWithData:data encoding: NSUTF8StringEncoding];
        NSDictionary *dictResponseData =[self isValidJSONData:data]?[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error]:nil;
        
        [dictReponse setObject:data forKey:AK_Response_Bytes];
        [dictReponse setObject:error?error:@"" forKey:AK_Response_Error];
        [dictReponse setObject:strResponseText?strResponseText:@"" forKey:AK_Response_String];
        [dictReponse setObject:dictResponseData?dictResponseData:@"" forKey:AK_Response_JSON];
        [dictReponse setObject:userInfo forKey:AK_Response_UserInfo];
        [dictReponse setObject:url forKey:AK_Request_URL];
    }
    else
    {
        [dictReponse setObject:@"" forKey:AK_Response_Bytes];
        [dictReponse setObject:error?error:@"" forKey:AK_Response_Error];
        [dictReponse setObject:@"" forKey:AK_Response_String];
        [dictReponse setObject:@"" forKey:AK_Response_JSON];
        [dictReponse setObject:userInfo?userInfo:@"" forKey:AK_Response_UserInfo];
        [dictReponse setObject:url forKey:AK_Request_URL];
    }
    //NSLog(@"Response Data :%@",dictReponse);
    return dictReponse;
}

#pragma mark- Validator
-(BOOL)isValidJSONData:(NSData*)data
{
    if (!data)
    {
        return NO;
    }
    
    NSError *error;
    if ([NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error] == nil)
    {
        return NO;
    }
    return YES;
}


#pragma mark- XML Parser
-(NSDictionary *)dictionaryForXMLData:(NSData *)data error:(NSError **)error
{
    NSDictionary *rootDictionary = [self objectWithData:data options:0];
    return rootDictionary;
}

- (NSDictionary *)objectWithData:(NSData *)data options:(NSInteger)options
{
    enum {
        XMLReaderOptionsProcessNamespaces           = 1 << 0, // Specifies whether the receiver reports the namespace and the qualified name of an element.
        XMLReaderOptionsReportNamespacePrefixes     = 1 << 1, // Specifies whether the receiver reports the scope of namespace declarations.
        XMLReaderOptionsResolveExternalEntities     = 1 << 2, // Specifies whether the receiver reports declarations of external entities.
    };
    
    // Clear out any old data
    self.dictionaryStack = [[NSMutableArray alloc] init];
    self.textInProgress = [[NSMutableString alloc] init];
    
    // Initialize the stack with a fresh dictionary
    [self.dictionaryStack addObject:[NSMutableDictionary dictionary]];
    
    // Parse the XML
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
    
    [parser setShouldProcessNamespaces:(options & XMLReaderOptionsProcessNamespaces)];
    [parser setShouldReportNamespacePrefixes:(options & XMLReaderOptionsReportNamespacePrefixes)];
    [parser setShouldResolveExternalEntities:(options & XMLReaderOptionsResolveExternalEntities)];
    
    parser.delegate = (id)self;
    BOOL success = [parser parse];
    
    // Return the stack's root dictionary on success
    if (success)
    {
        NSDictionary *resultDict = [self.dictionaryStack objectAtIndex:0];
        return resultDict;
    }
    
    return nil;
}

#pragma mark -  NSXMLParserDelegate methods

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    // Get the dictionary for the current level in the stack
    NSMutableDictionary *parentDict = [self.dictionaryStack lastObject];
    
    // Create the child dictionary for the new element, and initilaize it with the attributes
    NSMutableDictionary *childDict = [NSMutableDictionary dictionary];
    [childDict addEntriesFromDictionary:attributeDict];
    
    // If there's already an item for this key, it means we need to create an array
    id existingValue = [parentDict objectForKey:elementName];
    if (existingValue)
    {
        NSMutableArray *array = nil;
        if ([existingValue isKindOfClass:[NSMutableArray class]])
        {
            // The array exists, so use it
            array = (NSMutableArray *) existingValue;
        }
        else
        {
            // Create an array if it doesn't exist
            array = [NSMutableArray array];
            [array addObject:existingValue];
            
            // Replace the child dictionary with an array of children dictionaries
            [parentDict setObject:array forKey:elementName];
        }
        
        // Add the new child dictionary to the array
        [array addObject:childDict];
    }
    else
    {
        // No existing value, so update the dictionary
        [parentDict setObject:childDict forKey:elementName];
    }
    // Update the stack
    [self.dictionaryStack addObject:childDict];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    // Update the parent dict with text info
    NSMutableDictionary *dictInProgress = [self.dictionaryStack lastObject];
    
    // Set the text property
    if ([self.textInProgress length] > 0)
    {
        // trim after concatenating
        NSString *trimmedString = [self.textInProgress stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [dictInProgress setObject:[trimmedString mutableCopy] forKey:kXMLReaderTextNodeKey];
        
        // Reset the text
        self.textInProgress = [[NSMutableString alloc] init];
    }
    // Pop the current dict
    [self.dictionaryStack removeLastObject];
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    // Build the text value
    [self.textInProgress appendString:string];
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    // Set the error pointer to the parser's error object
    //self.errorPointer = parseError;
}













@end
