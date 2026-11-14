/// Up to two capital letters for an avatar, as in the Figma Profile frame
/// ("Osanda" -> "OS", "Tharindu Dhanushka" -> "TD").
///
/// Uses the first letters of the first two words of [fullName]. A single word
/// gives its first two letters. Without a name it falls back to the first
/// letter of [email], and finally to "A" for AquaGrow.
String initialsFor({String? fullName, String? email}) {
  final words = (fullName ?? '')
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();

  if (words.length >= 2) {
    return (words[0][0] + words[1][0]).toUpperCase();
  }
  if (words.length == 1) {
    final word = words.first;
    return word.substring(0, word.length < 2 ? word.length : 2).toUpperCase();
  }

  final mail = (email ?? '').trim();
  if (mail.isNotEmpty) return mail[0].toUpperCase();
  return 'A';
}
