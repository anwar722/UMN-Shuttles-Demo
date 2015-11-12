# UMN-Shuttles-Demo 

This is a simple app which parses data from the [NextBus XML](https://www.nextbus.com/xmlFeedDocs/NextBusXMLFeed.pdf) feed and displays bus stops, and real-time bus locations on a map. You can use this if you're trying to learn about Apple's `NSXMLParser`, `MapKit` and the NextBus API using Swift 1.2. Please note that this is a demo version of a more elaborate application and is based on iOS 8.2. Updates for iOS 9.1 are to be followed soon. Also, the full version of the application will be uploaded in a different repository once the UI elements are figured out!

**Features that may come in handy across multiple applications:**
- Parsing live XML data from http (specifically, NextBus)
- Using the XML data to draw routes and vehicle annotations on the map.
- Animating the vehicle movements
- Other MapKit and custom MKAnnotation implementation features (e.g. adding an `observer` to detect vehicles' angle/rotation property)

## Screenshot:
<img src="./Map%20Demo/screenshot.png" width="350">

*The arrow is a single bus and the blue annotations are the bus stops. The red polyline is the bus route.*

Thank you, and hope you find it useful. This app could use a lot of improvements (memory management, efficient caching, etc.) So please feel free to use it and make it better!

Note: The title is a bit misleading. But since it is a demo, I decided to stick with it. But, please note that you can use it basically with any NextBus agency or even any XML document which has similar format!
