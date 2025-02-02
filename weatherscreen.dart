import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class WeatherHomePage extends StatefulWidget {
  @override
  _WeatherHomePageState createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  final TextEditingController _cityController = TextEditingController();
  bool isLoading = false;
  String? cityName;
  String? temperature;
  String? weatherCondition;
  String? weatherIcon;
  List<Map<String, dynamic>> forecast = [];
  String? error;
  List<String> citySuggestions = [];
  bool isFetchingSuggestions = false;

  @override
  void initState() {
    super.initState();
    _fetchWeatherForCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Weather App',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
        elevation: 8,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.lightBlue.shade100, Colors.blue.shade400],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) async {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<String>.empty();
                    }
                    await _fetchCitySuggestions(textEditingValue.text);
                    return citySuggestions;
                  },
                  onSelected: (String selectedCity) {
                    _cityController.text = selectedCity;
                  },
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: 'Enter City Name',
                        labelStyle: TextStyle(color: Colors.blue.shade800),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    );
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _fetchWeather,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Get Weather',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
                if (isLoading) Center(child: CircularProgressIndicator()),
                if (error != null)
                  Center(
                    child: Text(
                      error!,
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (cityName != null && !isLoading && error == null)
                  Column(
                    children: [
                      Card(
                        elevation: 8.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        margin: EdgeInsets.all(8),
                        color: Colors.white.withOpacity(0.9),
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text(
                                cityName!,
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                              SizedBox(height: 12),
                              Text(
                                temperature!,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                weatherCondition!,
                                style: TextStyle(fontSize: 20, color: Colors.grey.shade800),
                              ),
                              SizedBox(height: 12),
                              if (weatherIcon != null)
                                Image.network(
                                  weatherIcon!,
                                  width: 100,
                                  height: 100,
                                ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        '5-Day Forecast',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      ...forecast.map((day) => Card(
                        elevation: 6,
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: Image.network(
                            day['icon'],
                            width: 50,
                            height: 50,
                          ),
                          title: Text(
                            day['date'],
                            style: TextStyle(
                                fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                          ),
                          subtitle: Text(day['condition']),
                          trailing: Text(
                            '${day['temp']}°C',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      )),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _fetchWeather() async {
    final city = _cityController.text;
    if (city.isEmpty) {
      setState(() {
        error = "Please enter a city name!";
      });
      return;
    }
    await _fetchWeatherData(city);
  }

  Future<void> _fetchWeatherForCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      final url =
          'https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&units=metric&appid=a27607774edc2888034cfd0fb18100ae';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final city = data['name'];
        _fetchWeatherData(city);
      } else {
        throw Exception('Error fetching current location weather.');
      }
    } catch (e) {
      setState(() {
        error = 'Error detecting current location: ${e.toString()}';
      });
    }
  }

  Future<void> _fetchWeatherData(String city) async {
    setState(() {
      isLoading = true;
      error = null;
      cityName = null;
      temperature = null;
      weatherCondition = null;
      weatherIcon = null;
      forecast.clear();
    });

    try {
      final currentWeatherUrl =
          'https://api.openweathermap.org/data/2.5/weather?q=$city&units=metric&appid=a27607774edc2888034cfd0fb18100ae';
      final forecastUrl =
          'https://api.openweathermap.org/data/2.5/forecast?q=$city&units=metric&appid=a27607774edc2888034cfd0fb18100ae';

      final currentWeatherResponse = await http.get(Uri.parse(currentWeatherUrl));
      final forecastResponse = await http.get(Uri.parse(forecastUrl));

      if (currentWeatherResponse.statusCode == 200 &&
          forecastResponse.statusCode == 200) {
        final currentData = json.decode(currentWeatherResponse.body);
        final forecastData = json.decode(forecastResponse.body);

        setState(() {
          cityName = currentData['name'] ?? 'Unknown City';
          temperature = '${(currentData['main']['temp'] ?? 0).toString()}°C';
          weatherCondition =
              (currentData['weather']?[0]?['description'] ?? 'No description')
                  .toString();
          weatherIcon =
          'https://openweathermap.org/img/wn/${currentData['weather']?[0]?['icon'] ?? '01d'}@2x.png';

          forecast = (forecastData['list'] as List<dynamic>?)
              ?.where((item) => item['dt_txt']?.contains('12:00:00') ?? false)
              .take(5)
              .map<Map<String, dynamic>>((item) => {
            'date': (item['dt_txt']?.split(' ')[0] ?? 'N/A').toString(),
            'temp': (item['main']?['temp'] ?? 0).toString(),
            'condition': (item['weather']?[0]?['description'] ?? 'N/A')
                .toString(),
            'icon':
            'https://openweathermap.org/img/wn/${item['weather']?[0]?['icon'] ?? '01d'}@2x.png',
          })
              .toList() ??
              [];
          isLoading = false;
        });
      } else {
        throw Exception('Error fetching weather data.');
      }
    } catch (e) {
      setState(() {
        error = 'Error fetching weather data: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<void> _fetchCitySuggestions(String query) async {
    if (isFetchingSuggestions) return;

    setState(() {
      isFetchingSuggestions = true;
    });

    try {
       final url =
          'http://api.openweathermap.org/geo/1.0/direct?q=$query&limit=5&appid=a27607774edc2888034cfd0fb18100ae';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          citySuggestions =
              data.map<String>((city) => city['name'] as String).toList();
        });
      } else {
        throw Exception('Failed to fetch city suggestions');
      }
    } catch (e) {
      setState(() {
        error = 'Error fetching city suggestions: ${e.toString()}';
      });
    } finally {
      setState(() {
        isFetchingSuggestions = false;
      });
    }
  }
}
