import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

/// A text field that suggests cities and reports the city its text matches, or
/// null while the text matches none.
class CityAutocompleteField extends StatefulWidget {
  const CityAutocompleteField({
    super.key,
    required this.label,
    required this.icon,
    required this.cityNames,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final List<String> cityNames;
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  State<CityAutocompleteField> createState() => _CityAutocompleteFieldState();
}

class _CityAutocompleteFieldState extends State<CityAutocompleteField> {
  late final _controller = TextEditingController(text: widget.selected);
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(CityAutocompleteField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A selection made elsewhere, by the carousel, has to show up in the field.
    final selected = widget.selected;
    if (selected != null && !_matches(selected, _controller.text)) {
      // The controller notifies listeners, which is not allowed during build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.text = selected;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    widget.onChanged(
      widget.cityNames.firstWhereOrNull((c) => _matches(c, _controller.text)),
    );
  }

  bool _matches(String city, String text) =>
      city.toLowerCase() == text.trim().toLowerCase();

  Iterable<String> _suggestions(TextEditingValue value) {
    final query = value.text.trim().toLowerCase();
    return widget.cityNames.where((c) => c.toLowerCase().contains(query));
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: _controller,
      focusNode: _focusNode,
      optionsBuilder: _suggestions,
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          onSubmitted: (_) => onSubmitted(),
          decoration: InputDecoration(
            labelText: widget.label,
            prefixIcon: Icon(widget.icon),
            border: const OutlineInputBorder(),
            suffixIcon: ListenableBuilder(
              listenable: controller,
              builder: (context, _) => controller.text.isEmpty
                  ? const SizedBox.shrink()
                  : IconButton(
                      tooltip: 'Clear ${widget.label.toLowerCase()}',
                      icon: const Icon(Icons.clear),
                      onPressed: controller.clear,
                    ),
            ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240, maxWidth: 400),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: [
                  for (final option in options)
                    ListTile(
                      title: Text(option),
                      onTap: () => onSelected(option),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
