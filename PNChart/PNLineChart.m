//
//  PNLineChart.m
//  PNChartDemo
//
//  Created by kevin on 11/7/13.
//  Copyright (c) 2013年 kevinzhow. All rights reserved.
//

#import "PNLineChart.h"
#import "PNColor.h"
#import "PNChartLabel.h"
#import "PNLineChartData.h"
#import "PNLineChartDataItem.h"
#import <CoreText/CoreText.h>

@interface PNLineChart ()

@property (nonatomic) NSMutableArray *chartLineArray;  // Array[CAShapeLayer]
@property (nonatomic) NSMutableArray *chartPointArray; // Array[CAShapeLayer] save the point layer

@property (nonatomic) NSMutableArray *chartPath;       // Array of line path, one for each line.
@property (nonatomic) NSMutableArray *pointPath;       // Array of point path, one for each line
@property (nonatomic) NSMutableArray *endPointsOfPath;      // Array of start and end points of each line path, one for each line

// display grade
@property (nonatomic) NSMutableArray *gradeStringPaths;

@end

@implementation PNLineChart

#pragma mark initialization

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];

    if (self) {
        [self setupDefaultValues];
    }

    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self) {
        [self setupDefaultValues];
    }

    return self;
}


#pragma mark instance methods

- (void)setYLabels
{
    CGFloat yStep = (_yValueMax - _yValueMin) / _yLabelNum;
    CGFloat yStepHeight = _chartCavanHeight / _yLabelNum;

    if (_yChartLabels) {
        for (PNChartLabel * label in _yChartLabels) {
            [label removeFromSuperview];
        }
    }else{
        _yChartLabels = [NSMutableArray new];
    }

    if (yStep == 0.0) {
        PNChartLabel *minLabel = [[PNChartLabel alloc] initWithFrame:CGRectMake(0.0, (NSInteger)_chartCavanHeight, (NSInteger)_chartMarginBottom, (NSInteger)_yLabelHeight)];
        minLabel.text = [self formatYLabel:0.0];
        [self setCustomStyleForYLabel:minLabel];
        [self addSubview:minLabel];
        [_yChartLabels addObject:minLabel];

        PNChartLabel *midLabel = [[PNChartLabel alloc] initWithFrame:CGRectMake(0.0, (NSInteger)(_chartCavanHeight / 2), (NSInteger)_chartMarginBottom, (NSInteger)_yLabelHeight)];
        midLabel.text = [self formatYLabel:_yValueMax];
        [self setCustomStyleForYLabel:midLabel];
        [self addSubview:midLabel];
        [_yChartLabels addObject:midLabel];

        PNChartLabel *maxLabel = [[PNChartLabel alloc] initWithFrame:CGRectMake(0.0, 0.0, (NSInteger)_chartMarginBottom, (NSInteger)_yLabelHeight)];
        maxLabel.text = [self formatYLabel:_yValueMax * 2];
        [self setCustomStyleForYLabel:maxLabel];
        [self addSubview:maxLabel];
        [_yChartLabels addObject:maxLabel];

    } else {
        NSInteger index = 0;
        NSInteger num = _yLabelNum + 1;

        while (num > 0)
        {
            PNChartLabel *label = [[PNChartLabel alloc] initWithFrame:CGRectMake(0.0, (NSInteger)(_chartCavanHeight - index * yStepHeight), (NSInteger)_chartMarginBottom, (NSInteger)_yLabelHeight)];
            [label setTextAlignment:NSTextAlignmentRight];
            label.text = [self formatYLabel:_yValueMin + (yStep * index)];
            [self setCustomStyleForYLabel:label];
            [self addSubview:label];
            [_yChartLabels addObject:label];
            index += 1;
            num -= 1;
        }
    }
}

- (void)setYLabels:(NSArray *)yLabels
{
    _showGenYLabels = NO;
    _yLabelNum = yLabels.count - 1;
    
    //==============================
    //      Gevin Modified
    //==============================
    _yLabels = yLabels;
//    _yLabelHeight = yLabelHeight;
    if (_yChartLabels) {
        for (PNChartLabel * label in _yChartLabels) {
            [label removeFromSuperview];
        }
    }else{
        _yChartLabels = [NSMutableArray new];
    }
    
    NSString *labelText;
    
    if (_showLabel) {
        CGFloat yStepHeight = _chartCavanHeight / _yLabelNum;
        for (int index = 0; index < yLabels.count; index++) {
            labelText = yLabels[index];
            PNChartLabel *label = [[PNChartLabel alloc] initWithFrame:CGRectMake(0.0, _chartCavanOrigin.y - _chartStrokeOffset.y - (index * yStepHeight) - (_yLabelHeight/2) , (NSInteger)_chartMarginLeft * 0.9, (NSInteger)_yLabelHeight)];
            [label setTextAlignment:NSTextAlignmentRight];
            label.text = labelText;
            [self setCustomStyleForYLabel:label];
            [self addSubview:label];
            [_yChartLabels addObject:label];
        }
    }
}

- (CGFloat)computeEqualWidthForXLabels:(NSArray *)xLabels
{
    CGFloat xLabelWidth;

    if (_showLabel) {
        xLabelWidth = _chartCavanWidth / [xLabels count];
    } else {
        xLabelWidth = (self.frame.size.width) / [xLabels count];
    }

    return xLabelWidth;
}


- (void)setXLabels:(NSArray *)xLabels
{
    CGFloat xLabelWidth;

    if (_showLabel) {
        xLabelWidth = _chartCavanWidth / [xLabels count];
    } else {
        xLabelWidth = (self.frame.size.width - _chartMarginLeft - _chartMarginRight) / [xLabels count];
    }

    return [self setXLabels:xLabels withWidth:xLabelWidth];
}

- (void)setXLabels:(NSArray *)xLabels withWidth:(CGFloat)width
{
    _xLabels = xLabels;
    _xLabelWidth = width;
    _xSeparateInterval = _chartCavanWidth / [xLabels count];
    if (_xChartLabels) {
        for (PNChartLabel * label in _xChartLabels) {
            [label removeFromSuperview];
        }
    }else{
        _xChartLabels = [NSMutableArray new];
    }
    
    NSString *labelText;

    if (_showLabel) {
        for (int index = 0; index < xLabels.count; index++) {
            labelText = xLabels[index];

            NSInteger x = _chartCavanOrigin.x + _chartStrokeOffset.x + ( index *  _xSeparateInterval ) - (_xLabelWidth/2) ;
            NSInteger y = _chartCavanOrigin.y;

            PNChartLabel *label = [[PNChartLabel alloc] initWithFrame:CGRectMake(x, y, (NSInteger)_xLabelWidth, (NSInteger)_chartMarginBottom)];
            [label setTextAlignment:NSTextAlignmentCenter];
            label.text = labelText;
            [self setCustomStyleForXLabel:label];
            [self addSubview:label];
            [_xChartLabels addObject:label];
        }
    }
}

- (void)setCustomStyleForXLabel:(UILabel *)label
{
    if (_xLabelFont) {
        label.font = _xLabelFont;
    }

    if (_xLabelColor) {
        label.textColor = _xLabelColor;
    }

}

- (void)setCustomStyleForYLabel:(UILabel *)label
{
    if (_yLabelFont) {
        label.font = _yLabelFont;
    }

    if (_yLabelColor) {
        label.textColor = _yLabelColor;
    }
}


// gevin added
- (void)setChartMarginBottom:(CGFloat)chartMarginBottom
{
    _chartMarginBottom = chartMarginBottom;
    [self updateCoordinate];
}

- (void)setChartMarginTop:(CGFloat)chartMarginTop
{
    _chartMarginTop = chartMarginTop;
    [self updateCoordinate];
}

- (void)setChartMarginLeft:(CGFloat)chartMarginLeft
{
    _chartMarginLeft = chartMarginLeft;
    [self updateCoordinate];
}

- (void)setChartMarginRight:(CGFloat)chartMarginRight
{
    _chartMarginRight = chartMarginRight;
    [self updateCoordinate];
}


- (void)updateCoordinate
{
    _chartCavanWidth = self.frame.size.width - _chartMarginLeft - _chartMarginRight;
    _chartCavanHeight = self.frame.size.height - _chartMarginBottom - _chartMarginTop;
    _chartCavanOrigin = CGPointMake( _chartMarginLeft, _chartMarginTop + _chartCavanHeight );
    _chartStrokeOffset = CGPointMake( 10.0f, 10.0f );
}

#pragma mark - Touch at point

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    // Gevin modify
    if ( _delegate ) {
        [self touchPoint:touches withEvent:event];
        [self touchKeyPoint:touches withEvent:event];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    // Gevin modify
    if ( _delegate ) {
        [self touchPoint:touches withEvent:event];
        [self touchKeyPoint:touches withEvent:event];
    }
}

- (void)touchPoint:(NSSet *)touches withEvent:(UIEvent *)event
{
    // Get the point user touched
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self];

    for (NSInteger p = _pathPoints.count - 1; p >= 0; p--) {
        NSArray *linePointsArray = _endPointsOfPath[p];

        for (int i = 0; i < linePointsArray.count - 1; i += 2) {
            CGPoint p1 = [linePointsArray[i] CGPointValue];
            CGPoint p2 = [linePointsArray[i + 1] CGPointValue];

            // Closest distance from point to line
            float distance = fabs(((p2.x - p1.x) * (touchPoint.y - p1.y)) - ((p1.x - touchPoint.x) * (p1.y - p2.y)));
            distance /= hypot(p2.x - p1.x, p1.y - p2.y);

            if (distance <= 5.0) {
                // Conform to delegate parameters, figure out what bezier path this CGPoint belongs to.
                for (UIBezierPath *path in _chartPath) {
                    BOOL pointContainsPath = CGPathContainsPoint(path.CGPath, NULL, p1, NO);

                    if (pointContainsPath) {
                        // Gevin added
                        if ( [_delegate respondsToSelector:@selector(userClickedOnLinePoint:lineIndex:) ]) {
                            [_delegate userClickedOnLinePoint:touchPoint lineIndex:[_chartPath indexOfObject:path]];                            
                        }

                        return;
                    }
                }
            }
        }
    }
}

- (void)touchKeyPoint:(NSSet *)touches withEvent:(UIEvent *)event
{
    // Get the point user touched
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self];

    for (NSInteger p = _pathPoints.count - 1; p >= 0; p--) {
        NSArray *linePointsArray = _pathPoints[p];

        for (int i = 0; i < linePointsArray.count - 1; i += 1) {
            CGPoint p1 = [linePointsArray[i] CGPointValue];
            CGPoint p2 = [linePointsArray[i + 1] CGPointValue];

            float distanceToP1 = fabs(hypot(touchPoint.x - p1.x, touchPoint.y - p1.y));
            float distanceToP2 = hypot(touchPoint.x - p2.x, touchPoint.y - p2.y);

            float distance = MIN(distanceToP1, distanceToP2);

            if (distance <= 10.0) {
                // Gevin added
                if ( [_delegate respondsToSelector:@selector(userClickedOnLineKeyPoint:lineIndex:pointIndex:)]) {
                    [_delegate userClickedOnLineKeyPoint:touchPoint
                                               lineIndex:p
                                              pointIndex:(distance == distanceToP2 ? i + 1 : i)];
                }

                return;
            }
        }
    }
}

#pragma mark - Draw Chart

- (void)strokeChart
{
    _chartPath = [[NSMutableArray alloc] init];
    _pointPath = [[NSMutableArray alloc] init];
    _gradeStringPaths = [NSMutableArray array];

    [self calculateChartPath:_chartPath andPointsPath:_pointPath andPathKeyPoints:_pathPoints andPathStartEndPoints:_endPointsOfPath];
    // Draw each line
    for (NSUInteger lineIndex = 0; lineIndex < self.chartData.count; lineIndex++) {
        PNLineChartData *chartData = self.chartData[lineIndex];
        CAShapeLayer *lineLayer = (CAShapeLayer *)self.chartLineArray[lineIndex];
        CAShapeLayer *pointLayer = (CAShapeLayer *)self.chartPointArray[lineIndex];
        UIGraphicsBeginImageContext(self.frame.size);
        // setup the color of the chart line
        if (chartData.color) {
            lineLayer.strokeColor = [[chartData.color colorWithAlphaComponent:chartData.alpha]CGColor];
        } else {
            lineLayer.strokeColor = [PNGreen CGColor];
            pointLayer.strokeColor = [PNGreen CGColor];
        }
        
        UIBezierPath *linePath = [_chartPath objectAtIndex:lineIndex];
        UIBezierPath *pointPath = [_pointPath objectAtIndex:lineIndex];

        lineLayer.path = linePath.CGPath;
        pointLayer.path = pointPath.CGPath;

        [CATransaction begin];
        CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        pathAnimation.duration = 1.0;
        pathAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        pathAnimation.fromValue = @0.0f;
        pathAnimation.toValue   = @1.0f;

        [lineLayer addAnimation:pathAnimation forKey:@"strokeEndAnimation"];
        lineLayer.strokeEnd = 1.0;

        // if you want cancel the point animation, conment this code, the point will show immediately
        if (chartData.inflexionPointStyle != PNLineChartPointStyleNone) {
            [pointLayer addAnimation:pathAnimation forKey:@"strokeEndAnimation"];
        }

        [CATransaction commit];
        
        NSMutableArray* textLayerArray = [self.gradeStringPaths objectAtIndex:lineIndex];
        for (CATextLayer* textLayer in textLayerArray) {
            CABasicAnimation* fadeAnimation = [self fadeAnimation];
            [textLayer addAnimation:fadeAnimation forKey:nil];
        }

        UIGraphicsEndImageContext();
    }
}


- (void)calculateChartPath:(NSMutableArray *)chartPath andPointsPath:(NSMutableArray *)pointsPath andPathKeyPoints:(NSMutableArray *)pathPoints andPathStartEndPoints:(NSMutableArray *)pointsOfPath
{
    
    // Draw each line
    for (NSUInteger lineIndex = 0; lineIndex < self.chartData.count; lineIndex++) {
        PNLineChartData *chartData = self.chartData[lineIndex];
        
        CGFloat yValue;
        
        UIBezierPath *progressline = [UIBezierPath bezierPath];
        
        UIBezierPath *pointPath = [UIBezierPath bezierPath];
        
        
        [chartPath insertObject:progressline atIndex:lineIndex];
        [pointsPath insertObject:pointPath atIndex:lineIndex];
        
        
        NSMutableArray* gradePathArray = [NSMutableArray array];
        [self.gradeStringPaths addObject:gradePathArray];
        

        if (!_showLabel) {
            _chartCavanHeight = self.frame.size.height - 2 * _yLabelHeight;
            _chartCavanWidth = self.frame.size.width;
            //_chartMargin = chartData.inflexionPointWidth;
            _xSeparateInterval = (_chartCavanWidth / ([_xLabels count] - 1));
        }
        
        NSMutableArray *linePointsArray = [[NSMutableArray alloc] init];
        NSMutableArray *lineStartEndPointsArray = [[NSMutableArray alloc] init];
        CGFloat inflexionWidth = chartData.inflexionPointWidth;
        CGPoint lastCenter = CGPointZero;
        
        // draw each point
        for (NSUInteger i = 0; i < chartData.itemCount; i++) {
            
            yValue = chartData.getData(i).y;
            if ( yValue == -1 ) {
                continue;
            }
            CGPoint chartStrokeOrigin = (CGPoint){ _chartCavanOrigin.x + _chartStrokeOffset.x, _chartCavanOrigin.y - _chartStrokeOffset.y };
            //  y 在計算 yValue : yValueMax 對映 y : _chartCavanHeight， y = ( yValue / yValueMax ) * _chartCavanHeight，然後因為座標是相反的，所以用減，畫出來才會是往上
            float valueHeight = ( yValue / _yValueMax ) * _chartCavanHeight;
            CGPoint itemCenter = CGPointMake( chartStrokeOrigin.x + (i * _xSeparateInterval), chartStrokeOrigin.y - valueHeight );
            CGRect  itemRect = CGRectMake( itemCenter.x - inflexionWidth / 2, itemCenter.y - inflexionWidth / 2, inflexionWidth, inflexionWidth);
            // Circular point
            if (chartData.inflexionPointStyle == PNLineChartPointStyleCircle) {
                                
                [pointPath moveToPoint:CGPointMake( itemCenter.x + (inflexionWidth / 2), itemCenter.y)];
                [pointPath addArcWithCenter:itemCenter radius:inflexionWidth / 2 startAngle:0 endAngle:2 * M_PI clockwise:YES];
                
                //jet text display text
                if (chartData.showPointLabel == YES) {
                    [gradePathArray addObject:[self createPointLabelFor:chartData.getData(i).rawY pointCenter:itemCenter width:inflexionWidth withChartData:chartData]];
                }
                
                if ( i != 0 ) {
                    [progressline moveToPoint:lastCenter];
                    [progressline addLineToPoint:itemCenter];

                    [lineStartEndPointsArray addObject:[NSValue valueWithCGPoint:lastCenter]];
                    [lineStartEndPointsArray addObject:[NSValue valueWithCGPoint:itemCenter]];
                    
                }
                
                lastCenter = itemCenter;
            }
            // Square point
            else if (chartData.inflexionPointStyle == PNLineChartPointStyleSquare) {
                
                [pointPath moveToPoint:CGPointMake(itemCenter.x - (inflexionWidth / 2), itemCenter.y - (inflexionWidth / 2))];
                [pointPath addLineToPoint:CGPointMake(itemCenter.x + (inflexionWidth / 2), itemCenter.y - (inflexionWidth / 2))];
                [pointPath addLineToPoint:CGPointMake(itemCenter.x + (inflexionWidth / 2), itemCenter.y + (inflexionWidth / 2))];
                [pointPath addLineToPoint:CGPointMake(itemCenter.x - (inflexionWidth / 2), itemCenter.y + (inflexionWidth / 2))];
                [pointPath closePath];
                
                // text display text
                if (chartData.showPointLabel == YES) {
                    [gradePathArray addObject:[self createPointLabelFor:chartData.getData(i).rawY pointCenter:itemCenter width:inflexionWidth withChartData:chartData]];
                }
                
                if ( i != 0 ) {
                    [progressline moveToPoint:lastCenter];
                    [progressline addLineToPoint:itemCenter];
                    
                    [lineStartEndPointsArray addObject:[NSValue valueWithCGPoint:lastCenter]];
                    [lineStartEndPointsArray addObject:[NSValue valueWithCGPoint:itemCenter]];
                }
                
                lastCenter = itemCenter;
            }
            // Triangle point
            else if (chartData.inflexionPointStyle == PNLineChartPointStyleTriangle) {
                
                CGPoint startPoint = CGPointMake(itemRect.origin.x,itemRect.origin.y + itemRect.size.height);
                CGPoint endPoint = CGPointMake(itemRect.origin.x + (itemRect.size.width / 2) , itemRect.origin.y);
                CGPoint middlePoint = CGPointMake(itemRect.origin.x + (itemRect.size.width) , itemRect.origin.y + itemRect.size.height);
                
                [pointPath moveToPoint:startPoint];
                [pointPath addLineToPoint:middlePoint];
                [pointPath addLineToPoint:endPoint];
                [pointPath closePath];
                
                // text display text
                if (chartData.showPointLabel == YES) {
                    [gradePathArray addObject:[self createPointLabelFor:chartData.getData(i).rawY pointCenter:middlePoint width:inflexionWidth withChartData:chartData]];
                }
                
                if ( i != 0 ) {
                    [progressline moveToPoint:lastCenter];
                    [progressline addLineToPoint:itemCenter];
                    
                    [lineStartEndPointsArray addObject:[NSValue valueWithCGPoint:lastCenter]];
                    [lineStartEndPointsArray addObject:[NSValue valueWithCGPoint:itemCenter]];
                }
                
                lastCenter = itemCenter;
                
            } else {
                
                if ( i != 0 ) {
                    [progressline addLineToPoint:itemCenter];
                    [lineStartEndPointsArray addObject:[NSValue valueWithCGPoint:itemCenter]];
                }
                
                [progressline moveToPoint:itemCenter];
                if(i != chartData.itemCount - 1){
                    [lineStartEndPointsArray addObject:[NSValue valueWithCGPoint:itemCenter]];
                }
            }
            
            [linePointsArray addObject:[NSValue valueWithCGPoint:itemCenter]];
        }
        
        [pathPoints addObject:[linePointsArray copy]];
        [pointsOfPath addObject:[lineStartEndPointsArray copy]];
    }
}

#pragma mark - Set Chart Data

- (void)setChartData:(NSArray *)data
{
    if (data != _chartData) {

        // remove all shape layers before adding new ones
        for (CALayer *layer in self.chartLineArray) {
            [layer removeFromSuperlayer];
        }
        for (CALayer *layer in self.chartPointArray) {
            [layer removeFromSuperlayer];
        }

        [self.chartLineArray removeAllObjects];
        [self.chartPointArray removeAllObjects];
        for (PNLineChartData *chartData in data) {
            // create as many chart line layers as there are data-lines
            CAShapeLayer *chartLine = [CAShapeLayer layer];
            chartLine.lineCap       = kCALineCapButt;
            chartLine.lineJoin      = kCALineJoinMiter;
            chartLine.fillColor     = [[UIColor whiteColor] CGColor];
            chartLine.lineWidth     = chartData.lineWidth;
            chartLine.strokeEnd     = 0.0;
            [self.layer addSublayer:chartLine];
            [self.chartLineArray addObject:chartLine];

            // create point
            CAShapeLayer *pointLayer = [CAShapeLayer layer];
            pointLayer.strokeColor   = [[chartData.color colorWithAlphaComponent:chartData.alpha]CGColor];
            pointLayer.lineCap       = kCALineCapRound;
            pointLayer.lineJoin      = kCALineJoinBevel;
            pointLayer.fillColor     = nil;
            pointLayer.lineWidth     = chartData.lineWidth;
            [self.layer addSublayer:pointLayer];
            [self.chartPointArray addObject:pointLayer];
        }

        _chartData = data;
        
        [self prepareYLabelsWithData:data];

        [self setNeedsDisplay];
    }
}

-(void)prepareYLabelsWithData:(NSArray *)data
{
    CGFloat yMax = 0.0f;
    CGFloat yMin = MAXFLOAT;
    NSMutableArray *yLabelsArray = [NSMutableArray new];
    
    for (PNLineChartData *chartData in data) {
        // create as many chart line layers as there are data-lines
        for (NSUInteger i = 0; i < chartData.itemCount; i++) {
            CGFloat yValue = chartData.getData(i).y;
//            NSLog(@"prepareYLabelsWithData y:%f", yValue);
            [yLabelsArray addObject:[NSString stringWithFormat:@"%2f", yValue]];
            yMax = fmaxf(yMax, yValue);
            yMin = fminf(yMin, yValue);
            
        }
    }
    
    // Min value for Y label
    if (yMax < 5) {
        yMax = 5.0f;
    }
    
    if (yMin < 0) {
        yMin = 0.0f;
    }
    
    _yValueMin = (_yFixedValueMin > -FLT_MAX) ? _yFixedValueMin : yMin ;
    _yValueMax = (_yFixedValueMax > -FLT_MAX) ? _yFixedValueMax : yMax + yMax / 10.0;

    if (_showGenYLabels) {
        [self setYLabels];
    }
    
}

#pragma mark - Update Chart Data

- (void)updateChartData:(NSArray *)data
{
//    _chartData = data;
//    [self prepareYLabelsWithData:data];
    [self setChartData: data ];
    [self calculateChartPath:_chartPath andPointsPath:_pointPath andPathKeyPoints:_pathPoints andPathStartEndPoints:_endPointsOfPath];
    
    for (NSUInteger lineIndex = 0; lineIndex < self.chartData.count; lineIndex++) {

        PNLineChartData *chartData = self.chartData[lineIndex];

        CAShapeLayer *lineLayer = (CAShapeLayer *)self.chartLineArray[lineIndex];
        CAShapeLayer *pointLayer = (CAShapeLayer *)self.chartPointArray[lineIndex];
        
        // setup the color of the chart line
        if (chartData.color) {
            lineLayer.strokeColor = [[chartData.color colorWithAlphaComponent:chartData.alpha]CGColor];
        } else {
            lineLayer.strokeColor = [PNGreen CGColor];
            pointLayer.strokeColor = [PNGreen CGColor];
        }
        
        UIBezierPath *linePath = [_chartPath objectAtIndex:lineIndex];
        UIBezierPath *pointPath = [_pointPath objectAtIndex:lineIndex];
        
//        CABasicAnimation * pathAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
//        pathAnimation.fromValue = (id)lineLayer.path;
//        pathAnimation.toValue = (id)[linePath CGPath];
//        pathAnimation.duration = 0.5f;
//        pathAnimation.autoreverses = NO;
//        pathAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
//        [lineLayer addAnimation:pathAnimation forKey:@"animationKey"];
        CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        pathAnimation.duration = 1.0;
        pathAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        pathAnimation.fromValue = @0.0f;
        pathAnimation.toValue   = @1.0f;
        [lineLayer addAnimation:pathAnimation forKey:@"strokeEndAnimation"];
        lineLayer.strokeEnd = 1.0;
        
        
        CABasicAnimation * pointPathAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
        pointPathAnimation.fromValue = (id)pointLayer.path;
        pointPathAnimation.toValue = (id)[pointPath CGPath];
        pointPathAnimation.duration = 0.5f;
        pointPathAnimation.autoreverses = NO;
        pointPathAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [pointLayer addAnimation:pointPathAnimation forKey:@"animationKey"];
        
        lineLayer.path = linePath.CGPath;
        pointLayer.path = pointPath.CGPath;
        
        
    }
    
}

#define IOS7_OR_LATER [[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0

- (void)drawRect:(CGRect)rect
{
    if (self.isShowCoordinateAxis) {

        CGContextRef ctx = UIGraphicsGetCurrentContext();
        UIGraphicsPushContext(ctx);
        CGContextSetLineWidth(ctx, self.axisWidth);
        CGContextSetStrokeColorWithColor(ctx, [self.axisColor CGColor]);

        // draw coordinate axis
        CGContextMoveToPoint(ctx, _chartCavanOrigin.x, 0);
        CGContextAddLineToPoint(ctx, _chartCavanOrigin.x, _chartCavanOrigin.y);
        CGContextAddLineToPoint(ctx, _chartCavanOrigin.x + _chartCavanWidth, _chartCavanOrigin.y );
        CGContextStrokePath(ctx);

        // draw y axis arrow
        CGContextMoveToPoint(ctx, _chartCavanOrigin.x - 3, 6);
        CGContextAddLineToPoint(ctx, _chartCavanOrigin.x, 0);
        CGContextAddLineToPoint(ctx, _chartCavanOrigin.x + 3, 6);
        CGContextStrokePath(ctx);

        // draw x axis arrow
        CGContextMoveToPoint(ctx, _chartCavanOrigin.x + _chartCavanWidth - 6, _chartCavanOrigin.y - 3);
        CGContextAddLineToPoint(ctx, _chartCavanOrigin.x + _chartCavanWidth, _chartCavanOrigin.y  );
        CGContextAddLineToPoint(ctx, _chartCavanOrigin.x + _chartCavanWidth - 6, _chartCavanOrigin.y + 3);
        CGContextStrokePath(ctx);

        if (self.showLabel) {

            // draw x axis separator
            CGPoint point;
            for (NSUInteger i = 0; i < [self.xLabels count]; i++) {
                point = CGPointMake( _chartStrokeOffset.x + _chartCavanOrigin.x + (i * _xSeparateInterval), _chartCavanOrigin.y );
                CGContextMoveToPoint(ctx, point.x, point.y - 2);
                CGContextAddLineToPoint(ctx, point.x, point.y);
                CGContextStrokePath(ctx);
            }

            // draw y axis separator
            CGFloat yStepHeight = _chartCavanHeight / _yLabelNum;
            for (NSUInteger i = 0; i < [self.xLabels count]; i++) {
                // Gevin modified
                point = CGPointMake(_chartCavanOrigin.x, _chartCavanOrigin.y - i * yStepHeight - _chartStrokeOffset.y );
                CGContextMoveToPoint(ctx, point.x, point.y);
                CGContextAddLineToPoint(ctx, point.x + 2, point.y);
                CGContextStrokePath(ctx);
            }
        }

        UIFont *font = [UIFont systemFontOfSize:11];

        // draw y unit
        if ([self.yUnit length]) {
            CGFloat height = [PNLineChart sizeOfString:self.yUnit withWidth:30.f font:font].height;
            CGRect drawRect = CGRectMake(_chartMarginLeft + 10 + 5, 0, 30.f, height);
            [self drawTextInContext:ctx text:self.yUnit inRect:drawRect font:font];
        }

        // draw x unit
        if ([self.xUnit length]) {
            CGFloat height = [PNLineChart sizeOfString:self.xUnit withWidth:30.f font:font].height;
            CGRect drawRect = CGRectMake(CGRectGetWidth(rect) - _chartMarginLeft + 5, _chartMarginTop + _chartCavanHeight - height / 2, 25.f, height);
            [self drawTextInContext:ctx text:self.xUnit inRect:drawRect font:font];
        }
    }

    [super drawRect:rect];
}

#pragma mark private methods

- (void)setupDefaultValues
{
    [super setupDefaultValues];
    // Initialization code
    self.backgroundColor = [UIColor whiteColor];
    self.clipsToBounds   = YES;
    self.chartLineArray  = [NSMutableArray new];
    self.chartPointArray = [NSMutableArray new]; // Gevin added, did not find init
    _showLabel            = YES;
    _showGenYLabels        = YES;
    _pathPoints          = [[NSMutableArray alloc] init];
    _endPointsOfPath     = [[NSMutableArray alloc] init];
    self.userInteractionEnabled = YES;

    _yFixedValueMin = -FLT_MAX;
    _yFixedValueMax = -FLT_MAX;
    _yLabelNum = 5.0;
    _yLabelHeight = [[[[PNChartLabel alloc] init] font] pointSize] + 10;

//    _chartMargin = 40;
    
    _chartMarginLeft     = 25.0;
    _chartMarginRight    = 25.0;
    _chartMarginTop      = 25.0;
    _chartMarginBottom   = 25.0;
    
    _yLabelFormat = @"%1.f";

    _chartCavanWidth = self.frame.size.width - _chartMarginLeft - _chartMarginRight;
    _chartCavanHeight = self.frame.size.height - _chartMarginBottom - _chartMarginTop;
    _chartCavanOrigin = CGPointMake( _chartMarginLeft, _chartMarginTop + _chartCavanHeight );
    _chartStrokeOffset = CGPointMake( 10.0f, 10.0f );
    
    // Coordinate Axis Default Values
    _showCoordinateAxis = NO;
    _axisColor = [UIColor colorWithRed:0.4f green:0.4f blue:0.4f alpha:1.f];
    _axisWidth = 1.f;

}

#pragma mark - tools

+ (CGSize)sizeOfString:(NSString *)text withWidth:(float)width font:(UIFont *)font
{
    NSInteger ch;
    CGSize size = CGSizeMake(width, MAXFLOAT);

    if ([text respondsToSelector:@selector(boundingRectWithSize:options:attributes:context:)]) {
        NSDictionary *tdic = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, nil];
        size = [text boundingRectWithSize:size
                                  options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                               attributes:tdic
                                  context:nil].size;
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        size = [text sizeWithFont:font constrainedToSize:size lineBreakMode:NSLineBreakByCharWrapping];
#pragma clang diagnostic pop
    }
    ch = size.height;

    return size;
}

- (void)drawTextInContext:(CGContextRef )ctx text:(NSString *)text inRect:(CGRect)rect font:(UIFont *)font
{
    if (IOS7_OR_LATER) {
        NSMutableParagraphStyle *priceParagraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        priceParagraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
        priceParagraphStyle.alignment = NSTextAlignmentLeft;

        [text drawInRect:rect
          withAttributes:@{ NSParagraphStyleAttributeName:priceParagraphStyle, NSFontAttributeName:font }];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [text drawInRect:rect
                withFont:font
           lineBreakMode:NSLineBreakByTruncatingTail
               alignment:NSTextAlignmentLeft];
#pragma clang diagnostic pop
    }
}

- (NSString*) formatYLabel:(double)value{

    if (self.yLabelBlockFormatter)
    {
        return self.yLabelBlockFormatter(value);
    }
    else
    {
        if (!self.thousandsSeparator) {
            NSString *format = self.yLabelFormat ? : @"%1.f";
            return [NSString stringWithFormat:format,value];
        }
        
        NSNumberFormatter* numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setFormatterBehavior: NSNumberFormatterBehavior10_4];
        [numberFormatter setNumberStyle: NSNumberFormatterDecimalStyle];
        return [numberFormatter stringFromNumber: [NSNumber numberWithDouble:value]];
    }
}

- (UIView*) getLegendWithMaxWidth:(CGFloat)mWidth{
    if ([self.chartData count] < 1) {
        return nil;
    }
    
    /* This is a short line that refers to the chart data */
    CGFloat legendLineWidth = 40;
    
    /* x and y are the coordinates of the starting point of each legend item */
    CGFloat x = 0;
    CGFloat y = 0;
    
    /* accumulated height */
    CGFloat totalHeight = 0;
    CGFloat totalWidth = 0;
    
    NSMutableArray *legendViews = [[NSMutableArray alloc] init];

    /* Determine the max width of each legend item */
    CGFloat maxLabelWidth;
    if (self.legendStyle == PNLegendItemStyleStacked) {
        maxLabelWidth = mWidth - legendLineWidth;
    }else{
        maxLabelWidth = MAXFLOAT;
    }
    
    /* this is used when labels wrap text and the line 
     * should be in the middle of the first row */
    CGFloat singleRowHeight = [PNLineChart sizeOfString:@"Test"
                                              withWidth:MAXFLOAT
                                                   font:self.legendFont ? self.legendFont : [UIFont systemFontOfSize:12.0f]].height;

    NSUInteger counter = 0;
    NSUInteger rowWidth = 0;
    NSUInteger rowMaxHeight = 0;
    
    for (PNLineChartData *pdata in self.chartData) {
        /* Expected label size*/
        CGSize labelsize = [PNLineChart sizeOfString:pdata.dataTitle
                                           withWidth:maxLabelWidth
                                                font:self.legendFont ? self.legendFont : [UIFont systemFontOfSize:12.0f]];
        
        /* draw lines */
        if ((rowWidth + labelsize.width + legendLineWidth > mWidth)&&(self.legendStyle == PNLegendItemStyleSerial)) {
            rowWidth = 0;
            x = 0;
            y += rowMaxHeight;
            rowMaxHeight = 0;
        }
        rowWidth += labelsize.width + legendLineWidth;
        totalWidth = self.legendStyle == PNLegendItemStyleSerial ? fmaxf(rowWidth, totalWidth) : fmaxf(totalWidth, labelsize.width + legendLineWidth);
        
        /* If there is inflection decorator, the line is composed of two lines 
         * and this is the space that separates two lines in order to put inflection
         * decorator */
        
        CGFloat inflexionWidthSpacer = pdata.inflexionPointStyle == PNLineChartPointStyleTriangle ? pdata.inflexionPointWidth / 2 : pdata.inflexionPointWidth;
        
        CGFloat halfLineLength;
        
        if (pdata.inflexionPointStyle != PNLineChartPointStyleNone) {
            halfLineLength = (legendLineWidth * 0.8 - inflexionWidthSpacer)/2;
        }else{
            halfLineLength = legendLineWidth * 0.8;
        }
        
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(x + legendLineWidth * 0.1, y + (singleRowHeight - pdata.lineWidth) / 2, halfLineLength, pdata.lineWidth)];
        
        line.backgroundColor = pdata.color;
        line.alpha = pdata.alpha;
        [legendViews addObject:line];
        
        if (pdata.inflexionPointStyle != PNLineChartPointStyleNone) {
            line = [[UIView alloc] initWithFrame:CGRectMake(x + legendLineWidth * 0.1 + halfLineLength + inflexionWidthSpacer, y + (singleRowHeight - pdata.lineWidth) / 2, halfLineLength, pdata.lineWidth)];
            line.backgroundColor = pdata.color;
            line.alpha = pdata.alpha;
            [legendViews addObject:line];
        }

        // Add inflexion type
        [legendViews addObject:[self drawInflexion:pdata.inflexionPointWidth
                                                center:CGPointMake(x + legendLineWidth / 2, y + singleRowHeight / 2)
                                           strokeWidth:pdata.lineWidth
                                        inflexionStyle:pdata.inflexionPointStyle
                                              andColor:pdata.color
                                              andAlpha:pdata.alpha]];

        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(x + legendLineWidth, y, labelsize.width, labelsize.height)];
        label.text = pdata.dataTitle;
        label.textColor = self.legendFontColor ? self.legendFontColor : [UIColor blackColor];
        label.font = self.legendFont ? self.legendFont : [UIFont systemFontOfSize:12.0f];
        label.lineBreakMode = NSLineBreakByWordWrapping;
        label.numberOfLines = 0;

        rowMaxHeight = fmaxf(rowMaxHeight, labelsize.height);
        x += self.legendStyle == PNLegendItemStyleStacked ? 0 : labelsize.width + legendLineWidth;
        y += self.legendStyle == PNLegendItemStyleStacked ? labelsize.height : 0;
        
        
        totalHeight = self.legendStyle == PNLegendItemStyleSerial ? fmaxf(totalHeight, rowMaxHeight + y) : totalHeight + labelsize.height;
        
        [legendViews addObject:label];
        counter++;
    }
    
    UIView *legend = [[UIView alloc] initWithFrame:CGRectMake(0, 0, mWidth, totalHeight)];

    for (UIView* v in legendViews) {
        [legend addSubview:v];
    }
    return legend;
}


- (UIImageView*)drawInflexion:(CGFloat)size center:(CGPoint)center strokeWidth: (CGFloat)sw inflexionStyle:(PNLineChartPointStyle)type andColor:(UIColor*)color andAlpha:(CGFloat) alfa
{
    //Make the size a little bigger so it includes also border stroke
    CGSize aSize = CGSizeMake(size + sw, size + sw);
    

    UIGraphicsBeginImageContextWithOptions(aSize, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    

    if (type == PNLineChartPointStyleCircle) {
        CGContextAddArc(context, (size + sw)/2, (size + sw) / 2, size/2, 0, M_PI*2, YES);
    }else if (type == PNLineChartPointStyleSquare){
        CGContextAddRect(context, CGRectMake(sw/2, sw/2, size, size));
    }else if (type == PNLineChartPointStyleTriangle){
        CGContextMoveToPoint(context, sw/2, size + sw/2);
        CGContextAddLineToPoint(context, size + sw/2, size + sw/2);
        CGContextAddLineToPoint(context, size/2 + sw/2, sw/2);
        CGContextAddLineToPoint(context, sw/2, size + sw/2);
        CGContextClosePath(context);
    }
    
    //Set some stroke properties
    CGContextSetLineWidth(context, sw);
    CGContextSetAlpha(context, alfa);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    
    //Finally draw
    CGContextDrawPath(context, kCGPathStroke);

    //now get the image from the context
    UIImage *squareImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    //// Translate origin
    CGFloat originX = center.x - (size + sw) / 2.0;
    CGFloat originY = center.y - (size + sw) / 2.0;
    
    UIImageView *squareImageView = [[UIImageView alloc]initWithImage:squareImage];
    [squareImageView setFrame:CGRectMake(originX, originY, size + sw, size + sw)];
    return squareImageView;
}

#pragma mark setter and getter

-(CATextLayer*) createPointLabelFor:(CGFloat)grade pointCenter:(CGPoint)pointCenter width:(CGFloat)width withChartData:(PNLineChartData*)chartData
{
    CATextLayer *textLayer = [[CATextLayer alloc]init];
    [textLayer setAlignmentMode:kCAAlignmentCenter];
    [textLayer setForegroundColor:[chartData.pointLabelColor CGColor]];
    [textLayer setBackgroundColor:[[[UIColor whiteColor] colorWithAlphaComponent:0.8] CGColor]];
    [textLayer setCornerRadius:textLayer.fontSize/8.0];
    
    if (chartData.pointLabelFont != nil) {
        [textLayer setFont:(__bridge CFTypeRef)(chartData.pointLabelFont)];
        textLayer.fontSize = [chartData.pointLabelFont pointSize];
    }
    
    CGFloat textHeight = textLayer.fontSize * 1.1;
    CGFloat textWidth = width*8;
    CGFloat textStartPosY;
    
    textStartPosY = pointCenter.y - textLayer.fontSize;

    [self.layer addSublayer:textLayer];
    
    if (chartData.pointLabelFormat != nil) {
        [textLayer setString:[[NSString alloc]initWithFormat:chartData.pointLabelFormat, grade]];
    } else {
        [textLayer setString:[[NSString alloc]initWithFormat:_yLabelFormat, grade]];
    }
    
    [textLayer setFrame:CGRectMake(0, 0, textWidth,  textHeight)];
    [textLayer setPosition:CGPointMake(pointCenter.x, textStartPosY)];
    textLayer.contentsScale = [UIScreen mainScreen].scale;

    return textLayer;
}

-(CABasicAnimation*)fadeAnimation
{
    CABasicAnimation* fadeAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fadeAnimation.fromValue = [NSNumber numberWithFloat:0.0];
    fadeAnimation.toValue = [NSNumber numberWithFloat:1.0];
    fadeAnimation.duration = 2.0;
    
    return fadeAnimation;
}

@end
