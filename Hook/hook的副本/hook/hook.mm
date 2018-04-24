#import <CaptainHook/CaptainHook.h>
#import "SocketManager.h"
CHDeclareClass(YYxxTeaJSONResponseSerializer);
CHDeclareClass(YYxxTeaHTTPRequestSerializer);
//CHDeclareClass(XXTEA);
CHDeclareClass(WloginSdk_v2);
CHDeclareClass(QQLoginSdk);
CHDeclareClass(LoginOperator);
CHDeclareClass(WebServiceManager);

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


CHOptimizedMethod4(self, void, WloginSdk_v2, loginSuccessSig, id, arg1, andBaseInfo, id, arg2, andPasswdSig, id ,arg3,tag,long long,arg4)
{
    NSLog(@"I need to see arg1 WloginSdk_v2 loginSuccessSig arg1  %@,  arg2 %@, arg3 %@, arg4 %lld",arg1,arg2,arg3,arg4);
    CHSuper4(WloginSdk_v2, loginSuccessSig, arg1, andBaseInfo, arg2, andPasswdSig, arg3, tag, arg4);
}

CHOptimizedMethod4(self, void, QQLoginSdk, loginSuccessSig_v2, id, arg1, andSig, id, arg2, andBaseInfo, id ,arg3,tag,long long,arg4)
{
    NSLog(@"I need to see arg1 QQLoginSdk loginSuccessSig_v2 arg1  %@,  arg2 %@, arg3 %@, arg4 %lld",arg1,arg2,arg3,arg4);
    CHSuper4(QQLoginSdk, loginSuccessSig_v2, arg1, andSig, arg2, andBaseInfo, arg3, tag, arg4);
}

CHOptimizedMethod1(self, void, LoginOperator, _loginQQDidSuccess, id, arg1)
{
    NSLog(@"I need to see arg1 LoginOperator _loginQQDidSuccess arg1  %@",arg1);
    CHSuper1(LoginOperator, _loginQQDidSuccess, arg1);
}

CHOptimizedMethod1(self, void, LoginOperator, _loginDidSuccessWithAccount, id, arg1)
{
    NSLog(@"I need to see arg1 LoginOperator _loginDidSuccessWithAccount arg1  %@",arg1);
    CHSuper1(LoginOperator, _loginDidSuccessWithAccount, arg1);
}

CHOptimizedMethod1(self, void, LoginOperator, _loginAppServerWithAccount, id, arg1)
{
    NSLog(@"I need to see arg1 LoginOperator _loginAppServerWithAccount arg1  %@",arg1);
    CHSuper1(LoginOperator, _loginAppServerWithAccount, arg1);
}

CHOptimizedMethod4(self, void, WebServiceManager, loginWithQQTicket, id, arg1, andIsRelogin, id, arg2, success, id ,arg3,failure,id,arg4)
{
    NSLog(@"I need to see arg1 WebServiceManager loginWithQQTicket arg1  %@,  arg2 %@, arg3 %@, arg4 %@",arg1,arg2,arg3,arg4);
    CHSuper4(WebServiceManager, loginWithQQTicket, arg1, andIsRelogin, arg2, success, arg3, failure, arg4);
}

CHOptimizedMethod4(self, void, WebServiceManager, callApi, id, arg1, param, id, arg2, success, id ,arg3,failure,id,arg4)
{
    NSLog(@"I need to see arg1 WebServiceManager callApi arg1  %@,  arg2 %@, arg3 %@, arg4 %@",arg1,arg2,arg3,arg4);
    CHSuper4(WebServiceManager, callApi, arg1, param, arg2, success, arg3, failure, arg4);
}

CHConstructor {
    @autoreleasepool {
        CHLoadLateClass(YYxxTeaJSONResponseSerializer);
        CHHook3(YYxxTeaJSONResponseSerializer, responseObjectForResponse, data,error);
        
        CHLoadLateClass(YYxxTeaHTTPRequestSerializer);
        CHHook3(YYxxTeaHTTPRequestSerializer, requestBySerializingRequest, withParameters,error);
        
        CHLoadLateClass(WloginSdk_v2);
        CHHook4(WloginSdk_v2, loginSuccessSig, andBaseInfo,andPasswdSig,tag);
        
        CHLoadLateClass(QQLoginSdk);
        CHHook4(QQLoginSdk, loginSuccessSig_v2, andSig,andBaseInfo,tag);
        
        CHLoadLateClass(LoginOperator);
        CHHook1(LoginOperator, _loginQQDidSuccess);
        
        CHLoadLateClass(LoginOperator);
        CHHook1(LoginOperator, _loginDidSuccessWithAccount);
        
        CHLoadLateClass(LoginOperator);
        CHHook1(LoginOperator, _loginAppServerWithAccount);
        
        CHLoadLateClass(WebServiceManager);
        CHHook4(WebServiceManager, loginWithQQTicket, andIsRelogin,success,failure);
        
        CHLoadLateClass(WebServiceManager);
        CHHook4(WebServiceManager, callApi, param,success,failure);
        
        [[SocketManager shareManager] listenSocket:8890];
        [[SocketManager shareManager] setDowithDataCallback:^id(id dic) {
            if(dic){
                NSString *url = [dic objectForKey:@"url"];
                NSString *label = [dic objectForKey:@"label"];
                id state = [dic objectForKey:@"state"];
                NSMutableDictionary *resultDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:url,@"url",label,@"label",state,@"state", nil];
                if([label isEqualToString:@"encrypt"]){
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
                        NSString *base64EncryptString = [encryptResult base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
                        [resultDic setObject:base64EncryptString forKey:@"data"];
                    }else{
                        [resultDic setObject:@"" forKey:@"data"];
                    }
                    [[SocketManager shareManager] writeDataToClient:resultDic];
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
