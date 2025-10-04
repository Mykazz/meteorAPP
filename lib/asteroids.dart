import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

// -----------------------------------------------------------
// Data Model
// -----------------------------------------------------------
class Asteroid {
  final String fullName;
  final double? epochMjd;
  final double? a;
  final double? e;
  final double? i;
  final double? node;
  final double? peri;
  final double? M;
  final bool success;

  Asteroid({
    required this.fullName,
    this.epochMjd,
    this.a,
    this.e,
    this.i,
    this.node,
    this.peri,
    this.M,
    this.success = true,
  });

  factory Asteroid.fromSbdb(Map<String, dynamic> json, String name) {
    final orbit = json['orbit'];
    final elements = orbit['elements'];

    // ✅ Epoch can be string, num, or object
    double? epochMjd;
    if (orbit['epoch'] is String || orbit['epoch'] is num) {
      epochMjd = double.tryParse(orbit['epoch'].toString());
    } else if (orbit['epoch'] is Map) {
      epochMjd = double.tryParse(orbit['epoch']['mjd'].toString());
    }

    // ✅ Elements can be List or Map
    Map<String, double> elemMap = {};
    if (elements is List) {
      elemMap = {
        for (var e in elements)
          e['name']: double.tryParse(e['value'].toString()) ?? 0.0,
      };
    } else if (elements is Map) {
      elemMap = elements.map(
        (k, v) => MapEntry(k.toString(), double.tryParse(v.toString()) ?? 0.0),
      );
    }

    return Asteroid(
      fullName: name,
      epochMjd: epochMjd,
      a: elemMap['a'],
      e: elemMap['e'],
      i: elemMap['i'],
      node: elemMap['om'],
      peri: elemMap['w'],
      M: elemMap['ma'],
      success: true,
    );
  }

  // Fallback empty asteroid
  factory Asteroid.empty(String name) {
    return Asteroid(fullName: name, success: false);
  }

  // Convert to JSON for API call
  Map<String, dynamic> toApiJson() {
    return {
      "fullName": fullName,
      "epochMjd": epochMjd ?? 0.0,
      "a": a ?? 0.0,
      "e": e ?? 0.0,
      "i": i ?? 0.0,
      "node": node ?? 0.0,
      "peri": peri ?? 0.0,
      "M": M ?? 0.0,
      "success": success,
    };
  }
}

// -----------------------------------------------------------
// Step 1: Fetch asteroid IDs (SPKID + names)
// -----------------------------------------------------------
Future<List<Map<String, String>>> fetchAsteroidIds() async {
  final url = Uri.parse(
    'https://ssd-api.jpl.nasa.gov/sbdb_query.api'
    '?fields=full_name,spkid'
    '&sb-kind=a'
    '&limit=10',
  );

  final response = await http.get(url);
  if (response.statusCode == 200) {
    final jsonData = json.decode(response.body);
    final List<dynamic> data = jsonData['data'];

    return data.map<Map<String, String>>((row) {
      if (row is List && row.length >= 2) {
        return {"name": row[0].toString(), "id": row[1].toString()};
      } else {
        throw Exception("Unexpected row format: $row");
      }
    }).toList();
  } else {
    throw Exception(
      "Failed to fetch asteroid IDs (code ${response.statusCode})",
    );
  }
}

// -----------------------------------------------------------
// Step 2: Fetch details with retry + fallback
// -----------------------------------------------------------
Future<Asteroid> fetchAsteroidDetails(String spkid, String name) async {
  Future<Asteroid> tryFetch(String query, String label) async {
    final url = Uri.parse('https://ssd-api.jpl.nasa.gov/sbdb.api?sstr=$query');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return Asteroid.fromSbdb(jsonData, name);
    } else {
      throw Exception("Failed with code ${response.statusCode}");
    }
  }

  for (int attempt = 1; attempt <= 2; attempt++) {
    try {
      return await tryFetch(spkid, "spkid");
    } catch (_) {
      await Future.delayed(Duration(seconds: attempt));
    }
  }

  final designation = name.split(" ").first;
  try {
    return await tryFetch(designation, "pdes");
  } catch (_) {}

  try {
    return await tryFetch(Uri.encodeComponent(name), "full_name");
  } catch (_) {}

  return Asteroid.empty(name);
}

// -----------------------------------------------------------
// Step 3: Fetch all asteroids
// -----------------------------------------------------------
Future<List<Asteroid>> fetchAsteroids() async {
  final ids = await fetchAsteroidIds();
  final futures = ids.map((entry) async {
    return await fetchAsteroidDetails(entry["id"]!, entry["name"]!);
  });
  return await Future.wait(futures);
}

// -----------------------------------------------------------
// API CALL: Send asteroid to FastAPI
// -----------------------------------------------------------
Future<Map<String, dynamic>> sendAsteroidToApi(Asteroid asteroid) async {
  final url = Uri.parse("http://10.0.2.2:8000/v1/simulate");
  // 👈 your FastAPI
  final response = await http.post(
    url,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(asteroid.toApiJson()),
  );

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception("API call failed: ${response.statusCode}");
  }
}

// -----------------------------------------------------------
// UI Screen: Asteroid List
// -----------------------------------------------------------
class AsteroidListScreen extends StatelessWidget {
  const AsteroidListScreen({super.key});

  void _onAsteroidTap(BuildContext context, Asteroid asteroid) async {
    try {
      final apiResponse = await sendAsteroidToApi(asteroid);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ApiResponseScreen(response: apiResponse),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("API error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "Asteroid Database Terminal",
          style: TextStyle(color: Colors.greenAccent, fontFamily: "monospace"),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FutureBuilder<List<Asteroid>>(
          future: fetchAsteroids(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Text(
                  "Connecting to NASA database...",
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontFamily: "monospace",
                    fontSize: 18,
                  ),
                ),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  "Error: ${snapshot.error}",
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontFamily: "monospace",
                    fontSize: 18,
                  ),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  "No asteroid data found.",
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontFamily: "monospace",
                    fontSize: 18,
                  ),
                ),
              );
            }

            final asteroids = snapshot.data!;

            return ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: asteroids.length,
              itemBuilder: (context, index) {
                final a = asteroids[index];
                return InkWell(
                  onTap: () => _onAsteroidTap(context, a),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.greenAccent.withOpacity(0.4),
                      ),
                      borderRadius: BorderRadius.circular(4),
                      color: Colors.black,
                    ),
                    child: Text(
                      a.success
                          ? "[${index + 1}]  ${a.fullName}\n"
                                "     Epoch (MJD): ${a.epochMjd}\n"
                                "     a   : ${a.a?.toStringAsFixed(6)} AU\n"
                                "     e   : ${a.e?.toStringAsFixed(6)}\n"
                                "     i   : ${a.i?.toStringAsFixed(4)}°\n"
                                "     Ω   : ${a.node?.toStringAsFixed(4)}°\n"
                                "     ω   : ${a.peri?.toStringAsFixed(4)}°\n"
                                "     M   : ${a.M?.toStringAsFixed(4)}°"
                          : "[${index + 1}]  ${a.fullName}\n"
                                "     ❌ Orbital data unavailable",
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontFamily: "monospace",
                        fontSize: 15,
                        height: 1.3,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// -----------------------------------------------------------
// UI Screen: API Response
// -----------------------------------------------------------
class ApiResponseScreen extends StatelessWidget {
  final Map<String, dynamic> response;
  const ApiResponseScreen({super.key, required this.response});

  @override
  Widget build(BuildContext context) {
    final prettyJson = const JsonEncoder.withIndent("  ").convert(response);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "API Response",
          style: TextStyle(color: Colors.greenAccent, fontFamily: "monospace"),
        ),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(
          prettyJson,
          style: const TextStyle(
            color: Colors.greenAccent,
            fontFamily: "monospace",
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------
// Main
// -----------------------------------------------------------
