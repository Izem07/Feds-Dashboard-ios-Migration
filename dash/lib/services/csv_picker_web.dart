// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void pickCsvFile(void Function(String name, String content) onPicked) {
  final input = html.FileUploadInputElement()..accept = '.csv';
  input.click();
  input.onChange.listen((_) {
    final file = input.files?.first;
    if (file == null) return;
    final reader = html.FileReader();
    reader.readAsText(file);
    reader.onLoadEnd.listen((_) {
      final content = reader.result as String?;
      if (content != null) onPicked(file.name, content);
    });
  });
}
