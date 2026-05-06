//
//  TherapistModel.swift
//  HealSync
//
//  Created by Arfa on 25/02/2026.
//
import Firebase

struct Therapist: Codable {
    let about: String
    let contactNo: String
    let dob: String?
    let createdAt: String
    let email: String
    let experience: Int
    let fullName: String
    let gender: String
    let licenseNo: String
    let location: String?
    let qualification: String
    let role: String
    let specialization: String
    let tagline: String
    let tags: [String]
    let uid: String
    let profileImageURL: String
    let licenseURL: String
    let verificationStatus: String
    let schedule: [String: [String]]
    let prices: [String: Int]
    let languages: [String]
    let sessionDurations: [String: Int]
    let isOnboardingComplete: Bool

    init?(document: DocumentSnapshot) {
        guard let data = document.data(),
              let fullName = data["fullName"] as? String,
              let specialization = data["specialization"] as? String else {
            return nil
        }

        self.uid            = document.documentID
        self.fullName       = fullName
        self.specialization = specialization

        self.about              = data["about"]              as? String ?? ""
        self.contactNo          = data["contactNo"]          as? String ?? ""
        self.dob                = data["dob"]                as? String ?? ""
        self.createdAt          = data["createdAt"]          as? String ?? ""
        self.email              = data["email"]              as? String ?? ""
        self.experience         = data["experience"]         as? Int    ?? 0
        self.gender             = data["gender"]             as? String ?? ""
        self.licenseNo          = data["licenseNo"]          as? String ?? ""
        self.location           = data["location"]           as? String ?? ""
        self.qualification      = data["qualification"]      as? String ?? ""
        self.role               = data["role"]               as? String ?? ""
        self.tagline            = data["tagline"]            as? String ?? ""
        self.tags               = data["tags"]               as? [String]      ?? []
        self.profileImageURL    = data["profileImageURL"]    as? String ?? ""
        self.licenseURL         = data["licenseURL"]         as? String ?? ""
        self.verificationStatus = data["verificationStatus"] as? String ?? "pending"
        self.schedule           = data["schedule"]           as? [String: [String]] ?? [:]
        self.prices             = data["prices"]             as? [String: Int]  ?? ["Video": 1000, "Audio": 700, "Chat": 500]
        self.languages          = data["languages"]          as? [String]       ?? []
        self.sessionDurations   = data["sessionDurations"]   as? [String: Int]  ?? ["Video": 60, "Audio": 45, "Chat": 30]
        self.isOnboardingComplete = data["isOnboardingComplete"] as? Bool ?? false
    }
}
