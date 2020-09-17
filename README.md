# PhotoPicker-iOS
a photo picker like photos app for iOS    
一个图片选择控件，交互类似iOS自带Photos App，可以自动处理下载iCloud图片相关逻辑，内置 `PhotoFetcher` 也可以自己有选择的下载存储在iCloud中的图片，支持图片放大缩小、预览等功能

### Demo
![wfhRr4.gif](https://s1.ax1x.com/2020/09/18/wfhRr4.gif)

## Requirements

- Swift 4.2
- iOS 10.0 or later

## Usage

```swift
class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func tappedAlbumButton(_ sender: Any) {
        PhotoPicker.presentPhotoPicker(in: self) { (result) in
            print(result.assets)
        }
    }
}
```

## Handle icloud image

```swift
PhotoFetcher().fetch(asset: asset, targetSize: targeSize, progressHandler: { (progress, error) in
    progressHandler?(progress, error)
}) { (image, info) in
    completionHandler(image)
}
```

## Author

SylenthWave


## LICENSE

Under the MIT license. See LICENSE file for details.
