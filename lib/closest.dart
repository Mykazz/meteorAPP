import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:asteroidsim/navigation.dart';

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
  final bool neo;

  final String? approachDate;
  final double? approachDist; // AU
  final double? approachVelocity; // km/s

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
    this.neo = false,
    this.approachDate,
    this.approachDist,
    this.approachVelocity,
  });

  factory Asteroid.fromSbdb(
    Map<String, dynamic> json,
    String name, {
    String? approachDate,
    double? approachDist,
    double? approachVelocity,
  }) {
    final orbit = json['orbit'];
    final elements = orbit['elements'];
    final object = json['object'];

    // Epoch parsing
    double? epochMjd;
    if (orbit['epoch'] is String || orbit['epoch'] is num) {
      epochMjd = double.tryParse(orbit['epoch'].toString());
    } else if (orbit['epoch'] is Map) {
      epochMjd = double.tryParse(orbit['epoch']['mjd'].toString());
    }

    // Elements parsing
    Map<String, double> elemMap = {};
    if (elements is List) {
      elemMap = {
        for (var e in elements)
          e['name']: double.tryParse(e['value'].toString()) ?? 0.0,
      };
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
      neo: (object != null && (object['neo'] == true || object['neo'] == "Y")),
      approachDate: approachDate,
      approachDist: approachDist,
      approachVelocity: approachVelocity,
    );
  }

  factory Asteroid.empty(String name) {
    return Asteroid(fullName: name, success: false);
  }

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
      "approachDate": approachDate,
      "approachDist": approachDist ?? 0.0,
      "approachVelocity": approachVelocity ?? 0.0,
      "neo": neo,
      "success": success,
    };
  }
}

// -----------------------------------------------------------
// Step 1: Fetch closest approach data
// -----------------------------------------------------------
Future<List<Map<String, dynamic>>> fetchCloseApproaches() async {
  final url = Uri.parse(
    "https://ssd-api.jpl.nasa.gov/cad.api"
    "?body=Earth"
    "&dist-max=0.01"
    "&date-min=2025-01-01"
    "&date-max=2026-12-31"
    "&sort=dist",
  );

  debugPrint("🌍 Fetching close approaches from: $url");
  final response = await http.get(url);
  if (response.statusCode == 200) {
    final jsonData = json.decode(response.body);
    final List<dynamic> data = jsonData['data'];
    final fields = List<String>.from(jsonData['fields']);

    return data.map((row) {
      final map = <String, dynamic>{};
      for (int i = 0; i < fields.length; i++) {
        map[fields[i]] = row[i];
      }
      return map;
    }).toList();
  } else {
    throw Exception("Failed to fetch CAD data (code ${response.statusCode})");
  }
}

// -----------------------------------------------------------
// Step 2: Fetch orbital details with retry
// -----------------------------------------------------------
Future<Asteroid> fetchAsteroidWithOrbit(Map<String, dynamic> cadEntry) async {
  final designation = cadEntry["des"];
  final url = Uri.parse(
    "https://ssd-api.jpl.nasa.gov/sbdb.api?sstr=$designation",
  );

  const maxRetries = 3;
  for (int attempt = 1; attempt <= maxRetries; attempt++) {
    debugPrint(
      "🔭 Fetching orbit for $designation (attempt $attempt/$maxRetries)...",
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final a = Asteroid.fromSbdb(
          jsonData,
          designation,
          approachDate: cadEntry["cd"],
          approachDist: double.tryParse(cadEntry["dist"].toString()),
          approachVelocity: double.tryParse(cadEntry["v_rel"].toString()),
        );
        debugPrint(
          "✅ Parsed orbit for $designation: "
          "a=${a.a?.toStringAsFixed(3)} e=${a.e?.toStringAsFixed(3)} i=${a.i?.toStringAsFixed(2)}",
        );
        return a;
      } else {
        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: 2 * attempt)); // backoff
          continue;
        }
      }
    } catch (e) {
      debugPrint("⚠️ Error fetching $designation: $e");
      if (attempt < maxRetries) {
        await Future.delayed(Duration(seconds: 2 * attempt));
        continue;
      }
    }
  }

  debugPrint("🚫 All retries failed for $designation — skipping.");
  return Asteroid.empty(designation);
}

// -----------------------------------------------------------
// Step 3: Combine CAD + SBDB
// -----------------------------------------------------------
Future<List<Asteroid>> fetchClosestAsteroids() async {
  debugPrint("🚀 Starting fetchClosestAsteroids...");
  final cadEntries = await fetchCloseApproaches();

  // Limit to 50 entries
  final limited = cadEntries.take(50).toList();
  debugPrint("📦 Limited to ${limited.length} CAD entries");

  final futures = limited.map(fetchAsteroidWithOrbit);
  final asteroids = await Future.wait(futures);

  // Filter valid
  final validAsteroids = asteroids.where((a) {
    final valid =
        a.success && (a.a != null && a.a! > 0) && (a.e != null && a.i != null);
    if (!valid) debugPrint("🚫 Skipping invalid asteroid: ${a.fullName}");
    return valid;
  }).toList();

  // Sort by distance
  validAsteroids.sort(
    (a, b) => (a.approachDist ?? double.infinity).compareTo(
      b.approachDist ?? double.infinity,
    ),
  );

  debugPrint("✅ Final valid asteroid count: ${validAsteroids.length}");
  return validAsteroids;
}

// -----------------------------------------------------------
// API Call to localhost
// -----------------------------------------------------------
Future<Map<String, dynamic>> sendAsteroidToApi(Asteroid asteroid) async {
  final url = Uri.parse("http://10.0.2.2:8000/v1/simulate");
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
// UI Screen
// -----------------------------------------------------------
class ClosestAsteroidsScreen extends StatelessWidget {
  const ClosestAsteroidsScreen({super.key});

  void _onAsteroidTap(BuildContext context, Asteroid asteroid) async {
    try {
      final apiResponse = await sendAsteroidToApi(asteroid);
      final pretty = const JsonEncoder.withIndent("  ").convert(apiResponse);

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ApiResponseScreen(response: pretty)),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("API error: $e")));
    }
  }

  void _goToNavig(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const Navig()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "Closest Earth Approaches",
          style: TextStyle(color: Colors.greenAccent, fontFamily: "monospace"),
        ),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.greenAccent),
            onPressed: () => _goToNavig(context),
          ),
        ],
      ),
      body: FutureBuilder<List<Asteroid>>(
        future: fetchClosestAsteroids(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Text(
                "Loading close approaches...",
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontFamily: "monospace",
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
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "No close approaches found.",
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontFamily: "monospace",
                ),
              ),
            );
          }

          final asteroids = snapshot.data!;
          return ListView.builder(
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
                    "[${index + 1}]  ${a.fullName}\n"
                    "     Date : ${a.approachDate ?? 'unknown'}\n"
                    "     Dist : ${(a.approachDist ?? 0).toStringAsExponential(3)} AU\n"
                    "     Vrel : ${(a.approachVelocity ?? 0).toStringAsFixed(2)} km/s\n"
                    "     a    : ${a.a?.toStringAsFixed(3)} AU\n"
                    "     e    : ${a.e?.toStringAsFixed(3)}\n"
                    "     i    : ${a.i?.toStringAsFixed(2)}°\n"
                    "     Ω    : ${a.node?.toStringAsFixed(2)}°\n"
                    "     ω    : ${a.peri?.toStringAsFixed(2)}°\n"
                    "     M    : ${a.M?.toStringAsFixed(2)}°\n"
                    "     NEO  : ${a.neo ? "✅" : "❌"}",
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontFamily: "monospace",
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------
// API Response Screen
// -----------------------------------------------------------
class ApiResponseScreen extends StatelessWidget {
  final String response;
  const ApiResponseScreen({super.key, required this.response});

  void _goToNavig(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const Navig()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "API Response",
          style: TextStyle(color: Colors.greenAccent, fontFamily: "monospace"),
        ),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.greenAccent),
            tooltip: "Return to Navigation",
            onPressed: () => _goToNavig(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(
          response,
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
