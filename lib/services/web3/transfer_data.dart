class TransferData {
  final String description;

  TransferData(this.description);

  // from json
  TransferData.fromJson(Map<String, dynamic> json)
      : description = json['description'];

  // to json
  Map<String, dynamic> toJson() => {
        'description': description,
      };
}
