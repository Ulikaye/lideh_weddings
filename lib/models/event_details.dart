/// Mirrors the single "event" document in Firestore (collection `event`,
/// doc id `config`). One wedding per deployment, same as the original app.
class EventDetails {
  final String brideName;
  final String groomName;
  final String weddingDate; // ISO yyyy-MM-dd, kept as string like the original
  final String venue;
  final num singleAmount;
  final num doubleAmount;
  final String? brideImageUrl;
  final String? groomImageUrl;

  const EventDetails({
    this.brideName = '',
    this.groomName = '',
    this.weddingDate = '',
    this.venue = '',
    this.singleAmount = 50000,
    this.doubleAmount = 100000,
    this.brideImageUrl,
    this.groomImageUrl,
  });

  factory EventDetails.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const EventDetails();
    return EventDetails(
      brideName: map['brideName'] ?? '',
      groomName: map['groomName'] ?? '',
      weddingDate: map['weddingDate'] ?? '',
      venue: map['venue'] ?? '',
      singleAmount: map['singleAmount'] ?? 50000,
      doubleAmount: map['doubleAmount'] ?? 100000,
      brideImageUrl: map['brideImageUrl'],
      groomImageUrl: map['groomImageUrl'],
    );
  }

  Map<String, dynamic> toMap() => {
        'brideName': brideName,
        'groomName': groomName,
        'weddingDate': weddingDate,
        'venue': venue,
        'singleAmount': singleAmount,
        'doubleAmount': doubleAmount,
        'brideImageUrl': brideImageUrl,
        'groomImageUrl': groomImageUrl,
      };

  EventDetails copyWith({
    String? brideName,
    String? groomName,
    String? weddingDate,
    String? venue,
    num? singleAmount,
    num? doubleAmount,
    String? brideImageUrl,
    String? groomImageUrl,
  }) {
    return EventDetails(
      brideName: brideName ?? this.brideName,
      groomName: groomName ?? this.groomName,
      weddingDate: weddingDate ?? this.weddingDate,
      venue: venue ?? this.venue,
      singleAmount: singleAmount ?? this.singleAmount,
      doubleAmount: doubleAmount ?? this.doubleAmount,
      brideImageUrl: brideImageUrl ?? this.brideImageUrl,
      groomImageUrl: groomImageUrl ?? this.groomImageUrl,
    );
  }
}
