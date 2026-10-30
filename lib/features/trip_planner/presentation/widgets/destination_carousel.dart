import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../domain/city.dart';

class DestinationCarousel extends StatefulWidget {
  const DestinationCarousel({
    super.key,
    required this.cities,
    required this.selected,
    required this.onSelected,
  });

  final List<City> cities;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  State<DestinationCarousel> createState() => _DestinationCarouselState();
}

class _DestinationCarouselState extends State<DestinationCarousel> {
  final _controller = PageController(viewportFraction: 0.8);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: PageView.builder(
        controller: _controller,
        itemCount: widget.cities.length,
        itemBuilder: (context, index) {
          final city = widget.cities[index];
          return _CityCard(
            city: city,
            isSelected: city.name == widget.selected,
            onTap: () => widget.onSelected(city.name),
          );
        },
      ),
    );
  }
}

class _CityCard extends StatelessWidget {
  const _CityCard({
    required this.city,
    required this.isSelected,
    required this.onTap,
  });

  final City city;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: theme.colorScheme.primary, width: 3)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _CityImage(url: city.imageUrl)),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      city.name,
                      style: theme.textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle, color: theme.colorScheme.primary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CityImage extends StatelessWidget {
  const _CityImage({required this.url});

  final String? url;

  static const _fallback = ColoredBox(
    color: Color(0x14000000),
    child: Center(child: Icon(Icons.image_not_supported_outlined, size: 40)),
  );

  @override
  Widget build(BuildContext context) {
    final url = this.url;
    if (url == null) return _fallback;
    return SvgPicture.network(
      url,
      fit: BoxFit.cover,
      placeholderBuilder: (_) =>
          const Center(child: CircularProgressIndicator()),
      errorBuilder: (_, _, _) => _fallback,
    );
  }
}
