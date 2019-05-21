#  ParkIt! Swift Edition

## The Project

ParkIt is an open-source Swift application aimed to help bike and motorbike owners in Paris find a parking nearby.

### To-Do

- Make sure that MKAnnotation are properly created
- Install ClusterKit to better see MKAnnotations
- Refactor tooltip view to display it programmatically 
- Add a button to center map
- Create service to convert mins in hours

### Gists

__Detect touch outside view__

```
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        let touch = touches.first
//        guard let location = touch?.location(in: self.view) else { return }
//
//        if !tooltipItinerary.frame.contains(location) {
//            tooltipItinerary.isHidden = true
//        }
//
//    }
```
