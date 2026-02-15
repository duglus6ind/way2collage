String normalizeId(String value) {
  return value
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'\s+'), '_')
      .replaceAll(RegExp(r'[^a-z0-9_]'), '');
}
