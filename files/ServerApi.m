//
//  ServerApi.m
//  HY012_iOS
//
//  Created by Arvin on 2018/6/5.
//  Copyright © 2018年 Arvin. All rights reserved.
//

#import "ServerApi.h"

NSErrorDomain const HBSServerNetErrorDomain = @"PMJServerNetErrorDomain";

#define HTTP_CONTENT_BOUNDARY @"###############BOUNDARY##################"

NSString * const HBSURLRequestSerializationErrorDomain = @"com.alamofire.error.serialization.request";
NSString * const HBSNetworkingOperationFailingURLRequestErrorKey = @"com.alamofire.serialization.request.error.response";

typedef NSString * (^HBSQueryStringSerializationBlock)(NSURLRequest *request, id parameters, NSError *__autoreleasing *error);

/**
 Returns a percent-escaped string following RFC 3986 for a query string key or value.
 RFC 3986 states that the following characters are "reserved" characters.
 - General Delimiters: ":", "#", "[", "]", "@", "?", "/"
 - Sub-Delimiters: "!", "$", "&", "'", "(", ")", "*", "+", ",", ";", "="
 
 In RFC 3986 - Section 3.4, it states that the "?" and "/" characters should not be escaped to allow
 query strings to include a URL. Therefore, all "reserved" characters with the exception of "?" and "/"
 should be percent-escaped in the query string.
 - parameter string: The string to be percent-escaped.
 - returns: The percent-escaped string.
 */
NSString * HBSPercentEscapedStringFromString(NSString *string) {
    static NSString * const kHBSCharactersGeneralDelimitersToEncode = @":#[]@"; // does not include "?" or "/" due to RFC 3986 - Section 3.4
    static NSString * const kHBSCharactersSubDelimitersToEncode = @"!$&'()*+,;=";
    NSMutableCharacterSet * allowedCharacterSet = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
    [allowedCharacterSet removeCharactersInString:[kHBSCharactersGeneralDelimitersToEncode stringByAppendingString:kHBSCharactersSubDelimitersToEncode]];
    
    // FIXME: https://github.com/HBSNetworking/HBSNetworking/pull/3028
    // return [string stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacterSet];
    
    static NSUInteger const batchSize = 50;
    
    NSUInteger index = 0;
    NSMutableString *escaped = @"".mutableCopy;
    
    while (index < string.length) {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wgnu"
        NSUInteger length = MIN(string.length - index, batchSize);
#pragma GCC diagnostic pop
        NSRange range = NSMakeRange(index, length);
        
        // To avoid breaking up character sequences such as 👴🏻👮🏽
        range = [string rangeOfComposedCharacterSequencesForRange:range];
        
        NSString *substring = [string substringWithRange:range];
        NSString *encoded = [substring stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacterSet];
        [escaped appendString:encoded];
        
        index += range.length;
    }
    
    return escaped;
}

#pragma mark -

@interface HBSQueryStringPair : NSObject
@property (readwrite, nonatomic, strong) id field;
@property (readwrite, nonatomic, strong) id value;

- (instancetype)initWithField:(id)field value:(id)value;

- (NSString *)URLEncodedStringValue;
@end

@implementation HBSQueryStringPair

- (instancetype)initWithField:(id)field value:(id)value {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.field = field;
    self.value = value;
    
    return self;
}

- (NSString *)URLEncodedStringValue {
    if (!self.value || [self.value isEqual:[NSNull null]]) {
        return HBSPercentEscapedStringFromString([self.field description]);
    } else {
        return [NSString stringWithFormat:@"%@=%@", HBSPercentEscapedStringFromString([self.field description]), HBSPercentEscapedStringFromString([self.value description])];
    }
}

@end

#pragma mark -

FOUNDATION_EXPORT NSArray * HBSQueryStringPairsFromDictionary(NSDictionary *dictionary);
FOUNDATION_EXPORT NSArray * HBSQueryStringPairsFromKeyAndValue(NSString *key, id value);

NSString * HBSQueryStringFromParameters(NSDictionary *parameters) {
    NSMutableArray *mutablePairs = [NSMutableArray array];
    for (HBSQueryStringPair *pair in HBSQueryStringPairsFromDictionary(parameters)) {
        [mutablePairs addObject:[pair URLEncodedStringValue]];
    }
    
    return [mutablePairs componentsJoinedByString:@"&"];
}

NSArray * HBSQueryStringPairsFromDictionary(NSDictionary *dictionary) {
    return HBSQueryStringPairsFromKeyAndValue(nil, dictionary);
}

NSArray * HBSQueryStringPairsFromKeyAndValue(NSString *key, id value) {
    NSMutableArray *mutableQueryStringComponents = [NSMutableArray array];
    
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"description" ascending:YES selector:@selector(compare:)];
    
    if ([value isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = value;
        // Sort dictionary keys to ensure consistent ordering in query string, which is important when deserializing potentially ambiguous sequences, such as an array of dictionaries
        for (id nestedKey in [dictionary.allKeys sortedArrayUsingDescriptors:@[ sortDescriptor ]]) {
            id nestedValue = dictionary[nestedKey];
            if (nestedValue) {
                [mutableQueryStringComponents addObjectsFromArray:HBSQueryStringPairsFromKeyAndValue((key ? [NSString stringWithFormat:@"%@[%@]", key, nestedKey] : nestedKey), nestedValue)];
            }
        }
    } else if ([value isKindOfClass:[NSArray class]]) {
        NSArray *array = value;
        for (id nestedValue in array) {
            [mutableQueryStringComponents addObjectsFromArray:HBSQueryStringPairsFromKeyAndValue([NSString stringWithFormat:@"%@[]", key], nestedValue)];
        }
    } else if ([value isKindOfClass:[NSSet class]]) {
        NSSet *set = value;
        for (id obj in [set sortedArrayUsingDescriptors:@[ sortDescriptor ]]) {
            [mutableQueryStringComponents addObjectsFromArray:HBSQueryStringPairsFromKeyAndValue(key, obj)];
        }
    } else {
        [mutableQueryStringComponents addObject:[[HBSQueryStringPair alloc] initWithField:key value:value]];
    }
    
    return mutableQueryStringComponents;
}

/*
 Http Header里的Content-Type一般有这三种：
 application/x-www-form-urlencoded：数据被编码为名称/值对。这是标准的编码格式。
 multipart/form-data： 数据被编码为一条消息，页上的每个控件对应消息中的一个部分。
 text/plain： 数据以纯文本形式(text/json/xml/html)进行编码，其中不含任何控件或格式字符。
 application/json
 */
@implementation ServerApi
{
    NSMutableDictionary *reqInfo;
}

+ (ServerApi *)getServerApi {
    
    static ServerApi *api = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        if (!api) {
            api = [[ServerApi alloc] init];
            
            [api initWithConfig:ServerConfig.defaultConfig];
        }
    });
    return api;
}

- (instancetype)init {
    
    if (self = [super init]) {
        reqInfo = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)initWithConfig:(ServerConfig *)config {
    
    _config = config;
    
}

- (void)test {
    
}

- (BOOL)isExsitReqWithUrl:(NSString *)url param:(NSDictionary *)param {
    
    NSMutableDictionary *allParam = [_config configParam];
    if (!allParam) {
        allParam = [NSMutableDictionary dictionaryWithCapacity:1];
    }
    [allParam addEntriesFromDictionary:param];
    
    NSMutableArray *infoArray = [reqInfo objectForKey:url];
    
    for (NSDictionary *info in infoArray) {
        
        if ([info isEqualToDictionary:allParam]) {
            
            return YES;
        }
    }
    
    return NO;
}

- (void)deleteReqInfoWithUrl:(NSString *)url param:(NSDictionary *)param {
    
    NSMutableArray *paramArray = [reqInfo objectForKey:url];
    
    if (!param) {
        param = @{};
    }
    
    [paramArray removeObject:param];
}

- (void)addReqInfoWithUrl:(NSString *)url param:(NSDictionary *)param {
    
    NSMutableArray *paramArray = [reqInfo objectForKey:url];
    if (!paramArray) {
        paramArray = [NSMutableArray arrayWithCapacity:1];
        [reqInfo setObject:paramArray forKey:url];
    }
    
    if (!param) {
        param = @{};
    }
    
    [paramArray addObject:param];
}

- (void)getRequestWithUrl:(NSString *)url param:(NSDictionary *)param response:(void (^)(NSDictionary *result,NSError *error))complete {
    
    NSMutableDictionary *allParam = [_config configParam];
    if (!allParam) {
        allParam = [NSMutableDictionary dictionaryWithCapacity:1];
    }
    [allParam addEntriesFromDictionary:param];
    
    NSString *postStr = HBSQueryStringFromParameters(allParam);
    NSString *urlstring = [NSString stringWithFormat:@"%@?%@",url,postStr];
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlstring] cachePolicy:0 timeoutInterval:30];
    [req setHTTPMethod:@"GET"];
    [req setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
//    S_DBG(@"请求url:%@\n参数:%@", url,allParam);
    
    [self addReqInfoWithUrl:url param:allParam];
    
    [self postRequest:req jsonResponse:^(NSDictionary *result, NSError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self deleteReqInfoWithUrl:url param:allParam];
            
            if (complete) {
                complete(result,error);
            }
        });
    }];
}

- (void)getDataRequestWithUrl:(NSString *)url param:(NSDictionary *)param response:(void (^)(NSData *result,NSError *error))complete {
    
    NSMutableDictionary *allParam = [_config configParam];
    if (!allParam) {
        allParam = [NSMutableDictionary dictionaryWithCapacity:1];
    }
    [allParam addEntriesFromDictionary:param];
    
    NSString *postStr = HBSQueryStringFromParameters(allParam);
    NSString *urlstring = [NSString stringWithFormat:@"%@?%@",url,postStr];
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlstring] cachePolicy:0 timeoutInterval:30];
    [req setHTTPMethod:@"GET"];
    [req setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
//    S_DBG(@"请求url:%@\n参数:%@", url,allParam);
    
    [self addReqInfoWithUrl:url param:allParam];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    
    NSURLSessionTask *task = [session dataTaskWithRequest:req completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self deleteReqInfoWithUrl:url param:allParam];
            
//            S_DBG(@"获取文件:%lld字节，error:%@",data.length,error);
            if (complete) {
                complete(data,error);
            }
        });
    }];
    [task resume];
}

//标准POST请求
- (void)postRequestWithUrl:(NSString *)url param:(NSDictionary *)param response:(void (^)(NSDictionary *result,NSError *error))complete {
    
    if (url.length <= 0 || param == nil) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (complete) {
                complete(nil,[NSError errorWithDomain:HBSServerNetErrorDomain code:CodeParamIsNil userInfo:@{NSLocalizedDescriptionKey:@"Url or param is nil!"}]);
            }
        });
        return;
    }
    
    NSMutableDictionary *allParam = [_config configParam];
    if (!allParam) {
        allParam = [NSMutableDictionary dictionaryWithCapacity:1];
    }
    [allParam addEntriesFromDictionary:param];
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:0 timeoutInterval:30];
    [req setHTTPMethod:@"POST"];
    [req setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    NSString *postStr = HBSQueryStringFromParameters(allParam);
    [req setHTTPBody:[postStr dataUsingEncoding:NSUTF8StringEncoding]];
    
//    S_DBG(@"请求url:%@\n参数:%@", url,allParam);
    [self addReqInfoWithUrl:url param:allParam];
    
    [self postRequest:req jsonResponse:^(NSDictionary *result, NSError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self deleteReqInfoWithUrl:url param:allParam];
            
            if (complete) {
                complete(result,error);
            }
        });
    }];
}

- (void)postRequestWithUrl:(NSString *)url
                 formParam:(NSDictionary *)param
                 formField:(NSArray <NSDictionary *> *)fieldArray
                  response:(void (^)(NSDictionary *result,NSError *error))complete {
    
    if (url.length <= 0 || (param == nil && [fieldArray count] == 0)) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
           
            if (complete) {
                complete(nil,[NSError errorWithDomain:HBSServerNetErrorDomain code:CodeParamIsNil userInfo:@{NSLocalizedDescriptionKey:@"Url or param is nil!"}]);
            }
        });
        return;
    }
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:0 timeoutInterval:60];
    [req setHTTPMethod:@"POST"];
    [req setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@",HTTP_CONTENT_BOUNDARY]  forHTTPHeaderField:@"Content-Type"];
    
    NSMutableDictionary *allParam = [_config configParam];
    if (!allParam) {
        allParam = [NSMutableDictionary dictionaryWithCapacity:1];
    }
    [allParam addEntriesFromDictionary:param];
    
    NSCharacterSet *character = [NSCharacterSet characterSetWithCharactersInString:@"#%<>[\\]^`{|}\"]+"].invertedSet;

    NSMutableData *postData = [NSMutableData data];
    for (NSString *key in [allParam allKeys]) {

        NSString *value = allParam[key];
        value = [value stringByAddingPercentEncodingWithAllowedCharacters:character];

        NSString *key_value_str = [NSString stringWithFormat:@"--%@\r\nContent-Disposition:form-data;name=\"%@\"\r\n\r\n%@\r\n",HTTP_CONTENT_BOUNDARY,key,allParam[key]];

        [postData appendData:[key_value_str dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    for (NSDictionary *field in fieldArray) {
        
        NSString *name = field[@"name"] ?: @"file";
        NSString *filename = field[@"filename"] ?: @"default.data";
        NSString *mime = field[@"mime"] ?: @"application/octet-stream";
        NSData *data = field[@"filedata"];
        
        NSString *key_str = [NSString stringWithFormat:@"--%@\r\nContent-Disposition:form-data;name=\"%@\";filename=\"%@\";Content-Type=\"%@\"\r\n\r\n",HTTP_CONTENT_BOUNDARY,name,filename,mime];
        printf("%s",[key_str UTF8String]);
        [postData appendData:[key_str dataUsingEncoding:NSUTF8StringEncoding]];
        
        if (data) {
            [postData appendData:data];
        }
        printf("data长度%d",(int)data.length);
        
        [postData appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        printf("\r\n");
    }
    
    NSString *end = [NSString stringWithFormat:@"--%@--\r\n",HTTP_CONTENT_BOUNDARY];
    printf("%s",[end UTF8String]);
    [postData appendData:[end dataUsingEncoding:NSUTF8StringEncoding]];
    
    req.HTTPBody = postData;
    [req setValue:[NSString stringWithFormat:@"%d",(int)postData.length] forHTTPHeaderField:@"Content-Length"];
    
//    S_DBG(@"请求url:%@\n参数:%@", url,allParam);
    
    [self addReqInfoWithUrl:url param:allParam];
    
    [self postRequest:req jsonResponse:^(NSDictionary *result, NSError *error) {
        
        NSError *r_error = nil;
        if (error) {
            r_error = error;
        }
        else {
            NSInteger code = [result[@"code"] integerValue];
            if (code != 200) {
                r_error = [NSError errorWithDomain:HBSServerNetErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey:result[@"message"] ?: @"Unknown error!"}];
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self deleteReqInfoWithUrl:url param:allParam];
            
            if (complete) {
                complete(result,r_error);
            }
        });
    }];
}

#pragma mark - private
- (void)postRequest:(NSMutableURLRequest *)req jsonResponse:(void (^)(NSDictionary *result,NSError *error))jsonResponse {
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    
    NSURLSessionTask *task = [session dataTaskWithRequest:req completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
//        S_DBG(@"响应url:%@:",[req.URL absoluteString]);
        if (error) {
            if (jsonResponse) {
                jsonResponse(nil,error);
            }
        }
        else if (data == nil) {
            if (jsonResponse) {
                jsonResponse(nil,[NSError errorWithDomain:HBSServerNetErrorDomain code:CodeResponseIsNil userInfo:@{NSLocalizedDescriptionKey:@"Response is nil!"}]);
            }
        }
        else {
            NSError *err = nil;
//            NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//            S_DBG(@"%@", str);
            id jsonObj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&err];
            if (err || !jsonObj) {
//                S_DBG(@"error:%@",[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                if (jsonResponse) {
                    jsonResponse(nil,[NSError errorWithDomain:HBSServerNetErrorDomain code:CodeResDataFormatError userInfo:@{NSLocalizedDescriptionKey:@"Response data format is error!"}]);
                }
            }
            else {
                NSDictionary *result = jsonObj;
//                S_DBG(@"%@",result);
                if (jsonResponse) {
                    jsonResponse(result,nil);
                }
            }
        }
    }];
    [task resume];
}

+ (NSString *)codeMessage:(NSInteger)code {
    
    NSString *msg = @"";
    switch (code) {
        case CodeParamIsNil:
            msg = @"请求参数为空!";
            break;
        case CodeResponseIsNil:
            msg = @"响应数据为空!";
            break;
        case CodeResDataFormatError:
            msg = @"响应数据格式错误!";
            break;
        default:
            break;
    }
    return msg;
}

#pragma mark -
@end
