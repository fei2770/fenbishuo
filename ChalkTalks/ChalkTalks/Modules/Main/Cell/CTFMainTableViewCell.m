//
//  CTFMainTableViewCell.m
//  ChalkTalks
//
//  Created by vision on 2020/1/7.
//  Copyright © 2020 xiaohuangren. All rights reserved.
//

#import "CTFMainTableViewCell.h"
#import "CTFPhotosColletionView.h"
#import "CTFAVVideoContainerView.h"
#import "CTFAudioFeedView.h"
#import "CTFFeedCellLayout.h"
#import "CTFCommonManager.h"
#import "CTFTopicAuthorView.h"
#import "CTFAnswerInfoView.h"
#import "CTFAnswerHandleView.h"
#import "NSString+Utilities.h"

@interface CTFMainTableViewCell ()

@property (nonatomic,strong) UILabel                 *titleLab;             //标题
@property (nonatomic,strong) CTFTopicAuthorView      *authorView;           //发布者
@property (nonatomic,strong) CTFPhotosColletionView  *imgsCollectionView;   //图片
@property (nonatomic,strong) CTFAVVideoContainerView *videoContainerView;   //视频
@property (nonatomic,strong) CTFAudioFeedView        *audioView;            //图语
@property (nonatomic,strong) CTBlurEffectView        *effectView;
@property (nonatomic,strong) UILabel                 *descLab;              //观点描述
@property (nonatomic,strong) CTFAnswerInfoView       *answerInfoView;       //回答发布者、浏览量
@property (nonatomic,strong) CTFAnswerHandleView     *handleView;           //更多、评论、靠谱事件
@property (nonatomic,strong) UIView                  *lineView;

@property (nonatomic, weak ) id<CTFMainTableViewCellDelegate>delegate;
@property (nonatomic,strong) CTFFeedCellLayout  *cellLayout;

@end

@implementation CTFMainTableViewCell

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self =  [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self initMainView];
    }
    return self;
}

#pragma mark 更新UI
-(void)layoutSubviews{
    [super layoutSubviews];
    
    self.titleLab.frame = self.cellLayout.titleRect;
    self.authorView.frame = self.cellLayout.authorRect;
    self.imgsCollectionView.frame = self.cellLayout.imgsRect;
    self.videoContainerView.frame = self.cellLayout.videoRect;
    self.audioView.frame = self.cellLayout.audioRect;
    self.descLab.frame = self.cellLayout.descRect;
    self.effectView.frame = self.cellLayout.descRect;
    self.answerInfoView.frame = self.cellLayout.infoRect;
    [self.answerInfoView setBorderWithCornerRadius:13 type:UIViewCornerTypeAll];
    self.handleView.frame = self.cellLayout.handleRect;
    self.lineView.frame = self.cellLayout.separationRect;
}

#pragma mark 填充数据
-(void)fillContentWithData:(id)obj{
    self.cellLayout = (CTFFeedCellLayout *)obj;
    AnswerModel *answerModel = self.cellLayout.model;
    if (kIsEmptyString(answerModel.question.shortTitle)&&kIsEmptyString(answerModel.question.suffix)) {
        self.titleLab.text = answerModel.question.title;
    } else {
       self.titleLab.attributedText = [CTFCommonManager setTopicTitleWithType:answerModel.question.type shortTitle:answerModel.question.shortTitle suffix:answerModel.question.suffix];
    }
    AuthorModel *author = [AuthorModel yy_modelWithDictionary:answerModel.question.author];
    [self.authorView fillDataWithType:answerModel.question.type author:author];
    
    //资源（图片或视频）
    if ([answerModel.type isEqualToString:@"images"]) {
        [self.imgsCollectionView fillImagesData:answerModel.images status:answerModel.status];
    }else if([answerModel.type isEqualToString:@"video"]){
        [self.videoContainerView fillContentWithData:answerModel];
    }else if([answerModel.type isEqualToString:@"audioImage"]){
        [self.audioView fillAudioImageData:answerModel.audioImage indexPath:self.cardIndexPath currentIndex:answerModel.currentIndex status:answerModel.status];
    }
    //描述
    self.descLab.text = answerModel.content;
    if ([answerModel.status isEqualToString:@"reviewing"] && !kIsEmptyString(answerModel.content)) {
        self.effectView.hidden = NO;
        if ([UIDevice currentDevice].systemVersion.floatValue > 12.0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.effectView.blurLevel = 0.5;
            });
        }
    } else {
        self.effectView.hidden = YES;
    }
    [self.answerInfoView fillDataWithAuthor:answerModel.author viewCount:answerModel.viewCount];
    [self.handleView fillAnswerData:answerModel indexPath:self.cardIndexPath];
}

#pragma mark 设置代理
-(void)setDelegate:(id<CTFMainTableViewCellDelegate>)delegate withIndexPath:(NSIndexPath *)indexPath{
    self.delegate = delegate;
    self.cardIndexPath = indexPath;
}

#pragma mark -- Event response
#pragma mark 点击标题
-(void)feedTitleTap{
    [self routerEventWithName:kTopicTitleEvent userInfo:@{kViewpointDataModelKey: self.cellLayout.model,kCellIndexPathKey: self.cardIndexPath}];
}

#pragma mark 点击描述
-(void)feedIntroTap{
    [self routerEventWithName:kViewpointIntroEvent userInfo:@{kViewpointDataModelKey: self.cellLayout.model, kCellIndexPathKey: self.cardIndexPath}];
}

#pragma mark -- Private methods
#pragma mark 界面初始化
-(void)initMainView{
    [self.contentView addSubview:self.titleLab];
    [self.contentView addSubview:self.authorView];
    [self.contentView addSubview:self.imgsCollectionView];
    [self.contentView addSubview:self.videoContainerView];
    [self.contentView addSubview:self.audioView];
    [self.contentView addSubview:self.descLab];
    [self.descLab addSubview:self.effectView];
    self.effectView.hidden = YES;
    [self.contentView addSubview:self.answerInfoView];
    [self.contentView addSubview:self.handleView];
    [self.contentView addSubview:self.lineView];
}

#pragma mark 加载失败
-(void)showLoadingFailView{
    [self.videoContainerView showInterruptTipsView:VideoInterrupted_NetError];
}

#pragma mark 停止播放
-(void)stopAuido{
    self.audioView.autoScroll = NO;
    [self.audioView stopPlayAudio];
}

#pragma mark 播放视频
- (void)playVideo{
    if([[CTFNetReachabilityManager sharedInstance] currentNetStatus] == AFNetworkReachabilityStatusReachableViaWWAN && ![CTFCellularPlayerVideo sharedInstance].canPlayVideoViaWWAN){
        [self.videoContainerView showInterruptTipsView:VideoInterrupted_Cellular];
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(mainTableViewCell:avcellPlayVideoAtIndexPath:)]) {
        [self.delegate mainTableViewCell:self avcellPlayVideoAtIndexPath:self.cardIndexPath];
    }
}

#pragma mark -- Getters
#pragma mark 话题标题
-(UILabel *)titleLab{
    if (!_titleLab) {
        _titleLab = [[UILabel alloc] init];
        _titleLab.font = [UIFont mediumFontWithSize:18];
        _titleLab.numberOfLines = 0;
        _titleLab.lineBreakMode = NSLineBreakByCharWrapping;
        _titleLab.textColor = [UIColor ctColor33];
        [_titleLab addTapPressed:@selector(feedTitleTap) target:self];
    }
    return _titleLab;
}

#pragma mark 发布者
- (CTFTopicAuthorView *)authorView {
    if (!_authorView) {
        _authorView = [[CTFTopicAuthorView alloc] init];
    }
    return _authorView;
}

#pragma mark 多张图片
-(CTFPhotosColletionView *)imgsCollectionView{
    if (!_imgsCollectionView) {
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc]init];
        _imgsCollectionView = [[CTFPhotosColletionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
    }
    return _imgsCollectionView;
}

#pragma mark 视频
-(CTFAVVideoContainerView *)videoContainerView{
    if (!_videoContainerView) {
        _videoContainerView = [[CTFAVVideoContainerView alloc] init];
        @weakify(self);
        _videoContainerView.playVideo = ^{
            @strongify(self);
            [self playVideo];
        };
        [_videoContainerView addTapPressed:@selector(playVideo) target:self];
    }
    return _videoContainerView;
}

#pragma mark 图语
-(CTFAudioFeedView *)audioView{
    if (!_audioView) {
        _audioView = [[CTFAudioFeedView alloc] initWithFrame:CGRectZero];
        _audioView.layer.cornerRadius = 5.0;
        _audioView.clipsToBounds = YES;
    }
    return _audioView;
}

#pragma mark 观点描述
-(UILabel *)descLab{
    if (!_descLab) {
        _descLab = [[UILabel alloc] init];
        _descLab.font = [UIFont regularFontWithSize:14];
        _descLab.numberOfLines = 0;
        _descLab.textColor = [UIColor ctColor66];
        [_descLab addTapPressed:@selector(feedIntroTap) target:self];
    }
    return _descLab;
}

- (CTBlurEffectView *)effectView {
    if (!_effectView) {
        UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        _effectView = [[CTBlurEffectView alloc] initWithEffect:blur];
    }
    return _effectView;
}

#pragma mark 回答发布者
- (CTFAnswerInfoView *)answerInfoView {
    if (!_answerInfoView) {
        _answerInfoView = [[CTFAnswerInfoView alloc] init];
    }
    return _answerInfoView;
}

#pragma mark 靠谱事件
-(CTFAnswerHandleView *)handleView {
    if (!_handleView) {
        _handleView = [[CTFAnswerHandleView alloc] init];
        _handleView.type = CTFAnswerHandleViewTypeHome;
    }
    return _handleView;
}

#pragma mark 线
-(UIView *)lineView{
    if (!_lineView) {
        _lineView = [[UIView alloc] init];
        _lineView.backgroundColor = UIColorFromHEX(0xF8F8F8);
    }
    return _lineView;
}

@end