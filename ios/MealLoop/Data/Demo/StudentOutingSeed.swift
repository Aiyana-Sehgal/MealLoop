#if DEMO_DATA || REVIEW_DATA
import Foundation

/// SAMPLE, NOT MEASURED. The Student side of the outing story (file nzzTAm9YnJRSdKEeYUWUEb, page 07, frames cited).
/// No value here is a real outing.
enum StudentOutingSeed {
    /// The signed-in sample student (Aarav ••0238) is the outing story's Aarav: the same masked ID and block.
    static let links: [StudentID: OutingStudent] = [DemoSeed.sampleStudent.id: OutingSeed.aarav]

    /// You · Outings (1848:22270), "Earlier": "Sat 10 Aug · Family · Back 7:15 PM · on time", "Sun 4 Aug · Shopping ·
    /// The warden said no", "Sat 27 Jul · Family · Back 6:48 PM · on time", "Sun 21 Jul · Medical · Back 1:55 PM ·
    /// on time". Only the visible rows are seeded.
    static let earlier: [StudentPastOuting] = [
        StudentPastOuting(id: "demo-past-0810", day: OutingSeed.at(8, 10, 12, 0), reason: "Family",
                          outcome: .returned(at: OutingSeed.at(8, 10, 19, 15), onTime: true)),
        StudentPastOuting(id: "demo-past-0804", day: OutingSeed.at(8, 4, 12, 0), reason: "Shopping", outcome: .wardenSaidNo),
        StudentPastOuting(id: "demo-past-0727", day: OutingSeed.at(7, 27, 12, 0), reason: "Family",
                          outcome: .returned(at: OutingSeed.at(7, 27, 18, 48), onTime: true)),
        StudentPastOuting(id: "demo-past-0721", day: OutingSeed.at(7, 21, 12, 0), reason: "Medical",
                          outcome: .returned(at: OutingSeed.at(7, 21, 13, 55), onTime: true)),
    ]
}
#endif
