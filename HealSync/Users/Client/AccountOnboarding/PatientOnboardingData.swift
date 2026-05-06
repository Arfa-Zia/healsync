//
//  PatientOnboardingData.swift
//  HealSync
//
//  Created by Arfa on 23/02/2026.
//

import Foundation

struct PatientOnboardingData {
    // Step 1: Profile Details
    var contactNumber: String?
    var dob: String?
    var gender: String?
    var location: String?

    // Step 2: Patient History
    var primaryConcern: String?
    var therapyHistory: Bool?
    var medication: Bool?
    var safetyCheck: Bool?

    // Step 3: Emergency Contact
    var guardianName: String?
    var guardianContact: String?

    // Step 4: Preferences
    var sessionFormat: String?
    var preferredLanguage: String?
    var preferredTherapistGender: String?
    var termsAccepted: Bool = false
}
