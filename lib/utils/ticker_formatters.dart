({double longPct, double shortPct}) fundingSentiment(double funding8hPct) {
  const scalePerPercent = 50.0;
  final longPct = (50 + funding8hPct * scalePerPercent).clamp(0.0, 100.0);
  return (longPct: longPct, shortPct: 100.0 - longPct);
}

String fmtUsd(double v) {
  if (v >= 1e9) return '\$${(v / 1e9).toStringAsFixed(2)}B';
  if (v >= 1e6) return '\$${(v / 1e6).toStringAsFixed(2)}M';
  if (v >= 1e3) return '\$${(v / 1e3).toStringAsFixed(2)}K';
  return '\$${v.toStringAsFixed(2)}';
}

String fmtNum(double v) {
  if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(2)}B';
  if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(2)}M';
  if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(2)}K';
  return v.toStringAsFixed(4);
}

String fmtPx(double v) {
  if (v <= 0) return '—';
  if (v >= 1000) return '\$${v.toStringAsFixed(2)}';
  if (v >= 1) return '\$${v.toStringAsFixed(4)}';
  return '\$${v.toStringAsFixed(6)}';
}
