import 'dart:convert';

import 'package:crypto/crypto.dart';

String sha256Hex(String plainText) {
  return sha256.convert(utf8.encode(plainText)).toString();
}

bool looksLikeSha256Hex(String value) {
  final candidate = value.trim();
  if (candidate.length != 64) return false;
  final hexRegExp = RegExp(r'^[0-9a-fA-F]{64}$');
  return hexRegExp.hasMatch(candidate);
}
