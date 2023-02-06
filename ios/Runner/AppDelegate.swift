import UIKit
import Flutter
import MapKit

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, MKLocalSearchCompleterDelegate {
    
    private var completer = MKLocalSearchCompleter()
    var locationChannel:FlutterMethodChannel? = nil
    
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let arguments = completer.results.map({["title":$0.title, "subtitle":$0.subtitle ]})
        _sendToChannel(arguments:arguments);
    }
    
    private func _sendToChannel(arguments:Any) {
        DispatchQueue.main.async {
            self.locationChannel?.invokeMethod("response", arguments: arguments);
        }
    }

    private func completer(completer: MKLocalSearchCompleter, didFailWithError error: NSError) {
        _sendToChannel(arguments:[["title": "error with completer", "subtitle":error.description ]]);
    }
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        completer.delegate = self
        
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController

        locationChannel = FlutterMethodChannel(
            name: "weather/location",
            binaryMessenger: controller.binaryMessenger
        )
        
        locationChannel?.setMethodCallHandler({
               (call: FlutterMethodCall, result: FlutterResult) -> Void in
            if (call.method == "lookup") {
                if #available(iOS 13.0, *) {
                    self.completer.resultTypes = MKLocalSearchCompleter.ResultType.address
                } else {
                    // Fallback on earlier versions
                };
                   self.completer.queryFragment = (call.arguments as! Dictionary<String, String>)["address"]!
               }
           })
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
