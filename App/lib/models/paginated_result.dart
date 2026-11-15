class PaginatedResult<T> {
  const PaginatedResult({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
    required this.hasMore,
  });

  final List<T> items;
  final int total;
  final int limit;
  final int offset;
  final bool hasMore;
}
