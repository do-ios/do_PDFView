//
//  do_PDFView_UI.h
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol do_PDFView_IView <NSObject>

@required
//属性方法
- (void)change_url:(NSString *)newValue;

//同步或异步方法
- (void)getPageCount:(NSArray *)parms;
- (void)jump:(NSArray *)parms;
- (void)next:(NSArray *)parms;
- (void)prev:(NSArray *)parms;


@end