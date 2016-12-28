//
//  MAGNudityDetector.m
//  Utility class for identifiyng potentially pornographic images
//  Source: http://www.naun.org/multimedia/NAUN/computers/20-462.pdf
//  J. Marcial-Basilio (2011), Detection of Pornographic Digital Images, International Journal of Computers
//
//  Created by Andrew Petrus on 27.10.14.
//  Copyright (c) 2014 Andrew Petrus. All rights reserved.
//

#import "MAGNudityDetector.h"

static NSInteger const kBoundsCbCr[4] = {80, 120, 133, 173};
static NSInteger const kExcludeWhite = 253;
static NSInteger const kExcludeBlack = 3;

@interface MAGNudityDetector ()

@property (nonatomic) unsigned char *m_PixelBuf;
@property (nonatomic) unsigned long length;

@end


@implementation MAGNudityDetector


+ (instancetype)sharedInstance {
    static id instance_ = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance_ = [self new];
    });
    return instance_;
}


- (instancetype)init {
    self = [super init];
    if (self) {
        self.thresholdLimit = 0.55f; // default value;
    }
    return self;
}


- (void)unpackImage:(UIImage *)image {
    CGImageRef imageRef = [image CGImage];
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    _m_PixelBuf = malloc(height * width * 4);
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(_m_PixelBuf, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    self.length = height * width * 4;
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
}


- (double)quantifyYCbCr:(UIImage *)image {
    double total = 0;
    double count = 0;
    NSInteger cb1 = kBoundsCbCr[0],
              cb2 = kBoundsCbCr[1],
              cr1 = kBoundsCbCr[2],
              cr2 = kBoundsCbCr[3];
    for (unsigned long i = 0; i < self.length; i += 3) {
        NSInteger r = _m_PixelBuf[i + 0],
                  g = _m_PixelBuf[i + 1],
                  b = _m_PixelBuf[i + 2];
        if (((r > kExcludeWhite) && (g > kExcludeWhite) && (b > kExcludeWhite)) ||
            ((r < kExcludeBlack) && (g < kExcludeBlack) && (b < kExcludeBlack)))  {
            continue;
        }
        // Converg pixel RGB color to YCbCr, coefficients already divided by 255
        double cb = 128 + (-0.1482 * r) + (-0.291 * g) + (0.4392 * b);
        double cr = 128 + (0.4392 * r) + (-0.3678 * g) + (-0.0714 * b);
        if ((cb >= cb1) && (cb <= cb2) && (cr >= cr1) && (cr <= cr2)) {
            count++;
        }
        total++;
    }
    return (count / total);
}


- (void)analyzeImage:(UIImage *)image withCompletionBlock:(void (^)(NSDictionary *result))completionBlock {
    dispatch_async(dispatch_queue_create("com.MAGNudityDetector.analyzeImage", 0), ^{
        [self unpackImage:image];
        double result = [self quantifyYCbCr:image];
        BOOL nudityResult = (result>self.thresholdLimit)?YES:NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completionBlock) {
                completionBlock(@{kPotentialNudityPixelPercentageKey:@(result),
                                  kPotentialNudityResultKey:@(nudityResult)});
            }
        });
    });
}

@end
