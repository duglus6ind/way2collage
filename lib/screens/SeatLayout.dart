import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SeatLayoutPage extends StatelessWidget {
  final String busId;
  final bool readOnly;

  const SeatLayoutPage({
    super.key,
    required this.busId,
    required this.readOnly,
  });

  static const int totalSeats = 50;
  static const int seatsPerRow = 5;
  static const double seatGap = 8;
  static const double aisleGap = 20;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B5C43),
      body: SafeArea(
        child: Column(
          children: [
            // TOP BAR
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _iconButton(Icons.arrow_back, () => Navigator.pop(context)),
                  const Spacer(),
                  Text(
                    readOnly ? "Seat Availability" : "Select Occupied Seats",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            // MAIN CARD
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('Buses')
                      .doc(busId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final busData =
                        snapshot.data!.data() as Map<String, dynamic>;

                    final List<int> occupiedSeats = List<int>.from(
                      busData['occupiedSeats'] ?? [],
                    );

                    return Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: _seatGrid(context, occupiedSeats),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // LEGEND
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _legend(Colors.grey.shade700, "Occupied"),
                            _legend(Colors.grey.shade300, "Available"),
                            Text(
                              "Available: ${totalSeats - occupiedSeats.length}",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= SEAT GRID =================

  Widget _seatGrid(BuildContext context, List<int> occupiedSeats) {
    final screenWidth = MediaQuery.of(context).size.width;
    const horizontalPadding = 40.0;

    final totalGapWidth = (seatGap * (seatsPerRow - 1)) + aisleGap;

    final seatSize =
        (screenWidth - horizontalPadding - totalGapWidth) / seatsPerRow;

    return Column(
      children: List.generate((totalSeats / seatsPerRow).ceil(), (rowIndex) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(seatsPerRow, (colIndex) {
              final seatIndex = rowIndex * seatsPerRow + colIndex;

              if (seatIndex >= totalSeats) return const SizedBox();

              return Row(
                children: [
                  _seatBox(
                    seatIndex,
                    seatSize,
                    occupiedSeats.contains(seatIndex),
                    occupiedSeats,
                  ),
                  if (colIndex != seatsPerRow - 1) SizedBox(width: seatGap),
                  if (colIndex == 1) const SizedBox(width: aisleGap),
                ],
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _seatBox(
    int index,
    double size,
    bool isOccupied,
    List<int> occupiedSeats,
  ) {
    return GestureDetector(
      onTap: readOnly
          ? null
          : () async {
              final updatedSeats = List<int>.from(occupiedSeats);
              isOccupied ? updatedSeats.remove(index) : updatedSeats.add(index);

              await FirebaseFirestore.instance
                  .collection('Buses')
                  .doc(busId)
                  .update({'occupiedSeats': updatedSeats});
            },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isOccupied ? Colors.grey.shade700 : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 2,
              offset: Offset(1, 2),
            ),
          ],
        ),
      ),
    );
  }

  // ================= UI HELPERS =================

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.black),
      ),
    );
  }

  Widget _legend(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(text),
      ],
    );
  }
}
