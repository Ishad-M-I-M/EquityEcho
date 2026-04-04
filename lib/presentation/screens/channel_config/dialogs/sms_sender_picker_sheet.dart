import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:equity_echo/core/theme/app_theme.dart';
import 'package:equity_echo/core/services/sms_service.dart';

/// Modal bottom sheet that lists all distinct SMS senders from the device inbox.
/// Includes a real-time search bar. Selecting a row calls [onSelected].
class SmsSenderPickerSheet extends StatefulWidget {
  final ValueChanged<String> onSelected;

  const SmsSenderPickerSheet({super.key, required this.onSelected});

  @override
  State<SmsSenderPickerSheet> createState() => _SmsSenderPickerSheetState();
}

class _SmsSenderPickerSheetState extends State<SmsSenderPickerSheet> {
  final _searchController = TextEditingController();
  List<String> _allSenders = [];
  List<String> _filteredSenders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSenders();
    _searchController.addListener(_filterSenders);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSenders() async {
    try {
      final smsService = GetIt.instance<SmsService>();
      final senders = await smsService.getDistinctSenders();
      if (mounted) {
        setState(() {
          _allSenders = senders;
          _filteredSenders = senders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load SMS senders: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _filterSenders() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredSenders = query.isEmpty
          ? _allSenders
          : _allSenders
              .where((s) => s.toLowerCase().contains(query))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.65;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Drag handle ──
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),

            // ── Title ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.sms, size: 20, color: AppTheme.accent),
                  const SizedBox(width: 8),
                  Text(
                    'Select SMS Sender',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Search bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search senders...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: _searchController.clear,
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ── Content ──
            Flexible(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Reading SMS inbox...'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: AppTheme.sellRed, size: 36),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.sellRed),
              ),
            ],
          ),
        ),
      );
    }

    if (_allSenders.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox, size: 36, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'No SMS messages found on this device.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredSenders.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'No senders match "${_searchController.text}"',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: _filteredSenders.length,
      separatorBuilder: (context, _) => Divider(
        height: 1,
        indent: 16,
        endIndent: 16,
        color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
      ),
      itemBuilder: (context, index) {
        final sender = _filteredSenders[index];
        final isNumeric = RegExp(r'^[\d+\-\s]+$').hasMatch(sender);

        return ListTile(
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.accent.withValues(alpha: 0.1),
            child: Icon(
              isNumeric ? Icons.phone : Icons.business,
              size: 18,
              color: AppTheme.accent,
            ),
          ),
          title: Text(
            sender,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          onTap: () => widget.onSelected(sender),
          dense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        );
      },
    );
  }
}
