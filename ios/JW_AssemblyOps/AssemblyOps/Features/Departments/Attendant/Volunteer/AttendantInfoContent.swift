//
//  AttendantInfoContent.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/21/26.
//

// MARK: - Attendant Info Content
//
// Static data model for CO-23 (Assembly and Convention Attendant Instructions)
// quick-reference reminders. Each section groups related topics with localized
// bullet-point reminders. No ViewModel needed — purely static, read-only content.
//

import Foundation

struct AttendantInfoSection: Identifiable {
    let id: String
    let icon: String
    let titleKey: String
    let reminders: [AttendantReminder]
}

struct AttendantReminder: Identifiable {
    let id: String
    var isHighlighted: Bool = false
}

enum AttendantInfoContent {
    static let sections: [AttendantInfoSection] = [
        // 1. General Conduct & Preparation
        AttendantInfoSection(
            id: "conduct",
            icon: "person.badge.shield.checkmark",
            titleKey: "attendant.info.section.conduct",
            reminders: [
                AttendantReminder(id: "attendant.info.conduct.exemplary"),
                AttendantReminder(id: "attendant.info.conduct.alert"),
                AttendantReminder(id: "attendant.info.conduct.meeting"),
                AttendantReminder(id: "attendant.info.conduct.position15min"),
                AttendantReminder(id: "attendant.info.conduct.badge"),
                AttendantReminder(id: "attendant.info.conduct.stayAssigned"),
            ]
        ),

        // 2. Entrances & Seating
        AttendantInfoSection(
            id: "entrances",
            icon: "door.left.hand.open",
            titleKey: "attendant.info.section.entrances",
            reminders: [
                AttendantReminder(id: "attendant.info.entrances.elderly8am"),
                AttendantReminder(id: "attendant.info.entrances.general815"),
                AttendantReminder(id: "attendant.info.entrances.checkExits"),
                AttendantReminder(id: "attendant.info.entrances.doorsNotPropped"),
                AttendantReminder(id: "attendant.info.entrances.noSeatSaving"),
                AttendantReminder(id: "attendant.info.entrances.seatSavingRules"),
                AttendantReminder(id: "attendant.info.entrances.strollers"),
                AttendantReminder(id: "attendant.info.entrances.seatLatecomers"),
                AttendantReminder(id: "attendant.info.entrances.assistElders"),
            ]
        ),

        // 3. Attendance Counting
        AttendantInfoSection(
            id: "counting",
            icon: "number.circle",
            titleKey: "attendant.info.section.counting",
            reminders: [
                AttendantReminder(id: "attendant.info.counting.informed"),
                AttendantReminder(id: "attendant.info.counting.noDistraction"),
                AttendantReminder(id: "attendant.info.counting.countAll"),
            ]
        ),

        // 4. Handling Distractions
        AttendantInfoSection(
            id: "distractions",
            icon: "speaker.slash",
            titleKey: "attendant.info.section.distractions",
            reminders: [
                AttendantReminder(id: "attendant.info.distractions.sources"),
                AttendantReminder(id: "attendant.info.distractions.kindly"),
                AttendantReminder(id: "attendant.info.distractions.remote"),
            ]
        ),

        // 5. Safety & Emergencies
        AttendantInfoSection(
            id: "safety",
            icon: "exclamationmark.shield",
            titleKey: "attendant.info.section.safety",
            reminders: [
                AttendantReminder(id: "attendant.info.safety.watch"),
                AttendantReminder(id: "attendant.info.safety.wetFloors"),
                AttendantReminder(id: "attendant.info.safety.railings"),
                AttendantReminder(id: "attendant.info.safety.upperLevels"),
                AttendantReminder(id: "attendant.info.safety.nonmedical"),
                AttendantReminder(id: "attendant.info.safety.flashlight"),
                AttendantReminder(id: "attendant.info.safety.medical"),
                AttendantReminder(id: "attendant.info.safety.reportInfo"),
            ]
        ),

        // 6. Lost Persons & Threats
        AttendantInfoSection(
            id: "lostPersons",
            icon: "person.crop.circle.badge.exclamationmark",
            titleKey: "attendant.info.section.lostPersons",
            reminders: [
                AttendantReminder(id: "attendant.info.lost.bringToLF"),
                AttendantReminder(id: "attendant.info.lost.notifyOverseer"),
                AttendantReminder(id: "attendant.info.lost.missingPerson"),
                AttendantReminder(id: "attendant.info.lost.bombThreat", isHighlighted: true),
                AttendantReminder(id: "attendant.info.lost.noBombAlarm", isHighlighted: true),
            ]
        ),

        // 7. Escalators, Stage & Baptism
        AttendantInfoSection(
            id: "facilities",
            icon: "stairs",
            titleKey: "attendant.info.section.facilities",
            reminders: [
                AttendantReminder(id: "attendant.info.facilities.escalators"),
                AttendantReminder(id: "attendant.info.facilities.escalatorStop"),
                AttendantReminder(id: "attendant.info.facilities.assistElderly"),
                AttendantReminder(id: "attendant.info.facilities.stageAccess"),
                AttendantReminder(id: "attendant.info.facilities.noPhotos"),
                AttendantReminder(id: "attendant.info.facilities.baptism"),
            ]
        ),

        // 8. Disruptions & Violence
        AttendantInfoSection(
            id: "disruptions",
            icon: "shield.lefthalf.filled.trianglebadge.exclamationmark",
            titleKey: "attendant.info.section.disruptions",
            reminders: [
                AttendantReminder(id: "attendant.info.disruptions.twoApproach"),
                AttendantReminder(id: "attendant.info.disruptions.apostates"),
                AttendantReminder(id: "attendant.info.disruptions.calmFirst"),
                AttendantReminder(id: "attendant.info.disruptions.askToLeave"),
                AttendantReminder(id: "attendant.info.disruptions.noForce"),
                AttendantReminder(id: "attendant.info.disruptions.avoidDenyDefend", isHighlighted: true),
                AttendantReminder(id: "attendant.info.disruptions.callPolice", isHighlighted: true),
                AttendantReminder(id: "attendant.info.disruptions.lockDoors", isHighlighted: true),
                AttendantReminder(id: "attendant.info.disruptions.noWeapons", isHighlighted: true),
            ]
        ),
    ]
}
