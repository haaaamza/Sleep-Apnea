//
//  dataStore.swift
//  Sleep_Apnea
//
//  Created by Hamza Mian on 2021-01-25.
//
import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import CoreBluetooth

var username: String = ""
var peripheralName: String? = ""
var pheriphID: UUID? = UUID(uuidString: "abcd")
//var pheriphID : UUID {
//    get{
//        return UUID(uuidString: UUID_str)
//    }
//    set (id){
//
//    }
//}//= UUID(uuidString: "") ?? UUID(uuidString: "abcd") as! UUID//NSUUID = NSUUID(uuidString: "")!
struct Notification: Codable, Identifiable{ //Structure we write to Firebase
    @DocumentID var docID: String?
    var id: String = username //MARK: See if you need DocumentID
    var EOG: Int
    var epoch: Int
    var bleTime: Int
    @ServerTimestamp var createdTime: Timestamp?
}
typealias α = Float

struct accelerometer_data{
    var x : Float?
    var y: Float?
    var z : Float?
}

extension CBUUID{
    /// Inertial Measurement (custom) (aka Acceleration and Orientation)
    static let InertialMeasurement = CBUUID(string:  "0xa4e649f4-4be5-11e5-885d-feff819cdc9f")
    
    static let AccelerationMeasurement = CBUUID(string:  "0xc4c1f6e2-4be5-11e5-885d-feff819cdc9f")
    
    static let headBand = CBUUID(string:
        "57D59FA8-2E1B-7E40-482E-C442247F2911")
    
    static let bandService = CBUUID(string:
        "49535343-FE7D-4AE5-8FA9-9FAFD205E455")
    
    static let readBand = CBUUID(string:
        "49535343-1E4D-4BD9-BA61-23C647249616")
}
class timeSet {
    private var myInitStamp:TimeInterval?;
    var publicGetter:TimeInterval{
        set {
            if myInitStamp == nil {
                myInitStamp = newValue;
            }

        }
        get {
            return myInitStamp!;
        }
    }
}
