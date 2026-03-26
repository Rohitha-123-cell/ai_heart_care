import 'package:web/web.dart' as web;
import 'dart:js_interop';

void downloadTextFile(String content, String fileName) {
  final blob = web.Blob(
    [content.toJS].toJS,
    web.BlobPropertyBag(type: 'text/plain'),
  );
  final url = web.URL.createObjectURL(blob);
  (web.document.createElement('a') as web.HTMLAnchorElement)
    ..href = url
    ..setAttribute('download', fileName)
    ..click();
  web.URL.revokeObjectURL(url);
}

void printPage() {
  web.window.print();
}
