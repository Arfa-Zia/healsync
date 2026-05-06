//
//  TherapistOnboardingData.swift
//  HealSync
//
//  Created by Arfa on 11/03/2026.
//

import Foundation

struct TherapistOnboardingData {
    // Step 1: Profile Details
    var contactNo: String?
    var dob: String?
    var gender: String?
    var location: String?

    // Step 2: Qualifications
    var qualification: String?
    var licenseNo: String?
    var specialization: String?
    var experience: Int?
    var termsAccepted: Bool = false
}
