class DigiModel {
  final int id;
  final String name;
  final String image;

  DigiModel({required this.id, required this.name, required this.image});

  factory DigiModel.fromJson(Map<String, dynamic> json) {
    return DigiModel(id: json['id'], name: json['name'], image: json['image']);
  }
}
