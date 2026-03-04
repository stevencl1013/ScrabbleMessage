import SwiftUI

struct BlankPickerView: View {
    @Binding var isPresented: Bool
    var onLetterSelected: (Character) -> Void

    private let letters: [Character] = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Choose a letter for the blank tile")
                    .font(.headline)

                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(letters, id: \.self) { letter in
                        Button(action: {
                            onLetterSelected(letter)
                            isPresented = false
                        }) {
                            Text(String(letter))
                                .font(.title2.bold())
                                .frame(width: 44, height: 44)
                                .background(Color(red: 0.95, green: 0.89, blue: 0.76))
                                .cornerRadius(6)
                                .foregroundColor(.black)
                        }
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top)
            .navigationTitle("Blank Tile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
    }
}
