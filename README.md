# PhotoPicker-iOS
a photo picker like photos app for iOS

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

## Author

SylenthWave


## LICENSE

Under the MIT license. See LICENSE file for details.
