//
//  notificationRepository.swift
//  Sleep_Apnea
//
//  Created by Hamza Mian on 2021-01-25.
//
import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

class notificationRepository: ObservableObject{
    let db = Firestore.firestore()
    @Published var notifications = [Notification]()
    
    func checkUser(_ notif: Notification){
        if username != "" {
            let docRef = db.collection("users").document(notif.id)
            docRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    let dataDescription = document.data().map(String.init(describing:)) ?? "nil"
                    print("Document data: \(dataDescription)")
                } else {
                    print("Document does not exist, adding user")
                    self.addUser(notif)
                }
            }
        }
    }
    func addUser(_ notif: Notification){
        if username != ""{ //TODO: Confirm this in ViewController, then instantiate the notif.
            db.collection("users").document(notif.id).setData([
                "name": notif.id
            ]) { err in
                if let err = err {
                    print("Error writing document: \(err)")
                } else {
                    print("Document successfully written!")
                }
            }
        }
    }
    func addData(_ notif: Notification){
        if username != "" {
            do {
                try db.collection("users").document(username).collection("data").addDocument(from: notif)
//                try db.collection("users").document(username).setData([
//                                                                        "epoch": FieldValue.increment(Int64(1)),
//                                                                        "EOG": notif.EOG,
//                                                                        "createdTime": notif.createdTime,
//                                                                        "docId": notif.docID])//collection("data").addDocument(from: notif)
                print("WRITE SUCCESS")
            } catch{
                fatalError("Unable to encode task: \(error.localizedDescription)")
            }
        }
    }
}

