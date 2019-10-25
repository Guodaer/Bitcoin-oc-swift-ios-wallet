// Oleg Andreev <oleganza@gmail.com>

#import "BTCProtocolSerialization.h"

@implementation BTCProtocolSerialization


// varInt here refers to CompactSize in Satoshi code.
// BitcoinQT later added CVarInt which is different, more compact format used in block storage.
//  Value           Storage length     Format
//  < 0xfd          1                  uint8_t
// <= 0xffff        3                  0xfd followed by the value as uint16_t
// <= 0xffffffff    5                  0xfe followed by the value as uint32_t
//  > 0xffffffff    9                  0xff followed by the value as uint64_t

+ (NSUInteger) readVarInt:(uint64_t*)valueOut fromData:(NSData*)data {
    NSUInteger dataLength = data.length;
    if (dataLength == 0) return 0;
    
    unsigned char size = ((unsigned char*)data.bytes)[0];
    
    if (size < 0xfd) {
        if (valueOut) *valueOut = size;
        return 1;
    } else if (size == 0xfd) {
        if (dataLength < 3) return 0;
        if (valueOut) *valueOut = OSReadLittleInt16(data.bytes, 1);
        return 3;
    } else if (size == 0xfe) {
        if (dataLength < 5) return 0;
        if (valueOut) *valueOut = OSReadLittleInt32(data.bytes, 1);
        return 5;
    } else {
        if (dataLength < 9) return 0;
        if (valueOut) *valueOut = OSReadLittleInt64(data.bytes, 1);
        return 9;
    }
    return 0;
}

+ (NSUInteger) readVarInt:(uint64_t*)valueOut fromStream:(NSInputStream*)stream {
    if (!stream) return 0;
    
    unsigned char size = 0;
    NSInteger readSize = [stream read:&size maxLength:sizeof(size)];
    
    if (stream.streamStatus == NSStreamStatusClosed) return 0;
    if (stream.streamStatus == NSStreamStatusNotOpen) return 0;
    
    if (readSize < (NSInteger)sizeof(size)) {
        return 0;
    }
    
    if (size < 0xfd) {
        if (valueOut) *valueOut = size;
        return 1;
    } else if (size == 0xfd) {
        uint16_t value = 0;
        NSInteger readSize = [stream read:(uint8_t*)&value maxLength:sizeof(value)];
        if (readSize < sizeof(value)) return 0;
        if (valueOut) *valueOut = CFSwapInt16LittleToHost(value);
        return 1 + sizeof(value);
    } else if (size == 0xfe) {
        uint32_t value = 0;
        NSInteger readSize = [stream read:(uint8_t*)&value maxLength:sizeof(value)];
        if (readSize < sizeof(value)) return 0;
        if (valueOut) *valueOut = CFSwapInt32LittleToHost(value);
        return 1 + sizeof(value);
    } else {
        uint64_t value = 0;
        NSInteger readSize = [stream read:(uint8_t*)&value maxLength:sizeof(value)];
        if (readSize < sizeof(value)) return 0;
        if (valueOut) *valueOut = CFSwapInt64LittleToHost(value);
        return 1 + sizeof(value);
    }
}

+ (NSData*) readVarStringFromData:(NSData*)data {
    return [self readVarStringFromData:data readBytes:NULL];
}

+ (NSData*) readVarStringFromData:(NSData*)data readBytes:(NSUInteger*)lengthOut {
    uint64_t length = 0;
    NSUInteger varIntLength = [self readVarInt:&length fromData:data];
    if (varIntLength == 0) return nil;
    
    if (data.length < (varIntLength + length)) return nil;
    
    if (lengthOut) *lengthOut = varIntLength + (NSUInteger)length;
    
    return [data subdataWithRange:NSMakeRange(varIntLength, (NSUInteger)length)];
}

+ (NSData*) readVarStringFromStream:(NSInputStream*)stream {
    uint64_t length = 0;
    NSUInteger varIntLength = [self readVarInt:&length fromStream:stream];
    if (varIntLength == 0) return nil;
    
    NSMutableData* data = [NSMutableData dataWithLength:(NSUInteger)length];
    if (length > 0) {
        [stream read:data.mutableBytes maxLength:(NSUInteger)length];
    }
    return data;
}
//- (GDScrollPageView *)gdPageView {
//    if (!_gdPageView) {
//        CGFloat topHeight = [GDChiefHomeTopView getHeaderSize];
//        CGFloat tabbar_height = Height_TabbarSafeBottom;
//        CGFloat nav_height = Height_StatusBar;
//        UIImageView *scroll_TopView = [[UIImageView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.headerView.frame)-LineX(7.5), kScreenWidth, LineX(40))];
//        scroll_TopView.image = BullImage(@"sx_detail_top");
//        [self.view addSubview:scroll_TopView];
//
//        _gdPageView = [[GDScrollPageView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.headerView.frame)-LineX(7.5), kScreenWidth, kScreenHeight - tabbar_height - topHeight+LineX(7.5)-nav_height)];
//        _gdPageView.superVC = self;
//        _gdPageView.titles = self.pagetitleArray;
//        _gdPageView.controllers = self.controllerArray;
//        _gdPageView.title_Color = BullColor(0x333333, 1);
//        _gdPageView.titleSelect_Color = NavbgColor;
//        _gdPageView.bottomLine_color = NavbgColor;
//        _gdPageView.lineWidth = 35;
//        _gdPageView.bottomLineHeight = 3;
//        _gdPageView.headerBarHeight = LineX(40);
//        _gdPageView.title_font = [UIFont boldSystemFontOfSize:LineX(14)];
//        _gdPageView.topBgColor = [UIColor clearColor];
//        [_gdPageView loadScrollView];
//
//    }
//    return _gdPageView;
//}


+ (NSData*) dataForVarInt:(uint64_t)value
{
    if (value < 0xfd) {
        unsigned char size = value;
        return [NSData dataWithBytes:&size length:sizeof(size)];
    } else if (value <= 0xffff) {
        unsigned char size = 0xfd;
        uint16_t compactValue = CFSwapInt16HostToLittle((uint16_t)value);
        NSMutableData* data = [NSMutableData dataWithLength:1 + sizeof(compactValue)];
        [data replaceBytesInRange:NSMakeRange(0, 1) withBytes:&size];
        [data replaceBytesInRange:NSMakeRange(1, sizeof(compactValue)) withBytes:&compactValue];
        return data;
    } else if (value <= 0xffffffffUL) {
        unsigned char size = 0xfe;
        uint32_t compactValue = CFSwapInt32HostToLittle((uint32_t)value);
        NSMutableData* data = [NSMutableData dataWithLength:1 + sizeof(compactValue)];
        [data replaceBytesInRange:NSMakeRange(0, 1) withBytes:&size];
        [data replaceBytesInRange:NSMakeRange(1, sizeof(compactValue)) withBytes:&compactValue];
        return data;
    } else {
        unsigned char size = 0xff;
        uint64_t compactValue = CFSwapInt64HostToLittle(value);
        NSMutableData* data = [NSMutableData dataWithLength:1 + sizeof(compactValue)];
        [data replaceBytesInRange:NSMakeRange(0, 1) withBytes:&size];
        [data replaceBytesInRange:NSMakeRange(1, sizeof(compactValue)) withBytes:&compactValue];
        return data;
    }
}

// Prepends binary string with its length in varInt format.
+ (NSData*) dataForVarString:(NSData*)binaryString {
    if (!binaryString) return nil;
    
    NSMutableData* data = [[self dataForVarInt:binaryString.length] mutableCopy];
    [data appendData:binaryString];
    return data;
}


@end

