import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../cases/application/cases_providers.dart';
import '../../../cases/domain/true_crime_case.dart';

class HomeHeader extends ConsumerStatefulWidget {
  const HomeHeader({
    super.key,
    required this.suggestions,
    required this.onCarteleraTap,
    required this.onCaseSelected,
  });

  final List<TrueCrimeCase> suggestions;
  final VoidCallback onCarteleraTap;
  final ValueChanged<TrueCrimeCase> onCaseSelected;

  @override
  ConsumerState<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends ConsumerState<HomeHeader> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleQueryChanged(String value) {
    ref.read(searchQueryProvider.notifier).state = value;
    setState(() {});
  }

  void _handleSuggestionTap(TrueCrimeCase crimeCase) {
    _controller.text = crimeCase.title;
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
    ref.read(searchQueryProvider.notifier).state = crimeCase.title;
    _focusNode.unfocus();
    widget.onCaseSelected(crimeCase);
    setState(() {});
  }

  void _clearSearch() {
    _controller.clear();
    ref.read(searchQueryProvider.notifier).state = '';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = ref.watch(searchQueryProvider);
    final showSuggestions =
        _focusNode.hasFocus && widget.suggestions.isNotEmpty;

    if (_controller.text != query) {
      _controller.value = TextEditingValue(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
      );
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.background.withValues(alpha: 0.95),
              AppColors.background.withValues(alpha: 0.84),
              AppColors.background.withValues(alpha: 0),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1320),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 900;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isCompact)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _BrandBlock(theme: theme),
                              const SizedBox(height: 16),
                              _SearchBlock(
                                controller: _controller,
                                focusNode: _focusNode,
                                query: query,
                                showSuggestions: showSuggestions,
                                suggestions: widget.suggestions,
                                onChanged: _handleQueryChanged,
                                onClear: _clearSearch,
                                onSuggestionTap: _handleSuggestionTap,
                              ),
                              const SizedBox(height: 14),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: FilledButton.tonalIcon(
                                  onPressed: widget.onCarteleraTap,
                                  icon: const Icon(Icons.view_carousel_rounded),
                                  label: const Text('Cartelera'),
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Flexible(
                                flex: 3,
                                child: _BrandBlock(theme: theme),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                flex: 5,
                                child: _SearchBlock(
                                  controller: _controller,
                                  focusNode: _focusNode,
                                  query: query,
                                  showSuggestions: showSuggestions,
                                  suggestions: widget.suggestions,
                                  onChanged: _handleQueryChanged,
                                  onClear: _clearSearch,
                                  onSuggestionTap: _handleSuggestionTap,
                                ),
                              ),
                              const SizedBox(width: 24),
                              FilledButton.tonalIcon(
                                onPressed: widget.onCarteleraTap,
                                icon: const Icon(Icons.view_carousel_rounded),
                                label: const Text('Cartelera'),
                              ),
                            ],
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandBlock extends StatelessWidget {
  const _BrandBlock({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TRUE APP',
          style: theme.textTheme.labelLarge?.copyWith(
            color: AppColors.gold,
            letterSpacing: 2.6,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Mapa editorial del true crime',
          style: theme.textTheme.titleLarge?.copyWith(
            fontFamily: 'NotoSerifDisplay',
          ),
        ),
      ],
    );
  }
}

class _SearchBlock extends StatelessWidget {
  const _SearchBlock({
    required this.controller,
    required this.focusNode,
    required this.query,
    required this.showSuggestions,
    required this.suggestions,
    required this.onChanged,
    required this.onClear,
    required this.onSuggestionTap,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String query;
  final bool showSuggestions;
  final List<TrueCrimeCase> suggestions;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final ValueChanged<TrueCrimeCase> onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          key: const Key('case-search-field'),
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded),
            hintText: 'Busca casos, países o tags',
            suffixIcon: query.isNotEmpty
                ? IconButton(
                    onPressed: onClear,
                    icon: const Icon(Icons.close_rounded),
                  )
                : null,
          ),
        ),
        if (showSuggestions)
          Container(
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF12151B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 26,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: suggestions.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final crimeCase = suggestions[index];
                return ListTile(
                  dense: true,
                  onTap: () => onSuggestionTap(crimeCase),
                  title: Text(crimeCase.title),
                  subtitle: Text(
                    '${crimeCase.regionOrCity}, ${crimeCase.country}',
                  ),
                  trailing: Text('${crimeCase.year}'),
                );
              },
            ),
          ),
      ],
    );
  }
}
