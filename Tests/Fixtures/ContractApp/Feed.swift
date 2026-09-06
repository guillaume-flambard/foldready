import SwiftUI

// Fixture for the result-contract golden check. Keep it small and stable: any edit here
// changes Tests/Fixtures/contract-golden.json and must be deliberate.
struct Feed: View {
    var body: some View {
        NavigationStack {
            List(1...5, id: \.self) { Text("\($0)") }
                .frame(width: 320, height: 480)
        }
    }
}
