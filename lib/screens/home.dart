import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/weather_service.dart';
import '../services/user_service.dart';
import '../ui/components/reusable_card.dart';
import '../ui/components/weather_chip.dart';
import '../ui/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<WeatherData> _weatherFuture;
  final WeatherService _weatherService = WeatherService();
  final UserService _userService = UserService();

  String _locationLabel = 'Addis Ababa';
  double? _customLat;
  double? _customLong;
  bool _isManualLocation = false;
  bool _isProfileLocationLoaded = false;

  @override
  void initState() {
    super.initState();
    print("HomeScreen: initState called");
    _weatherFuture = _weatherService.fetchWeather();
    _initLocationStrategy();
  }

  Future<void> _initLocationStrategy() async {
    final user = FirebaseAuth.instance.currentUser;
    bool firebaseLocationFound = false;

    if (user != null) {
      try {
        final profile = await _userService.getUser(user.uid);
        if (profile != null &&
            profile.farmLocation.isNotEmpty &&
            profile.farmLocation != 'Unknown') {
          print("HomeScreen: Finding location for ${profile.farmLocation}");
          final coords = await _weatherService
              .getCoordinatesFromCityName(profile.farmLocation);

          if (coords != null && mounted) {
            setState(() {
              _locationLabel = profile.farmLocation;
              _customLat = coords['latitude'];
              _customLong = coords['longitude'];
              _isManualLocation = true;
              _isProfileLocationLoaded = true;
              _weatherFuture = _weatherService.fetchWeather(
                lat: _customLat,
                long: _customLong,
              );
            });
            firebaseLocationFound = true;
          }
        }
      } catch (e) {
        debugPrint("Error loading profile location: $e");
      }
    }

    if (!firebaseLocationFound) {
      _loadCurrentLocation();
    }
  }

  Future<void> _loadCurrentLocation() async {
    try {
      print("HomeScreen: Loading current GPS location");
      final pos = await _weatherService.getCurrentLocation();
      if (_isManualLocation || _isProfileLocationLoaded) return;

      if (pos != null && mounted) {
        String? cityName = await _weatherService.getCityNameFromCoordinates(
            pos.latitude, pos.longitude);
        if (_isManualLocation) return;

        setState(() {
          _locationLabel = cityName ?? "My Location";
          _customLat = pos.latitude;
          _customLong = pos.longitude;
          _weatherFuture = _weatherService.fetchWeather(
            lat: pos.latitude,
            long: pos.longitude,
          );
        });
      } else {
        print("HomeScreen: GPS location null or denied");
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

  void _selectCity(City city) {
    setState(() {
      _isManualLocation = true;
      _locationLabel = city.name;
      _customLat = city.latitude;
      _customLong = city.longitude;
      _weatherFuture = _weatherService.fetchWeather(
        lat: city.latitude,
        long: city.longitude,
      );
    });
    Navigator.of(context).pop();
  }

  void _showCitySearchDialog() {
    showDialog(
      context: context,
      builder: (context) => _CitySearchDialog(onCitySelected: _selectCity),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Debug print to check if build is running
    print("HomeScreen: build running");

    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      // backgroundColor removed: uses theme default
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Section (Simplified container)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                  left: 20, right: 20, top: 50, bottom: 30),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryGreen, AppTheme.lightGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Icon + Search
                  Row(
                    children: [
                      Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child:
                            const Icon(Icons.agriculture, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('FarmWise',
                                style: textTheme.titleMedium
                                    ?.copyWith(color: Colors.white)),
                            Text('Plan. Grow. Thrive.',
                                style: textTheme.bodySmall
                                    ?.copyWith(color: Colors.white70)),
                          ],
                        ),
                      ),
                      // Location Button
                      InkWell(
                        onTap: _showCitySearchDialog,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on,
                                  color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  _locationLabel,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down,
                                  color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Text('Welcome to FarmWise',
                      style: textTheme.headlineSmall
                          ?.copyWith(color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(
                    'Smart agriculture planning with live weather and market insights.',
                    style: textTheme.bodyMedium
                        ?.copyWith(color: Colors.white.withOpacity(0.9)),
                  ),
                ],
              ),
            ),

            // 2. Main Content (Weather and Actions)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Weather Card
                  ReusableCard(
                    padding: const EdgeInsets.all(20),
                    child: FutureBuilder<WeatherData>(
                      future: _weatherFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return _WeatherCardSkeleton(textTheme: textTheme);
                        }
                        if (snapshot.hasError) {
                          return _WeatherCardFallback(textTheme: textTheme);
                        }
                        if (!snapshot.hasData) {
                          return _WeatherCardFallback(textTheme: textTheme);
                        }

                        final weather = snapshot.data!;
                        final df = DateFormat('EEE');
                        final daily = weather.daily;

                        return _WeatherCardContent(
                          textTheme: textTheme,
                          temperature: weather.temperatureC,
                          condition: weather.weatherCodeLabel ?? 'Weather',
                          windSpeed: weather.windSpeed,
                          updatedAt: weather.updatedAt,
                          upcoming: daily.take(5).map((d) {
                            return _ForecastItem(
                              label:
                                  '${df.format(d.date)} ${d.tempMaxC.toStringAsFixed(0)}\u00B0/${d.tempMinC.toStringAsFixed(0)}\u00B0',
                              isRainy: (d.precipitationProb ?? 0) > 50,
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Weather Insights
                  FutureBuilder<WeatherData>(
                    future: _weatherFuture,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();
                      return Column(
                        children: [
                          ReusableCard(
                            padding: const EdgeInsets.all(16),
                            child:
                                _WeatherInsightsCard(weather: snapshot.data!),
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),

                  // Quick Actions
                  ReusableCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Quick Actions',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: const [
                            _QuickAction(
                                label: 'Crop Advice', icon: Icons.agriculture),
                            _QuickAction(
                                label: 'My Farm', icon: Icons.event_note),
                            _QuickAction(
                                label: 'Market Prices', icon: Icons.store),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CitySearchDialog extends StatefulWidget {
  final Function(City) onCitySelected;
  const _CitySearchDialog({required this.onCitySelected});

  @override
  State<_CitySearchDialog> createState() => _CitySearchDialogState();
}

class _CitySearchDialogState extends State<_CitySearchDialog> {
  final _searchController = TextEditingController();
  final _weatherService = WeatherService();
  List<City> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  void _search() async {
    if (_searchController.text.length < 2) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final cities = await _weatherService.searchCities(_searchController.text);
      if (mounted) setState(() => _results = cities);
    } catch (e) {
      debugPrint("Search error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Change Location',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Enter city name (e.g. Adama)',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _search,
                ),
              ),
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _results.isEmpty
                      ? Center(
                          child: Text(_hasSearched
                              ? 'No cities found. Try another name.'
                              : 'Enter a city name to search'),
                        )
                      : ListView.separated(
                          itemCount: _results.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final city = _results[index];
                            final parts = [city.admin1, city.country]
                                .where((s) => s != null && s.isNotEmpty)
                                .cast<String>()
                                .toList();
                            final subtitle = parts.join(', ');

                            return ListTile(
                              leading: const Icon(Icons.location_city,
                                  color: AppTheme.primaryGreen),
                              title: Text(city.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              subtitle:
                                  subtitle.isNotEmpty ? Text(subtitle) : null,
                              onTap: () => widget.onCitySelected(city),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeatherCardSkeleton extends StatelessWidget {
  final TextTheme textTheme;
  const _WeatherCardSkeleton({required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Today's Weather", style: textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: const [
            CircularProgressIndicator(),
            SizedBox(width: 12),
            Text('Loading weather...'),
          ],
        ),
        const SizedBox(height: 16),
        Text('Upcoming', style: textTheme.titleMedium),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            WeatherChip(label: '---', icon: Icons.wb_sunny),
            WeatherChip(label: '---', icon: Icons.cloud),
            WeatherChip(label: '---', icon: Icons.wb_cloudy),
          ],
        ),
      ],
    );
  }
}

class _WeatherCardFallback extends StatelessWidget {
  final TextTheme textTheme;
  const _WeatherCardFallback({required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Today's Weather", style: textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: const [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Expanded(child: Text('Weather unavailable')),
          ],
        ),
        const SizedBox(height: 16),
        Text('Upcoming', style: textTheme.titleMedium),
        const SizedBox(height: 10),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            WeatherChip(label: 'Tue 26\u00B0/22\u00B0', icon: Icons.wb_sunny),
            WeatherChip(label: 'Wed 25\u00B0/21\u00B0', icon: Icons.cloud),
            WeatherChip(label: 'Thu 27\u00B0/23\u00B0', icon: Icons.wb_cloudy),
          ],
        ),
      ],
    );
  }
}

class _ForecastItem {
  final String label;
  final bool isRainy;
  const _ForecastItem({required this.label, required this.isRainy});
}

class _WeatherCardContent extends StatelessWidget {
  final TextTheme textTheme;
  final double temperature;
  final String condition;
  final double? windSpeed;
  final List<_ForecastItem> upcoming;
  final DateTime updatedAt;

  const _WeatherCardContent({
    required this.textTheme,
    required this.temperature,
    required this.condition,
    required this.windSpeed,
    required this.upcoming,
    required this.updatedAt,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Today's Weather", style: textTheme.titleMedium),
            Text(
              'Updated ${DateFormat('HH:mm').format(updatedAt)}',
              style: textTheme.bodySmall?.copyWith(color: AppTheme.darkGray),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.wb_sunny, size: 44, color: AppTheme.accentYellow),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${temperature.toStringAsFixed(0)}\u00B0C',
                    style: textTheme.headlineMedium),
                Text(
                  condition,
                  style:
                      textTheme.bodyMedium?.copyWith(color: AppTheme.darkGray),
                ),
              ],
            ),
            const Spacer(),
            WeatherChip(
                label: windSpeed != null
                    ? 'Wind ${windSpeed!.toStringAsFixed(0)} km/h'
                    : 'Wind --',
                icon: Icons.air),
          ],
        ),
        const SizedBox(height: 16),
        Text('Upcoming', style: textTheme.titleMedium),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: upcoming.isNotEmpty
                ? upcoming
                    .map((f) => Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: WeatherChip(
                            label: f.label,
                            icon: f.isRainy ? Icons.umbrella : Icons.wb_sunny,
                          ),
                        ))
                    .toList()
                : const [
                    Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: WeatherChip(
                            label: 'Tue 26\u00B0/22\u00B0',
                            icon: Icons.wb_sunny)),
                    Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: WeatherChip(
                            label: 'Wed 25\u00B0/21\u00B0', icon: Icons.cloud)),
                    Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: WeatherChip(
                            label: 'Thu 27\u00B0/23\u00B0',
                            icon: Icons.wb_cloudy)),
                  ],
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;

  const _QuickAction({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.primaryGreen, size: 28),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _WeatherInsightsCard extends StatelessWidget {
  final WeatherData weather;

  const _WeatherInsightsCard({required this.weather});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final label = weather.weatherCodeLabel ?? 'Clear';
    final temp = weather.temperatureC;
    final isRainy = label.contains('Rain') ||
        label.contains('Drizzle') ||
        label.contains('Showers') ||
        label.contains('Thunderstorm') ||
        (weather.daily.isNotEmpty &&
            (weather.daily[0].precipitationProb ?? 0) > 50);
    final isHot = temp > 28;
    final isCold = temp < 10;
    final isWindy = (weather.windSpeed ?? 0) > 20;

    String title = "Farm Insight";
    List<String> insights = [
      "Conditions are mild. Great day for scouting pests and diseases.",
      "Ideal time for weeding and general soil maintenance."
    ];
    IconData icon = Icons.spa;
    Color color = isDark ? AppTheme.lightGreen : AppTheme.primaryGreen;

    if (isRainy) {
      title = "Rain Excepted";
      insights = [
        "Avoid applying fertilizers; they may wash away.",
        "Ensure drainage channels are clear to prevent waterlogging.",
        "Good opportunity for transplanting seedlings."
      ];
      icon = Icons.water_drop;
      color = isDark ? Colors.blueAccent : Colors.blue.shade700;
    } else if (isHot) {
      title = "High Heat Advisory";
      insights = [
        "Water crops early morning or late evening to reduce evaporation.",
        "Provide shade for young seedlings and livestock.",
        "Monitor for signs of heat stress in plants."
      ];
      icon = Icons.wb_sunny;
      color = isDark ? Colors.orangeAccent : Colors.orange.shade800;
    } else if (isCold) {
      title = "Cold Warning";
      insights = [
        "Risk of frost. Cover sensitive crops with mulch or cloth.",
        "Reduce watering frequency to avoid freezing field water.",
        "Provide warm bedding for animals."
      ];
      icon = Icons.ac_unit;
      color = isDark ? Colors.cyanAccent : Colors.cyan.shade700;
    } else if (isWindy) {
      title = "High Wind Alert";
      insights = [
        "Secure tall crops like maize and banana plants.",
        "Delay spraying pesticides to avoid chemical drift.",
        "Inspect greenhouses and covers for loose sections."
      ];
      icon = Icons.air;
      color = isDark ? Colors.grey.shade400 : Colors.blueGrey;
    }

    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.1 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: color, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...insights.map((insight) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Icon(Icons.circle,
                          size: 6, color: color.withOpacity(0.7)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        insight,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.4,
                              // Color is automatic (white in dark mode)
                            ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
