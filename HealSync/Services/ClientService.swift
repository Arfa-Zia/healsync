//
//  ClientService.swift
//  HealSync
//
//  Created by Arfa on 25/02/2026.
//
import FirebaseAuth
import FirebaseFirestore

class ClientService {
    
    static let shared = ClientService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    func fetchCurrentUser(completion: @escaping (ClientModel?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(nil)
            return
        }
        
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching user:", error.localizedDescription)
                completion(nil)
                return
            }
            
            guard let document = snapshot, let _ = document.data() else {
                completion(nil)
                return
            }
            
            let user = ClientModel(document: document)
            completion(user)
        }
    }
    
}
