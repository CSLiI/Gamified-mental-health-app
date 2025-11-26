import 'package:flutter/material.dart';

/// Centralized pagination widget for all list screens
/// Automatically loads more data when user scrolls to bottom
class PaginatedListView<T> extends StatefulWidget {
  final Future<List<T>> Function(int skip, int limit) fetchData;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Widget? emptyWidget;
  final Widget? errorWidget;
  final int itemsPerPage;
  final ScrollPhysics? physics;
  final EdgeInsets? padding;
  final Widget Function()? skeletonBuilder;

  const PaginatedListView({
    super.key,
    required this.fetchData,
    required this.itemBuilder,
    this.emptyWidget,
    this.errorWidget,
    this.itemsPerPage = 20,
    this.physics,
    this.padding,
    this.skeletonBuilder,
  });

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  final List<T> _items = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadMoreData();
      }
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = 0;
      _items.clear();
    });

    try {
      final newItems = await widget.fetchData(0, widget.itemsPerPage);
      setState(() {
        _items.addAll(newItems);
        _hasMore = newItems.length >= widget.itemsPerPage;
        _isLoading = false;
        _currentPage++;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreData() async {
    setState(() => _isLoading = true);

    try {
      final skip = _currentPage * widget.itemsPerPage;
      final newItems = await widget.fetchData(skip, widget.itemsPerPage);

      setState(() {
        _items.addAll(newItems);
        _hasMore = newItems.length >= widget.itemsPerPage;
        _isLoading = false;
        _currentPage++;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Don't show error for pagination failures, just stop loading
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show skeleton on initial load
    if (_isLoading && _items.isEmpty) {
      return widget.skeletonBuilder?.call() ??
          const Center(child: CircularProgressIndicator());
    }

    // Show error if initial load failed
    if (_error != null && _items.isEmpty) {
      return widget.errorWidget ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: $_error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadInitialData,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
    }

    // Show empty state
    if (_items.isEmpty) {
      return widget.emptyWidget ?? const Center(child: Text('No items found'));
    }

    // Show list with pagination
    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: ListView.builder(
        controller: _scrollController,
        physics: widget.physics ?? const AlwaysScrollableScrollPhysics(),
        padding: widget.padding,
        itemCount: _items.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            // Loading indicator at bottom
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return widget.itemBuilder(context, _items[index], index);
        },
      ),
    );
  }
}
