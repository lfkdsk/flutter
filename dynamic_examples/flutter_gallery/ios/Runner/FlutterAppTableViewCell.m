//
//  FlutterAppTableViewCell.m
//  Runner
//
//  Created by 白昆仑 on 2019/7/29.
//  Copyright © 2019 The Chromium Authors. All rights reserved.
//

#import "FlutterAppTableViewCell.h"
#import "BDWebImage.h"
static CGFloat const kCoverImageHeight = 300;
static CGFloat kCellWidth = 0;

@interface FlutterAppTableViewCell ()
@property(nonatomic, strong)UIView *containerView;
@property(nonatomic, strong)UILabel *nameLabel;
@property(nonatomic, strong)UILabel *versionlabel;
@property(nonatomic, strong)UILabel *descriptionLabel;
@property(nonatomic, strong)UIImageView *imageCover;
@property(nonatomic, strong)UIView *downloadProgressBackground;
@end

@implementation FlutterAppTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    if (self) {
        _containerView = [[UIView alloc] init];
        _containerView.backgroundColor = [UIColor whiteColor];
        _containerView.layer.cornerRadius = 12;
        _containerView.userInteractionEnabled = NO;
        _containerView.clipsToBounds = YES;
//        _containerView.layer.shadowColor = [UIColor blackColor].CGColor;
//        _containerView.clipsToBounds = NO;
//        _containerView.layer.shadowOffset = CGSizeMake(2, 2);
//        _containerView.layer.shadowRadius = 4;
//        _containerView.layer.shadowOpacity = 0.6;
        
        _imageCover = [[UIImageView alloc] init];
        _imageCover.contentMode = UIViewContentModeScaleAspectFill;
        _imageCover.clipsToBounds = YES;
        [_containerView addSubview:_imageCover];
        
        _downloadProgressBackground = [[UIView alloc] init];
        _downloadProgressBackground.backgroundColor = [UIColor colorWithRed:0.527 green:0.804 blue:0.976 alpha:1];
        _downloadProgressBackground.hidden = YES;
        [_containerView addSubview:_downloadProgressBackground];
        
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.numberOfLines = 1;
        _nameLabel.font = [UIFont boldSystemFontOfSize:26];
        _nameLabel.textColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1];
        [_containerView addSubview:_nameLabel];
        
        _versionlabel = [[UILabel alloc] init];
        _versionlabel.numberOfLines = 1;
        _versionlabel.font = [UIFont boldSystemFontOfSize:18];
        _versionlabel.textColor = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1];
        [_containerView addSubview:_versionlabel];
        
        _descriptionLabel = [[UILabel alloc] init];
        _descriptionLabel.numberOfLines = 0;
        _descriptionLabel.font = [UIFont systemFontOfSize:15];
        _descriptionLabel.textColor = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1];
        _descriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;
        [_containerView addSubview:_descriptionLabel];
        
        self.contentView.backgroundColor = [UIColor clearColor];
        self.contentView.userInteractionEnabled = NO;
        [self.contentView addSubview:_containerView];
    }
    
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

- (void)setModel:(FlutterAppModel *)model {
    _model = model;
    if (_model.detail && _model.detail[@"cover_url"]) {
        [_imageCover bd_setImageWithURL:[NSURL URLWithString:_model.detail[@"cover_url"]] options:BDImageRequestHighPriority|BDImageRequestNotCacheToMemery|BDImageNotDecoderForDisplay];
    }
    else {
        _imageCover.image = nil;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    _containerView.frame = _model.containerViewFrame;
    _imageCover.frame = _model.coverImageFrame;
    _nameLabel.text = _model.name;
    _nameLabel.frame = _model.nameLabelFrame;
    _versionlabel.frame = _model.versionLableFrame;
    _descriptionLabel.frame = _model.desFrame;
    
//    if (!_imageCover.layer.mask) {
//        UIBezierPath *round = [UIBezierPath bezierPathWithRoundedRect:_imageCover.bounds byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii:CGSizeMake(12, 12)];
//        CAShapeLayer *shape = [[CAShapeLayer alloc] init];
//        [shape setPath:round.CGPath];
//        _imageCover.layer.mask = shape;
//    }
    
    if (self.model.version >= 0) {
        _versionlabel.text = [NSString stringWithFormat:@"v%ld", self.model.version];
        _versionlabel.hidden = NO;
    }
    else {
        _versionlabel.hidden = YES;
    }
    
    if (self.model.updateStatus == UpdateStatusNone) {
        _downloadProgressBackground.hidden = YES;
        if (self.model.detail && self.model.detail[@"description"]) {
            _descriptionLabel.text = self.model.detail[@"description"];
            _descriptionLabel.hidden = NO;
        }
        else {
            _descriptionLabel.hidden = YES;
        }
    }
    else if(self.model.updateStatus == UpdateStatusDownloading) {
        _downloadProgressBackground.hidden = NO;
        _descriptionLabel.hidden = NO;
        _downloadProgressBackground.frame = CGRectMake(_model.progressFrame.origin.x, _model.progressFrame.origin.y, _model.progressFrame.size.width * self.model.updateProgress, _model.progressFrame.size.height);
        _descriptionLabel.text = [NSString stringWithFormat:@"下载中 (%ld%%)", (NSInteger)(self.model.updateProgress*100)];
    }
    else {
        _downloadProgressBackground.hidden = YES;
    }
}

+ (CGFloat)cellHeightWithModel:(FlutterAppModel *)model width:(CGFloat)width {
    CGFloat height = 20 + kCoverImageHeight + 20 + 20;
    CGFloat containerWidth = width - 40;
    model.coverImageFrame = CGRectMake(0, 0, containerWidth, kCoverImageHeight);
    
    CGFloat textWidth = containerWidth - 40;
    UILabel *nameLabel = [UILabel new];
    nameLabel.font = [UIFont boldSystemFontOfSize:26];
    nameLabel.numberOfLines = 1;
    nameLabel.text = model.name;
    CGSize nameLabelSize = [nameLabel sizeThatFits:CGSizeMake(MAXFLOAT, MAXFLOAT)];
    model.nameLabelFrame = CGRectMake(20, kCoverImageHeight+20, nameLabelSize.width, nameLabelSize.height);
    
    UIFont *versionFont = [UIFont boldSystemFontOfSize:18];
    model.versionLableFrame = CGRectMake(20+nameLabelSize.width+10, model.nameLabelFrame.origin.y+nameLabelSize.height-versionFont.lineHeight-2, textWidth-20*2-nameLabelSize.width-10, versionFont.lineHeight);
    height += nameLabelSize.height;
    
    if (model.detail && model.detail[@"description"]) {
        UILabel *desLabel = [UILabel new];
        desLabel.numberOfLines = 0;
        desLabel.font = [UIFont systemFontOfSize:15];
        desLabel.text = model.detail[@"description"];
        desLabel.lineBreakMode = NSLineBreakByWordWrapping;
        CGSize size = [desLabel sizeThatFits:CGSizeMake(width-80, MAXFLOAT)];
        model.desFrame = CGRectMake(20, model.nameLabelFrame.origin.y + model.nameLabelFrame.size.height + 10, size.width, size.height);
        height += 10;
        height += size.height;
    }
    
    model.containerViewFrame = CGRectMake(20, 10, containerWidth, height-20);
    model.progressFrame = CGRectMake(0, kCoverImageHeight, containerWidth, model.containerViewFrame.size.height-kCoverImageHeight);
    
    return height;
}

@end
