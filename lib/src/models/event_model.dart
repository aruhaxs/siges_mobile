class Event {
  final String title;
  final String date;
  final String time;
  final String location;
  final String description;

  Event({
    required this.title,
    required this.date,
    required this.time,
    required this.location,
    required this.description,
  });

  factory Event.fromFcmPayload(Map<String, dynamic> payload) {
    return Event(
      title: payload['eventName'] ?? 'Tanpa Judul',
      date: payload['eventDate'] ?? 'Tanggal tidak tersedia',
      time: payload['eventTime'] ?? 'Waktu tidak tersedia',
      location: payload['eventLocation'] ?? 'Lokasi tidak tersedia',
      description: payload['eventDescription'] ?? 'Tidak ada deskripsi.',
    );
  }
}