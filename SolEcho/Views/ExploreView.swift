import SwiftUI

/// First test screen: walk around the world map. The full survival game builds on top of this.
struct ExploreView: View {
    @State private var position = World.start
    @State private var message = "You wake in tall grass. No name. No food. No supplies. Lake to the east, mountains to the south. You need to survive."

    private var biome: Biome { World.biome(at: position) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Sol Echo")
                    .font(.largeTitle.bold())
                    .foregroundStyle(
                        LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing)
                    )
                    .accessibilityAddTraits(.isHeader)

                VStack(alignment: .leading, spacing: 8) {
                    Text("\(biome.symbol) \(biome.regionName)")
                        .font(.title2.bold())
                        .accessibilityAddTraits(.isHeader)
                    Text(World.description(at: position))
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
                .accessibilityElement(children: .combine)

                Text(message)
                    .font(.callout)
                    .italic()

                VStack(alignment: .leading, spacing: 4) {
                    ForEach(World.surroundings(of: position), id: \.0) { dir, label in
                        Text("\(dir.label): \(label)")
                            .font(.subheadline)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Surroundings")
                .accessibilityValue(
                    World.surroundings(of: position).map { "\($0.0.label), \($0.1)" }.joined(separator: ". ")
                )

                compass
            }
            .padding()
        }
        .background(Color(red: 0.07, green: 0.06, blue: 0.10).ignoresSafeArea())
    }

    private var compass: some View {
        Grid(horizontalSpacing: 12, verticalSpacing: 12) {
            GridRow {
                Color.clear.frame(width: 1, height: 1)
                moveButton(.north)
                Color.clear.frame(width: 1, height: 1)
            }
            GridRow {
                moveButton(.west)
                Image(systemName: "sun.max.fill")
                    .font(.title)
                    .foregroundStyle(.yellow)
                    .accessibilityHidden(true)
                moveButton(.east)
            }
            GridRow {
                Color.clear.frame(width: 1, height: 1)
                moveButton(.south)
                Color.clear.frame(width: 1, height: 1)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func moveButton(_ direction: Direction) -> some View {
        let next = World.neighbor(of: position, toward: direction)
        let canMove = World.contains(next)
        return Button {
            position = next
            message = "You travel \(direction.rawValue)."
            UIAccessibility.post(
                notification: .announcement,
                argument: "\(World.biome(at: next).regionName). \(World.description(at: next))"
            )
        } label: {
            Image(systemName: direction.arrow)
                .font(.title2.bold())
                .frame(width: 64, height: 64)
                .background(.orange.opacity(canMove ? 0.25 : 0.08), in: Circle())
        }
        .disabled(!canMove)
        .accessibilityLabel("Go \(direction.label)")
        .accessibilityHint(canMove ? World.biome(at: next).regionName : "Impassable")
    }
}
