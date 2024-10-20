import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';
import 'package:markdown/markdown.dart';
import 'package:intl/intl.dart';


final frontmatterRegex = RegExp(r'^---\n(.*)\n---', multiLine: true, dotAll: true);

class MarkdownDocument {
  final String title;
  final DateTime date;
  final String body;

  MarkdownDocument({required this.title, required this.date, required this.body});
}

void main(List<String> arguments) async {
  if (arguments.isEmpty) {
    print('No arguments provided. Please provide markdown file paths.');
    return;
  }

  // Ensure the dist directory exists
  final distDir = Directory('dist');
  if (!await distDir.exists()) {
    await distDir.create(recursive: true);
  }

  for (var filePath in arguments) {
    try {
      // Read the file
      final file = File(filePath);
      final contents = await file.readAsString();

      // Convert markdown to HTML
      final html = toHtml(parseMarkdown(contents));

      // Generate output file path
      final fileName = path.basenameWithoutExtension(filePath);
      final outputPath = path.join('dist', '$fileName.html');

      // Write HTML to file
      await File(outputPath).writeAsString(html);

      print('Converted $filePath to $outputPath');
    } catch (e) {
      print('Error processing file $filePath: $e');
    }
  }
}

String toHtml(MarkdownDocument document) {
  final dateFormatter = DateFormat('MMMM d, yyyy');
  var bodyHtml = markdownToHtml(document.body);
  bodyHtml = prefixRefs(bodyHtml);

  return '''
  <!DOCTYPE html>
  <html>
    <head>
      <link rel="stylesheet" href="../css/styles.css">
      <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/default.min.css">
      <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js"></script>
      <script>hljs.highlightAll();</script>
    </head>

    <body>
      <h1>${document.title}</h1>
      <i>${dateFormatter.format(document.date)}</i>
      ${bodyHtml}
    </body>
  </html>
  ''';
}

// 1. extract frontmatter and rest from markdown
// 2. prefix src references
// 3. assemble html
MarkdownDocument parseMarkdown(String markdown) {
  final frontmatter = parseFrontmatter(markdown);
  final body = markdown.replaceFirst(frontmatterRegex, '').trim();

  return MarkdownDocument(
    title: frontmatter['title'],
    date: frontmatter['date'],
    body: body
  );
}

String prefixRefs(String html) {
  final regex = RegExp(r'(src|href)="(/[^"]*)"');
  return html.replaceAllMapped(regex, (match) {
    final attribute = match.group(1);
    final originalPath = match.group(2)!;
    return '$attribute="..$originalPath"';
  });
}

// String prefixSrcReferences(String html) {
//   final srcRegex = RegExp(r'src="(/[^"]*)"');
//   return html.replaceAllMapped(srcRegex, (match) {
//     final originalPath = match.group(1);
//     return 'src="..$originalPath"';
//   });
// }

// String assembleHtmlWithFrontmatter(String markdown) {
//   final frontmatter = parseFrontmatter(markdown);
//   final body = markdown.replaceFirst(frontmatterRegex, '').trim();
//   String bodyHtml = markdownToHtml(body);
//   bodyHtml = prefixSrcReferences(bodyHtml);
//   final dateFormatter = DateFormat('MMMM d, yyyy');

//   return '''
//   <h1>
//   ${frontmatter['title']}
//   </h1>
//   <i>${dateFormatter.format(frontmatter['date'])}</i>

//   $bodyHtml
//   ''';
// }

Map<String, dynamic> parseFrontmatter(String markdown) {
  final match = frontmatterRegex.firstMatch(markdown);
  final frontmatterYaml = match?.group(1) ?? '';
  final parsedYaml = loadYaml(frontmatterYaml) as Map;

  String dateString = parsedYaml['date'].toString();
  DateTime date = DateTime.parse(dateString);

  return {
    'title': parsedYaml['title'] as String?,
    'date': date,
  };
}