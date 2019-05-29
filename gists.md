### Gists

__Detect touch outside view__

```
override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    let touch = touches.first
    guard let location = touch?.location(in: self.view) else { return }
    if !tooltipItinerary.frame.contains(location) {
        tooltipItinerary.isHidden = true
    }
}
```

