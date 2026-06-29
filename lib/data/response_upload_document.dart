class ResponseUploadDocument {
  bool? success;
  Document? document;

  ResponseUploadDocument({this.success, this.document});

  factory ResponseUploadDocument.fromJson(Map<String, dynamic> json) {
    return ResponseUploadDocument(
      success: json["success"],
      document:
          json["document"] != null ? Document.fromJson(json["document"]) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "success": success,
    "document": document?.toJson(),
  };
}

class Document {
  String? user;
  String? type;
  String? fileUrl;
  String? filename;
  String? status;
  String? id; // Mapeia o "_id" do JSON
  String? createdAt;
  String? updatedAt;
  int? v; // Mapeia o "__v" do JSON

  Document({
    this.user,
    this.type,
    this.fileUrl,
    this.filename,
    this.status,
    this.id,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      user: json["user"],
      type: json["type"],
      fileUrl: json["fileUrl"],
      filename: json["filename"],
      status: json["status"],
      id: json["_id"], // Atenção ao underline aqui
      createdAt: json["createdAt"],
      updatedAt: json["updatedAt"],
      v: json["__v"],
    );
  }

  Map<String, dynamic> toJson() => {
    "user": user,
    "type": type,
    "fileUrl": fileUrl,
    "filename": filename,
    "status": status,
    "_id": id,
    "createdAt": createdAt,
    "updatedAt": updatedAt,
    "__v": v,
  };
}
