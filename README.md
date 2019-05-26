#  ParkIt! Swift Edition

[https://i.imgur.com/BYkvNQJ.png](
![IParkIt!](https://i.imgur.com/BYkvNQJ.png)

## The Project

ParkIt is an open-source Swift application aimed to help bike and motorbike owners in Paris find a parking nearby.

### To-Do

#### Annotations View

- Optimize first annotation loading time

#### Itinerary tooltip

- Refactor tooltip view to display it programmatically
- Create service to convert mins in hours

#### Map


#### Misc 

- Refactor functions
- Add Settings to manage saving, add copyrights and data privacy information
- Add Transition effect to Settings
- Keep information of selected mode of transportation 

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
