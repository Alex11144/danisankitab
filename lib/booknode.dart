
class BookNode {
  final int id;
  final String title;
  final String subtitle;
  final String artUri;
  final String tts;
  final bool isCategory;
  final String mp3Uri;
  final Duration duration;

  List<BookNode> children;

  BookNode.category({this.id, this.title, this.artUri, this.tts, this.children}) : isCategory = true, mp3Uri = null, subtitle = null, duration = null;
  BookNode.book({this.id, this.title, this.subtitle, this.artUri, this.tts, this.mp3Uri, this.duration}) : isCategory = false;

  factory BookNode.fromJsonCategory(Map<String, dynamic> json, String ttsPrefix) {
    List<BookNode> chs = List<BookNode>();
    for (var j = 0; j < json["items"].length; j++) {
      chs.add(BookNode.fromJsonBook(json["items"][j], ttsPrefix));
    }

    if (json["subcats"] != null) {
      for (var j = 0; j < json["subcats"].length; j++) {
        chs.add(BookNode.fromJsonCategory(json["subcats"][j], ttsPrefix));
      }
    }

    ttsSet.add(json["tts"]);
    return BookNode.category(
        id: json["id"],
        title: json["title"],
        artUri: json["thumbnail"],
        tts: ttsPrefix + json["tts"],
        children: chs
    );
  }

  factory BookNode.fromJsonBook(Map<String, dynamic> json, String ttsPrefix) {
    ttsSet.add(json["tts"]);
    return BookNode.book(
        id: json["id"],
        title: json["title"],
        subtitle: json["author"],
        artUri: json["thumbnail"],
        mp3Uri: json["data"],
        tts: ttsPrefix + json["tts"],
        duration: Duration(seconds: json["duration"])
    );
  }

  static Set<String> ttsSet = Set<String>();

}
