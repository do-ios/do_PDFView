//
//  doPDFViewItem.m
//  Do_Test
//
//  Created by yz on 16/9/22.
//  Copyright © 2016年 DoExt. All rights reserved.
//

#import "doPDFViewItem.h"

@interface doPDFViewItem ()<UIGestureRecognizerDelegate>

@end

@implementation doPDFViewItem
{
    CGPDFDocumentRef docRef;
    NSInteger currentIndex;
    NSString *totalCount;
    UISwipeGestureRecognizer *_fromRightSwip;
    UISwipeGestureRecognizer *_fromLeftSwip;
    NSCache *dataCache;
    
    CGFloat lastScale;
}

#pragma mark - 重写父类方法
//初始化
- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        dataCache = [[NSCache alloc]init];
        dataCache.countLimit = 20;
        dataCache.totalCostLimit =  40*1024*1024;
        currentIndex = 1;
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}
- (void)dealloc
{
    if (docRef) {
        CGPDFDocumentRelease(docRef);
    }
    _fromLeftSwip.delegate = nil;
    _fromRightSwip.delegate = nil;
    [self removeGestureRecognizer:_fromRightSwip];
    [self removeGestureRecognizer:_fromLeftSwip];
    [dataCache removeAllObjects];
    dataCache = nil;
    
}
//绘制
- (void)drawRect:(CGRect)rect
{
    if (!docRef) {
        return;
    }
    CGContextRef context = UIGraphicsGetCurrentContext(); // 获取当前的绘图上下文
    [[UIColor whiteColor] set];
    CGContextFillRect(context, rect);
    
    CGPDFPageRef pdfPage = CGPDFDocumentGetPage(docRef, currentIndex);
    CGRect mediaRect = CGPDFPageGetBoxRect(pdfPage, kCGPDFCropBox);
    
    CGFloat width = mediaRect.size.width;
    CGFloat height = mediaRect.size.height;
    CGFloat scaledWidth = rect.size.width;
    CGFloat scaledHeight = rect.size.height;
    CGFloat targetWidth = rect.size.width;
    CGFloat targetHeight = rect.size.height;
    
    CGFloat scaleFactor = 0.0;
//    CGFloat widthFactor = targetWidth / width;
//    CGFloat heightFactor = targetHeight / height;
    if(CGSizeEqualToSize(rect.size, mediaRect.size) == NO){
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        if(widthFactor < heightFactor){
            scaleFactor = widthFactor;
        }else{
            scaleFactor = heightFactor;
        }
        scaledWidth = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
    }
    CGContextScaleCTM(context, 1 * scaleFactor, -1 * scaleFactor);
    CGContextTranslateCTM(context, 0, -mediaRect.size.height - mediaRect.origin.y);
    CGContextDrawPDFPage(context, pdfPage); // 绘制当前页面
}

#pragma mark - setter 方法
- (void)setFilePath:(NSURL *)filePath
{
    _filePath = filePath;
    docRef = (__bridge CGPDFDocumentRef)([dataCache objectForKey:filePath]);
    if (!docRef) {
        docRef = [self GetPDFDocRef:filePath];
        [dataCache setObject:(__bridge id _Nonnull)(docRef) forKey:filePath];
    }
    currentIndex = 1;
    size_t count;
    count = CGPDFDocumentGetNumberOfPages(docRef);//共有多少页
    totalCount = [NSString stringWithFormat:@"%zd", count];
    
    _fromRightSwip = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(nextPage:)];
    _fromRightSwip.direction = UISwipeGestureRecognizerDirectionUp;
    [self addGestureRecognizer:_fromRightSwip];
    _fromRightSwip.delegate = self;
    _fromLeftSwip = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(forwardPage:)];
    _fromLeftSwip.direction = UISwipeGestureRecognizerDirectionDown;
    _fromLeftSwip.delegate = self;
    [self addGestureRecognizer:_fromLeftSwip];
    
    [self setNeedsDisplay];
}
#pragma mark - public 方法
- (NSString *)getCurrentIndex
{
    return [NSString stringWithFormat:@"%ld",(long)currentIndex];
}
- (NSString *)getPageCount
{
    return totalCount;
}

- (void)jump:(int)pageIndex
{
    if (currentIndex == pageIndex) {
        return;
    }
    currentIndex = pageIndex;
    if (currentIndex < 1) {
        currentIndex = 1;
    }
    if(currentIndex > [totalCount integerValue])
    {
        currentIndex = [totalCount integerValue];
    }
    [self setNeedsDisplay];
    if ([self.delegate respondsToSelector:@selector(doPDFViewItemIndexDidChange:widthCurrentIndex:)]) {
        [self.delegate doPDFViewItemIndexDidChange:totalCount widthCurrentIndex:[NSString stringWithFormat:@"%ld",(long)currentIndex]];
    }
}

- (void)next
{
    currentIndex ++;
    if (currentIndex > [totalCount integerValue]) {
        currentIndex= [totalCount integerValue];
        return;
    }
    [self setNeedsDisplay];
    if ([self.delegate respondsToSelector:@selector(doPDFViewItemIndexDidChange:widthCurrentIndex:)]) {
        [self.delegate doPDFViewItemIndexDidChange:totalCount widthCurrentIndex:[NSString stringWithFormat:@"%ld",(long)currentIndex]];
    }
}
- (void)prev
{
    currentIndex--;
    if (currentIndex < 1) {
        currentIndex = 1;
        return;
    }
    [self setNeedsDisplay];
    if ([self.delegate respondsToSelector:@selector(doPDFViewItemIndexDidChange:widthCurrentIndex:)]) {
        [self.delegate doPDFViewItemIndexDidChange:totalCount widthCurrentIndex:[NSString stringWithFormat:@"%ld",(long)currentIndex]];
    }
}
#pragma mark - 手势
-(void)nextPage:(UISwipeGestureRecognizer*)sender
{
    if (currentIndex == [totalCount integerValue])return;
    NSString *subtypeString;
    [self transitionWithType:@"pageCurl" WithSubtype:subtypeString ForView:self];
    [self next];
}

- (void)forwardPage:(UISwipeGestureRecognizer *)sender
{
    if (currentIndex == 1)return;
    NSString *subtypeString;
    [self transitionWithType:@"pageUnCurl" WithSubtype:subtypeString ForView:self];
    [self prev];
}

#pragma mark - 私有方法
- (CGPDFDocumentRef)GetPDFDocRef:(NSURL *)url
{
    CGPDFDocumentRef document;
    size_t count;
    document = CGPDFDocumentCreateWithURL((__bridge CFURLRef)url);
    count = CGPDFDocumentGetNumberOfPages(document);//共有多少页
    
    if (count == 0) {
        return NULL;
    }
    if (docRef) {
        count = CGPDFDocumentGetNumberOfPages(docRef);//共有多少页
    }
    totalCount = [NSString stringWithFormat:@"%zd", count];
    NSLog(@"totalCount = %zd",count);
    return document;
}

//翻页动画
- (void) transitionWithType:(NSString *) type WithSubtype:(NSString *) subtype ForView : (UIView *) view {
    CATransition *animation = [CATransition animation];
    animation.duration = 0.7f;
    animation.type = type;
    if (subtype != nil) {
        animation.subtype = subtype;
    }
    animation.timingFunction = UIViewAnimationOptionCurveEaseInOut;
    [view.layer addAnimation:animation forKey:@"animation"];
}
#pragma  mark UIGestureRecognizerDelegate 方法
//处理清扫手势和UIScrollView滑动手势冲突
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    // 如果otherGestureRecognizer是scrollview 判断scrollview的contentOffset 是否小于等于0，YES cancel scrollview 的手势，否cancel自己

    if ([[otherGestureRecognizer view] isKindOfClass:[UIScrollView class]]) {
        
        UIScrollView *scrollView = (UIScrollView *)[otherGestureRecognizer view];
        if (scrollView.contentOffset.y <= 0) {
            return YES;
            
        }else if((scrollView.contentOffset.y + scrollView.frame.size.height + 1) >= scrollView.contentSize.height){
            return YES;
        }
    }
    return NO;
}
@end

