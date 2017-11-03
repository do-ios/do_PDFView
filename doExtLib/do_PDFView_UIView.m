//
//  do_PDFView_View.m
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_PDFView_UIView.h"

#import "doInvokeResult.h"
#import "doUIModuleHelper.h"
#import "doScriptEngineHelper.h"
#import "doIScriptEngine.h"
#import "doIOHelper.h"
#import "doIPage.h"
#import "doJsonHelper.h"
#import "doPDFViewItem.h"
#import "doServiceContainer.h"
#import "doILogEngine.h"


#define PDFvaild BOOL vaild = [self verifyPDF];if (!vaild){ return;}


@interface do_PDFView_UIView()<UIScrollViewDelegate,doPDFViewItemDelegate>

@end

@implementation do_PDFView_UIView
{
    CGPDFDocumentRef docRef;

    CGFloat lastScale;
    doPDFViewItem *pdfView;
    UIScrollView *scaleView;
}
#pragma mark - doIUIModuleView协议方法（必须）
//引用Model对象
- (void) LoadView: (doUIModule *) _doUIModule
{
    _model = (typeof(_model)) _doUIModule;
    pdfView = [[doPDFViewItem alloc]initWithFrame:CGRectMake(0, 0, _model.RealWidth, _model.RealHeight)];
    pdfView.delegate = self;
    scaleView = [[UIScrollView alloc]initWithFrame:CGRectMake(0, 0, _model.RealWidth, _model.RealHeight)];
    scaleView.delegate = self;
    scaleView.minimumZoomScale = 1;
    scaleView.maximumZoomScale = 2;
    scaleView.showsHorizontalScrollIndicator = NO;
    scaleView.showsVerticalScrollIndicator = NO;
    scaleView.bounces = NO;
    scaleView.backgroundColor = [UIColor clearColor];
    [scaleView addSubview:pdfView];
    
    [self addSubview:scaleView];
}
//销毁所有的全局对象
- (void) OnDispose
{
    //自定义的全局属性,view-model(UIModel)类销毁时会递归调用<子view-model(UIModel)>的该方法，将上层的引用切断。所以如果self类有非原生扩展，需主动调用view-model(UIModel)的该方法。(App || Page)-->强引用-->view-model(UIModel)-->强引用-->view
    [pdfView removeFromSuperview];
    pdfView.delegate = nil;
    pdfView = nil;
    [scaleView removeFromSuperview];
    scaleView.delegate = nil;
    scaleView = nil;
}
//实现布局
- (void) OnRedraw
{
    //实现布局相关的修改,如果添加了非原生的view需要主动调用该view的OnRedraw，递归完成布局。view(OnRedraw)<显示布局>-->调用-->view-model(UIModel)<OnRedraw>
    
    //重新调整视图的x,y,w,h
    [doUIModuleHelper OnRedraw:_model];
    scaleView.frame = CGRectMake(0, 0, _model.RealWidth, _model.RealHeight);
}

#pragma mark - TYPEID_IView协议方法（必须）
#pragma mark - Changed_属性
/*
 如果在Model及父类中注册过 "属性"，可用这种方法获取
 NSString *属性名 = [(doUIModule *)_model GetPropertyValue:@"属性名"];
 
 获取属性最初的默认值
 NSString *属性名 = [(doUIModule *)_model GetProperty:@"属性名"].DefaultValue;
 */
- (void)change_url:(NSString *)newValue
{
    //自己的代码实现
    NSString *filePath = [doIOHelper GetLocalFileFullPath:_model.CurrentPage.CurrentApp :newValue];
    BOOL exist = [doIOHelper ExistFile:filePath];
    if (!exist) {
        [[doServiceContainer Instance].LogEngine WriteError:nil :@"url无效"];
        return;
    }
    NSURL *url = [NSURL fileURLWithPath:filePath];
    
    pdfView.filePath = url;
}
#pragma mark - 同步异步方法的实现
//同步
- (void)getPageCount:(NSArray *)parms
{
    PDFvaild;
    doInvokeResult *_invokeResult = [parms objectAtIndex:2];
    //_invokeResult设置返回值
    NSString *currentIndex = [pdfView getCurrentIndex];
    NSString *totalCount = [pdfView getPageCount];
    NSMutableDictionary *node = [NSMutableDictionary dictionary];
    [node setObject:totalCount forKey:@"total"];
    [node setObject:currentIndex forKey:@"current"];
    [_invokeResult SetResultNode:node];
}
- (void)jump:(NSArray *)parms
{
    PDFvaild;
    NSDictionary *_dictParas = [parms objectAtIndex:0];
 
    int pageIndex = [doJsonHelper GetOneInteger:_dictParas :@"page" :1];
    if (pageIndex < 1 || pageIndex > ([pdfView getPageCount].integerValue)) { // page 不在范围直接返回
        return;
    }
    [pdfView jump:pageIndex];
    
}
- (void)next:(NSArray *)parms
{
    PDFvaild;
    [pdfView next];
}
- (void)prev:(NSArray *)parms
{
    PDFvaild;
    [pdfView prev];
}
//验证pdf是否有效
- (BOOL)verifyPDF
{
    if (pdfView.filePath)
    {
        return YES;
    }
    else
    {
        [[doServiceContainer Instance].LogEngine WriteError:nil :@"url无效"];
        return NO;
    }
}
#pragma mark - doPDFViewItemDelegate 方法
- (void)doPDFViewItemIndexDidChange:(NSString *)totalPage widthCurrentIndex:(NSString *)currentIndex
{
    doInvokeResult *invokeResult = [[doInvokeResult alloc]init:_model.UniqueKey];
    NSMutableDictionary *node = [NSMutableDictionary dictionary];
    [node setObject:totalPage forKey:@"total"];
    [node setObject:currentIndex forKey:@"current"];
    [invokeResult SetResultNode:node];
    [_model.EventCenter FireEvent:@"pageChanged" :invokeResult];
    
}
#pragma  mark -  UIScrollViewDelegate 方法
- (nullable UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return pdfView;
}
#pragma mark - doIUIModuleView协议方法（必须）<大部分情况不需修改>
- (BOOL) OnPropertiesChanging: (NSMutableDictionary *) _changedValues
{
    //属性改变时,返回NO，将不会执行Changed方法
    return YES;
}
- (void) OnPropertiesChanged: (NSMutableDictionary*) _changedValues
{
    //_model的属性进行修改，同时调用self的对应的属性方法，修改视图
    [doUIModuleHelper HandleViewProperChanged: self :_model : _changedValues ];
}
- (BOOL) InvokeSyncMethod: (NSString *) _methodName : (NSDictionary *)_dicParas :(id<doIScriptEngine>)_scriptEngine : (doInvokeResult *) _invokeResult
{
    //同步消息
    return [doScriptEngineHelper InvokeSyncSelector:self : _methodName :_dicParas :_scriptEngine :_invokeResult];
}
- (BOOL) InvokeAsyncMethod: (NSString *) _methodName : (NSDictionary *) _dicParas :(id<doIScriptEngine>) _scriptEngine : (NSString *) _callbackFuncName
{
    //异步消息
    return [doScriptEngineHelper InvokeASyncSelector:self : _methodName :_dicParas :_scriptEngine: _callbackFuncName];
}
- (doUIModule *) GetModel
{
    //获取model对象
    return _model;
}

@end
