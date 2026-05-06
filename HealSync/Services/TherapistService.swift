//
//  TherapistService.swift
//  HealSync
//
//  Created by Arfa on 25/02/2026.
//

import Firebase
import FirebaseFirestore

class TherapistService {
    
    static let shared = TherapistService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    func fetchSuggestedTherapists(limit: Int = 4, completion: @escaping ([Therapist]) -> Void) {
        db.collection("users")
            .whereField("role", isEqualTo: "therapist")
            .whereField("verificationStatus", isEqualTo: "approved")
            .limit(to: limit)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching therapists:", error.localizedDescription)
                    completion([])
                    return
                }
                
                let therapists = snapshot?.documents.compactMap { Therapist(document: $0) } ?? []
                completion(therapists)
            }
    }
  
    func fetchAllTherapists(completion: @escaping ([Therapist]) -> Void) {
        db.collection("users")
            .whereField("role", isEqualTo: "therapist")
            .whereField("verificationStatus", isEqualTo: "approved")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching therapists:", error.localizedDescription)
                    completion([])
                    return
                }
                
                let therapists = snapshot?.documents.compactMap { Therapist(document: $0) } ?? []
                completion(therapists)
            }
    }
    
    func fetchTherapist(uid: String, completion: @escaping (Therapist?) -> Void) {
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching therapist:", error.localizedDescription)
                completion(nil)
                return
            }
            
            guard let snapshot = snapshot else {
                completion(nil)
                return
            }
            
            let therapist = Therapist(document: snapshot)
            completion(therapist)
        }
    }
    
    func searchTherapists(query: String, completion: @escaping ([Therapist]) -> Void) {
        db.collection("users")
            .whereField("role", isEqualTo: "therapist")
            .whereField("verificationStatus", isEqualTo: "approved")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching therapists for search:", error.localizedDescription)
                    completion([])
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                
                let filtered = documents.compactMap { Therapist(document: $0) }.filter {
                    $0.fullName.lowercased().contains(query.lowercased()) ||
                    $0.tags.contains(where: { $0.lowercased().contains(query.lowercased()) })
                }
                
                completion(filtered)
            }
    }
}
