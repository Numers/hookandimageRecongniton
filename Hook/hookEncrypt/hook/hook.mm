#import <CaptainHook/CaptainHook.h>
#import "SocketManager.h"
CHDeclareClass(YYxxTeaJSONResponseSerializer);
CHDeclareClass(YYxxTeaHTTPRequestSerializer);
//CHDeclareClass(XXTEA);

CHOptimizedMethod3(self, id, YYxxTeaJSONResponseSerializer, responseObjectForResponse, id, arg1, data, id, arg2, error, id *,arg3)
{
    NSLog(@"hook values response arg1  %@,  arg2 %@",arg1,arg2);
    id result =  CHSuper3(YYxxTeaJSONResponseSerializer, responseObjectForResponse, arg1, data, arg2, error, arg3);
    NSLog(@"hook values Response: %@",result);
    NSHTTPURLResponse *urlResponse = (NSHTTPURLResponse *)arg1;
    NSString *url = [[urlResponse URL] absoluteString];
    if ([url containsString:@"user/login"]) {
        NSMutableDictionary *resultDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:url,@"url",@(0),@"isRequest",@"token",@"label", nil];
        id token = [[result objectForKey:@"data"] objectForKey:@"token"];
        id userId = [[result objectForKey:@"data"] objectForKey:@"userId"];
        [[SocketManager shareManager] setToken:token userId:userId];
        NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:token,@"token",userId,@"userId", nil];
        [resultDic setObject:[[SocketManager shareManager] stringFromJsonData:dic] forKey:@"data"];
        [[SocketManager shareManager] writeDataToClient:resultDic];
    }
    return result;
}

CHOptimizedMethod3(self, id, YYxxTeaHTTPRequestSerializer, requestBySerializingRequest, id, arg1, withParameters, id, arg2, error, id *,arg3)
{
    NSLog(@"hook values Request arg1  %@,  arg2 %@",arg1,arg2);
    NSMutableURLRequest *result =  CHSuper3(YYxxTeaHTTPRequestSerializer, requestBySerializingRequest, arg1, withParameters, arg2, error, arg3);
    NSLog(@"hook values Request: %@ httpBody:%@",[result allHTTPHeaderFields],[result HTTPBody]);
    id decrptResult = objc_msgSend([NSClassFromString(@"XXTEA") class], NSSelectorFromString(@"decryptToString:stringKey:"),[result HTTPBody],@"404ccc36a0e27a28");
    NSLog(@"decript result:%@",decrptResult);
    return result;
}

CHConstructor {
    @autoreleasepool {
        CHLoadLateClass(YYxxTeaJSONResponseSerializer);
        CHHook3(YYxxTeaJSONResponseSerializer, responseObjectForResponse, data,error);
        
        CHLoadLateClass(YYxxTeaHTTPRequestSerializer);
        CHHook3(YYxxTeaHTTPRequestSerializer, requestBySerializingRequest, withParameters,error);
        
        [[SocketManager shareManager] listenSocket:8890];
        [[SocketManager shareManager] setDowithDataCallback:^id(id dic) {
            if(dic){
                NSString *url = [dic objectForKey:@"url"];
                BOOL isRequest = [[dic objectForKey:@"isRequest"] boolValue];
                NSMutableDictionary *resultDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:url,@"url",@(isRequest),@"isRequest", nil];
                if(isRequest){
                    NSString *jsonString = nil;
                    id jsonObj = [dic objectForKey:@"data"];
                    if([jsonObj isKindOfClass:[NSDictionary class]]){
                        jsonString = [[SocketManager shareManager] stringFromJsonData:jsonObj];
                    }else if([jsonObj isKindOfClass:[NSString class]]){
                        jsonString = jsonObj;
                    }else{
                        jsonString = @"";
                    }
                    NSData *encryptResult = objc_msgSend([NSClassFromString(@"XXTEA") class], NSSelectorFromString(@"encryptString:stringKey:"),jsonString,@"404ccc36a0e27a28");
                    if(encryptResult){
                        NSString *encryptResultString = [encryptResult base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
                        [resultDic setObject:encryptResultString forKey:@"data"];
                    
//                        NSData *encrypt = [[NSData alloc] initWithBase64EncodedString:encryptResultString options:NSDataBase64Encoding64CharacterLineLength];
//                        NSLog(@"decryptData:%@ decrptDataString:%@",encrypt,encryptResultString);
                        
                        
                    }else{
                        [resultDic setObject:@"" forKey:@"data"];
                    }
                    [[SocketManager shareManager] writeDataToClient:resultDic data:nil];
                    return encryptResult;
                }else{
                    NSData *encrypt = nil;
                    id encryptData = [dic objectForKey:@"data"];
                    if(encryptData && [encryptData isKindOfClass:[NSString class]]){
                        NSLog(@"decrptDataString:%@",encryptData);
                        encrypt = [[NSData alloc] initWithBase64EncodedString:encryptData options:NSDataBase64Encoding64CharacterLineLength];
                    }
                    
                    if(encryptData && [encryptData isKindOfClass:[NSData class]]){
                        encrypt = encryptData;
                    }
                    
                    NSLog(@"decryptData:%@",encrypt);
                    if(encrypt != nil){
                        BOOL gzip = [[dic objectForKey:@"gzip"] boolValue];
                        id decrptResult = nil;
                        if(gzip){
                            id tempDecrptResult = objc_msgSend([NSClassFromString(@"XXTEA") class], NSSelectorFromString(@"decrypt:stringKey:"),encrypt,@"404ccc36a0e27a28");
                            if(tempDecrptResult){
                                id temp  = [[SocketManager shareManager] uncompressZippedData:tempDecrptResult];
                                if(temp){
                                    decrptResult = [[NSString alloc] initWithData:temp encoding:NSUTF8StringEncoding];
                                }
                            }
                        }else{
                            decrptResult = objc_msgSend([NSClassFromString(@"XXTEA") class], NSSelectorFromString(@"decryptToString:stringKey:"),encrypt,@"404ccc36a0e27a28");
                        }
                        
                        if(decrptResult){
                            [resultDic setObject:decrptResult forKey:@"data"];
                        }else{
                            [resultDic setObject:@"" forKey:@"data"];
                        }
                        
                    }else{
                        [resultDic setObject:@"" forKey:@"data"];
                    }
                    
                }
                [[SocketManager shareManager] writeDataToClient:resultDic];
                return resultDic;
            }
            return nil;
        }];
        
        [[SocketManager shareManager] setRequestCallback:^(id dic) {
            NSLog(@"hook Test");
            NSString *url = [dic objectForKey:@"url"];
            NSString *params = [dic objectForKey:@"data"];
            if(!url || !params){
                return;
            }
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
            NSData *encryptData = objc_msgSend([NSClassFromString(@"XXTEA") class], NSSelectorFromString(@"encryptString:stringKey:"),params,@"404ccc36a0e27a28");
            [request setValue:@"zh-Hans-CN;q=1, zh-Hant-CN;q=0.9, en-CN;q=0.8" forHTTPHeaderField:@"Accept-Language"];
            [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
            [request setValue:@"smoba/2.33.502 (iPhone; iOS 10.3.3; Scale/2.00)" forHTTPHeaderField:@"User-Agent"];
            [request setHTTPBody:encryptData];
            NSLog(@"http rest encryptData:%@",encryptData);

            NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
            NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                NSLog(@"responseResult:response: %@,data: %@, error:%@",response,data,error.localizedDescription);
                if(!error){
                    NSString *url = [[response URL] absoluteString];
                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                    NSDictionary *head = [httpResponse allHeaderFields];
                    BOOL gzip = [[head objectForKey:@"gh-gzip"] boolValue];
                    
                    id tempDecrptResult = objc_msgSend([NSClassFromString(@"XXTEA") class], NSSelectorFromString(@"decrypt:stringKey:"),data,@"404ccc36a0e27a28");
                    id decrptResult = nil;
                    if(gzip){
                        id temp = [[SocketManager shareManager] uncompressZippedData:tempDecrptResult];
                        decrptResult = [[NSString alloc] initWithData:temp encoding:NSUTF8StringEncoding];
                        NSLog(@"decript result:%@",decrptResult);
                    }else{
                        decrptResult = [[NSString alloc] initWithData:tempDecrptResult encoding:NSUTF8StringEncoding];
                        NSLog(@"decript result:%@",decrptResult);
                    }
                    
                    id label = [dic objectForKey:@"label"];
                    id state = [dic objectForKey:@"state"];
                    NSMutableDictionary *resultDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:url,@"url",label,@"label",state,@"state", nil];
                    if(decrptResult){
                        [resultDic setObject:decrptResult forKey:@"data"];
                    }else{
                        [resultDic setObject:@"" forKey:@"data"];
                    }
                    
                    [[SocketManager shareManager] writeDataToClient:resultDic];
                }
            }];

            [task resume];
        }];
    }
}
