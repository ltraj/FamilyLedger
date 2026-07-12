/// Describes one file or folder included in an export bundle.
///
/// A list of these forms the manifest inside `metadata.json`, giving a
/// reader (human or AI) a table of contents before it opens any other file
/// in the bundle.
class ExportedFileDescriptorModel {
  const ExportedFileDescriptorModel({
    required this.fileName,
    required this.description,
    this.recordCount,
  });

  /// Name of the file or folder, e.g. `people.json` or `attachments`.
  final String fileName;

  /// One-sentence explanation of what this file or folder contains.
  final String description;

  /// Number of records contained in this file, or number of files inside
  /// this folder. Null for single-object files such as `settings.json`.
  final int? recordCount;

  Map<String, dynamic> toJson() => {
    'fileName': fileName,
    'description': description,
    'recordCount': recordCount,
  };

  factory ExportedFileDescriptorModel.fromJson(Map<String, dynamic> json) {
    return ExportedFileDescriptorModel(
      fileName: json['fileName'] as String,
      description: json['description'] as String,
      recordCount: json['recordCount'] as int?,
    );
  }
}
