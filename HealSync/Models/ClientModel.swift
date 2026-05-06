//
//  ClientModel.swift
//  HealSync
//
//  Created by Arfa on 25/02/2026.
//

import Firebase

struct ClientModel {
    let id: String
    let fullName: String
    let contactNumber: String?
    let dob: String?
    let gender: String?
    let location: String?
    let primaryConcern: String?
    let therapyHistory: Bool
    let medication: Bool
    let safetyCheck: Bool
    let guardianName: String?
    let guardianContact: String?
    let sessionFormat: String?
    let preferredLanguage: String?
    let preferredTherapistGender: String?
    let termsAccepted: Bool
    let role: String
    let profileImageURL: String
    let isOnboardingComplete: Bool
    
    init?(document: DocumentSnapshot) {
        guard let data = document.data(),
              let fullName = data["fullName"] as? String,
              let role = data["role"] as? String,
              let therapyHistory = data["therapyHistory"] as? Bool,
              let medication = data["medication"] as? Bool,
              let safetyCheck = data["safetyCheck"] as? Bool,
              let termsAccepted = data["termsAccepted"] as? Bool else{
            return nil
        }
        
        self.isOnboardingComplete = data["isOnboardingComplete"] as? Bool ?? false
        
        self.id = document.documentID
        self.fullName = fullName
        self.role = role
        self.contactNumber = data["contactNumber"] as? String
        self.dob = data["dob"] as? String
        self.gender = data["gender"] as? String
        self.location = data["location"] as? String
        self.primaryConcern = data["primaryConcern"] as? String
        self.therapyHistory = therapyHistory
        self.medication = medication
        self.safetyCheck = safetyCheck
        self.guardianName = data["guardianName"] as? String
        self.guardianContact = data["guardianContact"] as? String
        self.sessionFormat = data["sessionFormat"] as? String
        self.preferredLanguage = data["preferredLanguage"] as? String
        self.preferredTherapistGender = data["preferredTherapistGender"] as? String
        self.profileImageURL = data["profileImageURL"] as? String ?? ""
        self.termsAccepted = termsAccepted
    }
}
