# ZFPlayer

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

ZFPlayer is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'ZFPlayer'
```

## Author

wangyongxin0408, wangyongxin0408@shihuo.cn

## License

ZFPlayer is available under the MIT license. See the LICENSE file for more info.

https://github.com/renzifeng/ZFPlayer/blob/master/README.md

私有库版本 12.0.0  -> github 4.0.3

ZFPlayer三方组件修改

修改点：

1、_findCorrectCellWhenScrollViewDirectionVertical -> 

```
 if ([self _isCollectionView]) {
    // First visible cell indexPath
    if (isLast) {
        // by wyx 修复列表滚动到最后一个播放错误的BUG
        indexPath = sortedIndexPaths.lastObject;
    } else {
        indexPath = sortedIndexPaths.firstObject;
    }
 }
```
    
2. _findCorrectCellWhenScrollViewDirectionVertical ->
502行改动

```

if ((topSpacing >= -(1 - self.zf_playerApperaPercent) * CGRectGetHeight(rect)) && (bottomSpacing >= -(1 - self.zf_playerApperaPercent) * CGRectGetHeight(rect))) {
    /// add by zm 添加视频列表滚动以视频消失为主即消失后下个视频才能播放
    if (self.zf_playingIndexPath) {
        indexPath = self.zf_playingIndexPath;
        finalIndexPath = indexPath;
        *stop = YES;
        return;
    }

    if (!finalIndexPath || centerSpacing < finalSpace) {
        finalIndexPath = indexPath;
        finalSpace = centerSpacing;
    }
}
        
```
