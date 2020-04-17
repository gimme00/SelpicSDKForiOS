//
//  NSObject_property.m
//  HY012_iOS
//
//  Created by Arvin on 2018/8/10.
//  Copyright © 2018年 Arvin. All rights reserved.
//

#import "NSObject_property.h"
#import <objc/runtime.h>

@implementation NSObject (property)

- (NSString *)propertyType:(NSString *)propertyName {
    
    Class self_cls = object_getClass(self);
    
    objc_property_t pro = class_getProperty(self_cls, [propertyName UTF8String]);
    
    const char * property_attr = property_getAttributes(pro);
    NSString *property_data_type = nil;
    
    if (property_attr[1] == '@') {
        char * occurs1 =  strchr(property_attr, '@');
        char * occurs2 =  strrchr(occurs1, '"');
        char dest_str[40]= {0};
        strncpy(dest_str, occurs1, occurs2 - occurs1);
        char * realType = (char *)malloc(sizeof(char) * 50);
        int i = 0, j = 0, len = (int)strlen(dest_str);
        for (; i < len; i++) {
            if ((dest_str[i] >= 'a' && dest_str[i] <= 'z') || (dest_str[i] >= 'A' && dest_str[i] <= 'Z')) {
                realType[j++] = dest_str[i];
            }
        }
        property_data_type = [NSString stringWithFormat:@"%s", realType];
        free(realType);
    }
    else {
        char *type;
        char t = property_attr[1];
        if (strcmp(&t, @encode(char)) == 0) {
            type = "char";
        } else if (strcmp(&t, @encode(int)) == 0) {
            type = "int";
        } else if (strcmp(&t, @encode(short)) == 0) {
            type = "short";
        } else if (strcmp(&t, @encode(long)) == 0) {
            type = "long";
        } else if (strcmp(&t, @encode(long long)) == 0) {
            type = "long long";
        } else if (strcmp(&t, @encode(unsigned char)) == 0) {
            type = "unsigned char";
        } else if (strcmp(&t, @encode(unsigned int)) == 0) {
            type = "unsigned int";
        } else if (strcmp(&t, @encode(unsigned short)) == 0) {
            type = "unsigned short";
        } else if (strcmp(&t, @encode(unsigned long)) == 0) {
            type = "unsigned long";
        } else if (strcmp(&t, @encode(unsigned long long)) == 0) {
            type = "unsigned long long";
        } else if (strcmp(&t, @encode(float)) == 0) {
            type = "float";
        } else if (strcmp(&t, @encode(double)) == 0) {
            type = "double";
        } else if (strcmp(&t, @encode(_Bool)) == 0 || strcmp(&t, @encode(bool)) == 0) {
            type = "BOOL";
        } else if (strcmp(&t, @encode(void)) == 0) {
            type = "void";
        } else if (strcmp(&t, @encode(char *)) == 0) {
            type = "char *";
        } else if (strcmp(&t, @encode(id)) == 0) {
            type = "id";
        } else if (strcmp(&t, @encode(Class)) == 0) {
            type = "Class";
        } else if (strcmp(&t, @encode(SEL)) == 0) {
            type = "SEL";
        } else {
            type = "";
        }
        
        property_data_type = [NSString stringWithFormat:@"%s", type];
    }
    return property_data_type;
}

- (BOOL)isExistProperty:(NSString *)key {
    
    Class self_class = object_getClass(self);
    
    BOOL isExsit = NO;
    
    do {
        unsigned int count = 0;
        objc_property_t *property_list = class_copyPropertyList(self_class, &count);
        
        for (int i = 0; i < count; i++) {
            
            objc_property_t property = property_list[i];
            
            NSString *name = [NSString stringWithUTF8String:property_getName(property)];
            
            if ([name isEqualToString:key]) {
                
                isExsit = YES;
                break;
            }
        }
        
        free(property_list);
        
        self_class = class_getSuperclass(self_class);
        
        if (self_class == [NSObject class]) {
            break;
        }
        
    } while (!isExsit);
    
    return isExsit;
}

- (NSMutableDictionary *)get_propertyInfo {
    
    NSMutableDictionary *propertyInfo = [NSMutableDictionary dictionaryWithCapacity:1];
    
    Class self_class = object_getClass(self);
    
    do {
        unsigned int count = 0;
        objc_property_t *property_list = class_copyPropertyList(self_class, &count);
        
        for (int i = 0; i < count; i++) {
            
            objc_property_t property = property_list[i];
            
            NSString *name = [NSString stringWithUTF8String:property_getName(property)];
            id value = [self valueForKey:name];
//            NSLog(@"key:%@ value:%@",name,value);
            if (propertyInfo[name] || !value) {
                continue;
            }
            
            if ([value isKindOfClass:[NSValue class]] || [value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSData class]] || [value isKindOfClass:[NSDate class]]) {
                
                [propertyInfo setObject:value forKey:name];
            }
            else if ([value isKindOfClass:[NSDictionary class]]) {
                
                [propertyInfo setObject:[NSObject dictionaryParse:value] forKey:name];
            }
            else if ([value isKindOfClass:[NSArray class]]) {
                
                [propertyInfo setObject:[NSObject arrayParse:value] forKey:name];
            }
            else {
                [propertyInfo setObject:[value get_propertyInfo] forKey:name];
            }
        }
        
        free(property_list);
        
        self_class = class_getSuperclass(self_class);
        
        if (self_class == [NSObject class]) {
            break;
        }
        
    } while (1);
    
    return propertyInfo;
}

+ (NSMutableDictionary *)dictionaryParse:(NSDictionary *)dic {
    
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    
    for (NSString *key in [dic allKeys]) {
        
        id value = [dic objectForKey:key];
        
        if (([value isKindOfClass:[NSNumber class]] || [value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSData class]] || [value isKindOfClass:[NSDate class]])) {
            
            [info setObject:value forKey:key];
        }
        else if ([value isKindOfClass:[NSDictionary class]]) {
            
            NSDictionary *tmp = [self dictionaryParse:value];
            
            [info setObject:tmp forKey:key];
        }
        else if ([value isKindOfClass:[NSArray class]]) {
            
            NSArray *tmp = [self arrayParse:value];
            
            [info setObject:tmp forKey:key];
        }
        else {
            NSDictionary *tmp = [value get_propertyInfo];
            
            [info setObject:tmp forKey:key];
        }
    }
    
    return info;
}

+ (NSMutableArray *)arrayParse:(NSArray *)array {
    
    NSMutableArray *tmp = [NSMutableArray array];
    
    for (id value in array) {
        
        if (([value isKindOfClass:[NSNumber class]] || [value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSData class]] || [value isKindOfClass:[NSDate class]])) {
            
            [tmp addObject:value];
        }
        else if ([value isKindOfClass:[NSDictionary class]]) {
            
            NSDictionary *dic = [self dictionaryParse:value];
            
            [tmp addObject:dic];
        }
        else if ([value isKindOfClass:[NSArray class]]) {
            
            NSArray *dic = [self arrayParse:value];
            
            [tmp addObject:dic];
        }
        else {
            NSDictionary *dic = [value get_propertyInfo];
            
            [tmp addObject:dic];
        }
    }
    
    return tmp;
}

@end
