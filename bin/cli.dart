import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';
import 'package:markdown/markdown.dart';
import 'package:intl/intl.dart';


final frontmatterRegex = RegExp(r'^---\n(.*)\n---', multiLine: true, dotAll: true);

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
      final html = assembleHtmlWithFrontmatter(contents);

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

String prefixSrcReferences(String html) {
  final srcRegex = RegExp(r'src="(/[^"]*)"');
  return html.replaceAllMapped(srcRegex, (match) {
    final originalPath = match.group(1);
    return 'src="..$originalPath"';
  });
}

String assembleHtmlWithFrontmatter(String markdown) {
  final frontmatter = parseFrontmatter(markdown);
  final body = markdown.replaceFirst(frontmatterRegex, '').trim();
  String bodyHtml = markdownToHtml(body);
  bodyHtml = prefixSrcReferences(bodyHtml);
  final dateFormatter = DateFormat('MMMM d, yyyy');

  return '''
  <h1>
  ${frontmatter['title']}
  </h1>
  <i>${dateFormatter.format(frontmatter['date'])}</i>

  $bodyHtml
  ''';
}

Map<String, dynamic> parseFrontmatter(String markdown) {
  final match = frontmatterRegex.firstMatch(markdown);

  if (match == null) {
    return {};
  }

  final frontmatterYaml = match.group(1) ?? '';
  final parsedYaml = loadYaml(frontmatterYaml);

  String dateString = parsedYaml['date'].toString();
  DateTime date = DateTime.parse(dateString);

  return {
    'title': parsedYaml['title'] as String?,
    'date': date,
  };
}