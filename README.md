# UMN-Shuttles-Demo 

This is a simple app which parses data from the [NextBus XML](https://www.nextbus.com/xmlFeedDocs/NextBusXMLFeed.pdf) feed and displays bus stops, and real-time bus locations on a map. This is a good example app if you're trying to learn about Apple's NSXMLParser, MapKit and the NextBus API using Swift 1.2. Please note that this is a demo version of a more elaborate application and it is based on iOS 8.2. Updates for iOS 9.1 are to be followed soon. Also, the full version of the application will be uploaded in a different repository once the UI elements are figured out!

Features that may come in handy:
- Parsing live XML data from http (specifically, NextBus)
- Using the XML data to draw vehicle annotations on the map.
- Animating the vehicle movements
- Other MapKit and custom MKAnnotation implementation features (e.g. adding an "observer" to detect vehicles' angle/rotation property)

## Screenshot:
![Alt text](https://github.com/anwar722/UMN-Shuttles-Demo/blob/master/Map%20Demo/screenshot.png =393x698"screenshot")

Thank you, and hope you find it useful. This app could use a lot of improvements (memory management, efficient caching, etc.) So please feel free to use it and make it better!

Note: The title is a bit misleading. But since it is a demo, I decided to stick with it. But, please note that you can use it basically with any NextBus agency or XML document which has the same format!
