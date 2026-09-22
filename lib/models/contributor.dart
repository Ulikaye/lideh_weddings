import 'package:cloud_firestore/cloud_firestore.dart';

/// One row in the `contributors` collection. The document id IS the
/// contributor id (e.g. `WC-0001`), same scheme as the original app.
class Contributor {
  final String id;
  final String fullName;
  final String cardType; // 'Single' | 'Double'
  final num amount;
  final String date; // ISO yyyy-MM-dd
  final String phone;
  final bool checkedIn;
  final String? checkedInTime;

  const Contributor({
    required this.id,
    required this.fullName,
    required this.cardType,
    required this.amount,
    required this.date,
    this.phone = '',
    this.checkedIn = false,
    this.checkedInTime,
  });

  factory Contributor.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Contributor(
      id: doc.id,
      fullName: data['fullName'] ?? '',
      cardType: data['cardType'] ?? 'Single',
      amount: data['amount'] ?? 0,
      date: data['date'] ?? '',
      phone: data['phone'] ?? '',
      checkedIn: data['checkedIn'] ?? false,
      checkedInTime: data['checkedInTime'],
    );
  }

  Map<String, dynamic> toMap() => {
        'fullName': fullName,
        'cardType': cardType,
        'amount': amount,
        'date': date,
        'phone': phone,
        'checkedIn': checkedIn,
        'checkedInTime': checkedInTime,
      };

  /// Same compact pipe-delimited payload the original app encoded into its
  /// QR. The scanner only trusts the id (`WC-0001`) as the lookup key and
  /// re-reads the live Firestore record - the rest is just a fallback for
  /// humans/other tools that read the QR directly.
  String get qrPayload => [id, fullName, cardType, amount, date].join('|');
}
