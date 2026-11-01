String normalizeQr(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

bool qrMatches(String scanned, String expected) =>
    normalizeQr(scanned) == normalizeQr(expected);
