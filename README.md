# BIHappy Europe API (Swift)
This is the official API for [BIHappy Europe (BIHappy.eu)](https://www.bihappy.eu)

To use this api:

     let BIHappy = BIHappyAPI.sharedInstance
         BIHappy.registerKEY("myAPIkeyGoesHere");
         // In the API settings you can change Sandbox Mode
 
         // Ask via BIHappy.eu (default)
         BIHappy.login(permissions: ["profile"]) { result in
             if (result) {
                 print("Welcome \(BIHappy.user)")
             } else {
                 print("Failed")
             }
         }
         
Or read the [wiki](https://github.com/BIHappy-Europe/BIHappy.eu-iOS-API/wiki)