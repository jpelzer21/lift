import SwiftUI

struct GroupCard: View {
    var groupName: String
    var groupDescription: String
    var onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(groupName)
                .font(.headline)
                .fontWeight(.bold)
                .lineLimit(1)
                .truncationMode(.tail)
            
            Text(groupDescription)
                .font(.subheadline)
                .foregroundColor(.gray)
                .lineLimit(2)
                .truncationMode(.tail)

            HStack {
                Spacer()
                Text("Join Group")
                    .font(.subheadline)
                    .foregroundColor(.pink)
                    .padding(.top, 5)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
        .onTapGesture {
            onTap()
        }
    }
}