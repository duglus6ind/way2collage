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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECEFF1),
      body: SafeArea(
        child: Column(
          children: [
            // ================= PREMIUM HEADER =================
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0B5C43), Color(0xFF1E8E66)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                // borderRadius: BorderRadius.vertical(
                //   bottom: Radius.circular(28),
                // ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                  child: Row(
                    children: [
                      // 🔹 Back Button (Glass Style)
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          height: 42,
                          width: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // 🔹 Title
                      const Expanded(
                        child: Text(
                          "Choose Your Seat",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),

                      // 🔹 Bus Details Capsule
                      GestureDetector(
                        onTap: () {
                          // Navigate to bus details
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.25),
                            ),
                          ),
                          child: const Text(
                            "Bus Details",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ================= SEAT CARD =================
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Buses')
                    .doc(busId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  final List<int> occupiedSeats = List<int>.from(
                    data['occupiedSeats'] ?? [],
                  );

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      const seatGap = 8.0;
                      const aisleGap = 20.0;
                      const bottomSectionHeight = 110.0;
                      const cardPadding = 40.0; // 20 top + 20 bottom
                      const cabinSpacing = 40.0; // Driver text + gap

                      final rows = (totalSeats / seatsPerRow).ceil();

                      final totalGapWidth =
                          (seatGap * (seatsPerRow - 1)) + aisleGap;

                      final totalGapHeight = seatGap * (rows - 1);

                      // Width-based seat size
                      final seatWidth =
                          (constraints.maxWidth - 60 - totalGapWidth) /
                          seatsPerRow;

                      // 🔥 Proper height calculation
                      final usableHeight =
                          constraints.maxHeight -
                          bottomSectionHeight -
                          cardPadding -
                          cabinSpacing -
                          totalGapHeight;

                      final seatHeight = usableHeight / rows;

                      // Final safe size
                      final seatSize = seatWidth < seatHeight
                          ? seatWidth
                          : seatHeight;

                      final gridWidth =
                          (seatSize * seatsPerRow) + totalGapWidth;

                      return Column(
                        children: [
                          Expanded(
                            child: Center(
                              child: Container(
                                width: gridWidth + 40,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      "Driver Cabin",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    /// 🔥 REMOVE Expanded here
                                    Flexible(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: List.generate(rows, (
                                          rowIndex,
                                        ) {
                                          return Padding(
                                            padding: EdgeInsets.only(
                                              bottom: rowIndex == rows - 1
                                                  ? 0
                                                  : seatGap,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: List.generate(
                                                seatsPerRow,
                                                (colIndex) {
                                                  final seatIndex =
                                                      rowIndex * seatsPerRow +
                                                      colIndex;

                                                  if (seatIndex >= totalSeats) {
                                                    return SizedBox(
                                                      width: seatSize,
                                                    );
                                                  }

                                                  return Row(
                                                    children: [
                                                      _seatBox(
                                                        seatIndex + 1,
                                                        seatSize,
                                                        occupiedSeats.contains(
                                                          seatIndex,
                                                        ),
                                                      ),
                                                      if (colIndex !=
                                                          seatsPerRow - 1)
                                                        const SizedBox(
                                                          width: seatGap,
                                                        ),
                                                      if (colIndex == 1)
                                                        const SizedBox(
                                                          width: aisleGap,
                                                        ),
                                                    ],
                                                  );
                                                },
                                              ),
                                            ),
                                          );
                                        }),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // LEGEND
                          Container(
                            height: bottomSectionHeight,
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _legend(Colors.grey.shade300, "Available"),
                                    _legend(Colors.grey.shade700, "Occupied"),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  "Available Seats: ${totalSeats - occupiedSeats.length}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= SEAT =================

  Widget _seatBox(int seatNumber, double size, bool isOccupied) {
    return GestureDetector(
      onTap: readOnly
          ? null
          : () async {
              final docRef = FirebaseFirestore.instance
                  .collection('Buses')
                  .doc(busId);

              final snapshot = await docRef.get();
              final data = snapshot.data() as Map<String, dynamic>;

              List<int> updatedSeats = List<int>.from(
                data['occupiedSeats'] ?? [],
              );

              final seatIndex = seatNumber - 1;

              if (updatedSeats.contains(seatIndex)) {
                updatedSeats.remove(seatIndex);
              } else {
                updatedSeats.add(seatIndex);
              }

              await docRef.update({'occupiedSeats': updatedSeats});
            },
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isOccupied ? Colors.grey.shade600 : Colors.white,
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          seatNumber.toString(),
          style: TextStyle(
            fontSize: size * 0.35,
            fontWeight: FontWeight.w600,
            color: isOccupied ? Colors.white : Colors.black87,
          ),
        ),
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
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }
}
