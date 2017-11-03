//
//  doPDFViewItem.h
//  Do_Test
//
//  Created by yz on 16/9/22.
//  Copyright © 2016年 DoExt. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol doPDFViewItemDelegate <NSObject>

@optional
- (void) doPDFViewItemIndexDidChange:(NSString *)totalPage widthCurrentIndex:(NSString *)currentIndex;
@end

@interface doPDFViewItem : UIView
@property (nonatomic,strong) NSURL *filePath;
@property (nonatomic,weak) id<doPDFViewItemDelegate>delegate;
- (void)next;
- (void)prev;
- (void)jump:(int)pageIndex;
- (NSString *)getCurrentIndex;
- (NSString *)getPageCount;
@end
