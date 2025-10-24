import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'indian_cities.dart';

// --- Entry Point of the App ---
void main() {
  runApp(const WeatherApp());
}

// --- App Root Widget ---
class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Weather App',
      // Removes the debug banner in the top right corner
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // The primary color swatch for the app
        primarySwatch: Colors.deepPurple,
        // Use Material Design 3 for a modern look
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const WeatherScreen(),
    );
  }
}

// --- Weather Screen Widget (Stateful) ---
class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  // --- State Variables ---

  // OpenWeatherMap API key
  final String _apiKey = '9039826d0f4573afb343cf8ef18e24e6';

  // Controller to get text from the search field
  final TextEditingController _cityController = TextEditingController();

  // The city currently being displayed
  String _cityName = 'Delhi';

  // Weather data fetched from the API
  Map<String, dynamic>? _weatherData;
  List<dynamic>? _forecastData;

  // Tracks the loading state for fetching data
  bool _isLoading = false;

  // Stores any error messages
  String? _errorMessage;

  final List<String> _allIndianCities = indianCities;

  // Filtered list of city suggestions based on search
  List<String> _citySuggestions = [];

  // Show suggestions flag
  bool _showSuggestions = false;

  // Maximum number of suggestions to show
  final int _maxSuggestions = 15;

  // --- Lifecycle Methods ---

  @override
  void initState() {
    super.initState();
    // Fetch initial weather data for the default city when the widget is first created
    _fetchWeather();
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is removed from the widget tree
    _cityController.dispose();
    super.dispose();
  }

  // --- Core Logic ---

  /// Filters city suggestions based on user input from local list
  void _filterCitySuggestions(String query) {
    if (query.length < 2) {
      setState(() {
        _citySuggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    // Filter cities that contain the query (case insensitive)
    final filteredCities = _allIndianCities
        .where((city) => city.toLowerCase().contains(query.toLowerCase()))
        .take(_maxSuggestions)
        .toList();

    setState(() {
      _citySuggestions = filteredCities;
      _showSuggestions = filteredCities.isNotEmpty;
    });
  }

  /// Fetches weather data from the OpenWeatherMap API for the current [_cityName].
  Future<void> _fetchWeather() async {
    // Don't fetch if an API key is not provided
    if (_apiKey == 'YOUR_API_KEY') {
      setState(() {
        _errorMessage = 'Please add your OpenWeatherMap API key to the code.';
        _isLoading = false;
      });
      return;
    }

    // Set loading state and clear previous errors/data
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _weatherData = null;
      _forecastData = null;
    });

    try {
      // Construct the API URL
      final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?q=$_cityName&appid=$_apiKey&units=metric',
      );

      // Make the HTTP GET request
      final response = await http.get(url);
      final forecastUrl = Uri.parse(
        'https://api.openweathermap.org/data/2.5/forecast?q=$_cityName&appid=$_apiKey&units=metric',
      );
      final forecastResponse = await http.get(forecastUrl);

      // Check if the request was successful
      if (response.statusCode == 200 && forecastResponse.statusCode == 200) {
        // Parse the JSON response and update the state
        setState(() {
          _weatherData = json.decode(response.body);
          _forecastData = json.decode(forecastResponse.body)['list'];
        });
      } else {
        // If the server returns an error, set an error message
        setState(() {
          _errorMessage = 'City not found. Please try again.';
        });
      }
    } catch (e) {
      // Catch any exceptions during the API call (e.g., network issues)
      setState(() {
        _errorMessage = 'Failed to load weather data. Check your connection.';
      });
    } finally {
      // Always set loading to false when the process is complete
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Returns a weather icon based on the weather condition code.
  IconData _getWeatherIcon(String? mainCondition) {
    switch (mainCondition?.toLowerCase()) {
      case 'clouds':
        return Icons.wb_cloudy;
      case 'rain':
        return Icons.grain;
      case 'drizzle':
        return Icons.shower;
      case 'thunderstorm':
        return Icons.flash_on;
      case 'snow':
        return Icons.ac_unit;
      case 'clear':
        return Icons.wb_sunny;
      case 'atmosphere':
      case 'mist':
      case 'fog':
        return Icons.blur_on;
      default:
        return Icons.wb_sunny; // Default icon
    }
  }

  // --- UI Build Method ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather App'),
        centerTitle: true,
        elevation: 4, // Adds a subtle shadow below the app bar
      ),
      body: GestureDetector(
        onTap: () {
          // Dismiss suggestions when tapping outside
          setState(() {
            _showSuggestions = false;
          });
        },
        child: Container(
          // A gentle gradient background
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.deepPurple.shade300, Colors.deepPurple.shade600],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // --- Search Bar and Button ---
                _buildSearchCard(),
                const SizedBox(height: 20),
                // --- Weather Information Display ---
                Expanded(child: _buildWeatherDisplay())
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.5, end: 0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the search input card.
  Widget _buildSearchCard() {
    return Column(
      children: [
        Card(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cityController,
                    decoration: InputDecoration(
                      labelText: 'Enter City Name',
                      border: InputBorder.none, // Clean look
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _cityController.clear();
                          setState(() {
                            _citySuggestions = [];
                            _showSuggestions = false;
                          });
                        },
                      ),
                    ),
                    // Handle search submission from keyboard
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        setState(() {
                          _cityName = value;
                          _citySuggestions = [];
                          _showSuggestions = false;
                        });
                        _fetchWeather();
                      }
                    },
                    // Fetch suggestions as user types
                    onChanged: (value) {
                      _filterCitySuggestions(value);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.deepPurple),
                  onPressed: () {
                    if (_cityController.text.isNotEmpty) {
                      setState(() {
                        _cityName = _cityController.text;
                        _citySuggestions = [];
                        _showSuggestions = false;
                      });
                      _fetchWeather();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        // City suggestions list
        if (_showSuggestions && _citySuggestions.isNotEmpty)
          _buildSuggestionsList(),
      ],
    );
  }

  /// Builds the suggestions list widget
  Widget _buildSuggestionsList() {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(top: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _citySuggestions.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.location_city, color: Colors.deepPurple),
            title: Text(
              _citySuggestions[index],
              style: const TextStyle(color: Colors.deepPurple),
            ),
            onTap: () {
              setState(() {
                _cityController.text = _citySuggestions[index];
                _cityName = _citySuggestions[index];
                _citySuggestions = [];
                _showSuggestions = false;
              });
              _fetchWeather();
            },
          );
        },
      ),
    );
  }

  /// Builds the main content area based on the current state.
  Widget _buildWeatherDisplay() {
    if (_isLoading) {
      // Show a loading indicator while fetching data
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    } else if (_errorMessage != null) {
      // Show an error message if something went wrong
      return Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          textAlign: TextAlign.center,
        ),
      );
    } else if (_weatherData != null) {
      // Display the weather data if available
      final mainWeather = _weatherData!['weather'][0]['main'];
      final description = _weatherData!['weather'][0]['description'];
      final temp = _weatherData!['main']['temp'].toStringAsFixed(1);
      final feelsLike = _weatherData!['main']['feels_like'].toStringAsFixed(1);
      final humidity = _weatherData!['main']['humidity'];
      final windSpeed = _weatherData!['wind']['speed'];
      final sunrise = DateFormat('h:mm a').format(
        DateTime.fromMillisecondsSinceEpoch(
          _weatherData!['sys']['sunrise'] * 1000,
        ),
      );
      final sunset = DateFormat('h:mm a').format(
        DateTime.fromMillisecondsSinceEpoch(
          _weatherData!['sys']['sunset'] * 1000,
        ),
      );

      return SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _weatherData!['name'],
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Icon(_getWeatherIcon(mainWeather), size: 100, color: Colors.white),
            const SizedBox(height: 10),
            Text(
              '$temp°C',
              style: const TextStyle(
                fontSize: 60,
                fontWeight: FontWeight.w200,
                color: Colors.white,
              ),
            ),
            Text(
              description[0].toUpperCase() + description.substring(1),
              style: const TextStyle(
                fontSize: 20,
                fontStyle: FontStyle.italic,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 30),
            // --- Sunrise and Sunset Times ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildWeatherDetailColumn(
                  'SUNRISE',
                  sunrise,
                  Icons.wb_sunny_outlined,
                ),
                _buildWeatherDetailColumn('SUNSET', sunset, Icons.wb_sunny),
              ],
            ),
            const SizedBox(height: 20),
            // --- Additional Details Section ---
            ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Card(
                      // ignore: deprecated_member_use
                      color: Colors.white.withOpacity(0.2),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildWeatherDetailColumn(
                              'FEELS LIKE',
                              '$feelsLike°C',
                              Icons.thermostat,
                            ),
                            _buildWeatherDetailColumn(
                              'HUMIDITY',
                              '$humidity%',
                              Icons.water_drop,
                            ),
                            _buildWeatherDetailColumn(
                              'WIND',
                              '$windSpeed m/s',
                              Icons.air,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .animate()
                .fadeIn(duration: 600.ms)
                .move(
                  begin: const Offset(0, 50),
                  end: Offset.zero,
                  curve: Curves.easeOut,
                )
                .shimmer(
                  delay: 800.ms,
                  duration: 1000.ms,
                  // ignore: deprecated_member_use
                  color: Colors.white.withOpacity(0.1),
                ),
            const SizedBox(height: 20),
            // --- 5-Day Forecast ---
            _buildForecast(),
          ],
        ),
      );
    } else {
      // Default view when no data is loaded yet (shouldn't be visible for long)
      return const Center(
        child: Text(
          'Enter a city to get started',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      );
    }
  }

  /// Helper widget for displaying individual weather details.
  Widget _buildWeatherDetailColumn(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(title, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }

  /// Builds the 5-day forecast section.
  Widget _buildForecast() {
    if (_forecastData == null) {
      return const SizedBox.shrink();
    }

    // Group forecast by day
    final Map<String, List<dynamic>> dailyForecast = {};
    for (var forecast in _forecastData!) {
      final day = DateFormat(
        'EEEE',
      ).format(DateTime.fromMillisecondsSinceEpoch(forecast['dt'] * 1000));
      if (!dailyForecast.containsKey(day)) {
        dailyForecast[day] = [];
      }
      dailyForecast[day]!.add(forecast);
    }

    // Get the next 5 days
    final next5Days = dailyForecast.keys.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '5-Day Forecast',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: next5Days.map((day) {
              final dayForecast = dailyForecast[day]!.first;
              final temp = dayForecast['main']['temp'].toStringAsFixed(1);
              final mainCondition = dayForecast['weather'][0]['main'];

              return Card(
                // ignore: deprecated_member_use
                color: Colors.white.withOpacity(0.2),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Text(
                        day,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Icon(
                        _getWeatherIcon(mainCondition),
                        color: Colors.white,
                        size: 30,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$temp°C',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 800.ms);
            }).toList(),
          ),
        ),
      ],
    );
  }
}
