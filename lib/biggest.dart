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
  final String spkid;
  final double? absoluteMagnitude;

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
    required this.spkid,
    this.absoluteMagnitude,
    this.epochMjd,
    this.a,
    this.e,
    this.i,
    this.node,
    this.peri,
    this.M,
    this.success = true,
  });

  factory Asteroid.fromSbdb(
    Map<String, dynamic> json,
    String fullName,
    String spkid,
  ) {
    final orbit = json['orbit'];
    final elements = orbit['elements'];

    // Epoch
    double? epochMjd;
    if (orbit['epoch'] is String || orbit['epoch'] is num) {
      epochMjd = double.tryParse(orbit['epoch'].toString());
    } else if (orbit['epoch'] is Map) {
      epochMjd = double.tryParse(orbit['epoch']['mjd'].toString());
    }

    // Elements
    Map<String, double> elemMap = {};
    if (elements is List) {
      elemMap = {
        for (var e in elements)
          e['name']: double.tryParse(e['value'].toString()) ?? 0.0,
      };
    }

    // Absolute Magnitude H
    double? H;
    if (json.containsKey("phys_par")) {
      for (var p in json["phys_par"]) {
        if (p["name"] == "H") {
          H = double.tryParse(p["value"].toString());
          break;
        }
      }
    }

    return Asteroid(
      fullName: fullName,
      spkid: spkid,
      absoluteMagnitude: H,
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

  factory Asteroid.empty(String fullName, String spkid) {
    return Asteroid(fullName: fullName, spkid: spkid, success: false);
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
      "success": success,
    };
  }
}

// -----------------------------------------------------------
// Step 1: Fetch list of asteroids
// -----------------------------------------------------------
Future<List<Map<String, dynamic>>> fetchAsteroidList() async {
  final url = Uri.parse(
    "https://ssd-api.jpl.nasa.gov/sbdb_query.api"
    "?fields=full_name,spkid"
    "&sb-kind=a"
    "&limit=20",
  );

  final response = await http.get(url);

  if (response.statusCode == 200) {
    final jsonData = json.decode(response.body);
    final fields = List<String>.from(jsonData['fields']);
    final data = jsonData['data'] as List;

    return data.map((row) {
      final map = <String, dynamic>{};
      for (int i = 0; i < fields.length; i++) {
        map[fields[i]] = row[i];
      }
      return map;
    }).toList();
  } else {
    throw Exception(
      "Failed to fetch asteroid list (code ${response.statusCode})",
    );
  }
}

// -----------------------------------------------------------
// Step 2: Fetch details
// -----------------------------------------------------------
Future<Asteroid> fetchAsteroidDetails(
  String fullName,
  String spkid, {
  int retries = 3,
}) async {
  final url = Uri.parse(
    "https://ssd-api.jpl.nasa.gov/sbdb.api?sstr=$spkid&phys-par=true",
  );

  debugPrint("🔭 Fetching details for $fullName ($spkid): $url");

  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final asteroid = Asteroid.fromSbdb(jsonData, fullName, spkid);
      debugPrint("✅ Success: $fullName, H=${asteroid.absoluteMagnitude}");
      return asteroid;
    } else {
      debugPrint(
        "❌ Failed detail for $fullName (code: ${response.statusCode})",
      );
      if (retries > 0) {
        await Future.delayed(Duration(milliseconds: 500));
        return fetchAsteroidDetails(fullName, spkid, retries: retries - 1);
      }
      return Asteroid.empty(fullName, spkid);
    }
  } catch (e) {
    debugPrint("❌ Exception for $fullName ($spkid): $e");
    return Asteroid.empty(fullName, spkid);
  }
}

// -----------------------------------------------------------
// Step 3: Combine and sort
// -----------------------------------------------------------
Future<List<Asteroid>> fetchBiggestAsteroids() async {
  final list = await fetchAsteroidList();
  final futures = list.map((entry) async {
    final fullName = entry["full_name"].toString().trim();
    final spkid = entry["spkid"].toString().trim();
    return fetchAsteroidDetails(fullName, spkid);
  });

  final asteroids = await Future.wait(futures);

  final valid = asteroids
      .where((a) => a.success && a.absoluteMagnitude != null)
      .toList();

  valid.sort(
    (a, b) => (a.absoluteMagnitude ?? 99).compareTo(b.absoluteMagnitude ?? 99),
  );

  return valid;
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
class BiggestAsteroidsScreen extends StatelessWidget {
  const BiggestAsteroidsScreen({super.key});

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
          "Biggest Asteroids (by H)",
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
      body: FutureBuilder<List<Asteroid>>(
        future: fetchBiggestAsteroids(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Text(
                "Loading...",
                style: TextStyle(color: Colors.greenAccent),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: TextStyle(color: Colors.redAccent),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "No asteroid data.",
                style: TextStyle(color: Colors.greenAccent),
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
                    "[${index + 1}] ${a.fullName} (spkid=${a.spkid})\n"
                    "     H     : ${a.absoluteMagnitude?.toStringAsFixed(2) ?? 'unknown'}\n"
                    "     Epoch : ${a.epochMjd ?? 0}\n"
                    "     a     : ${a.a?.toStringAsFixed(6)} AU\n"
                    "     e     : ${a.e?.toStringAsFixed(6)}\n"
                    "     i     : ${a.i?.toStringAsFixed(4)}°\n"
                    "     Ω     : ${a.node?.toStringAsFixed(4)}°\n"
                    "     ω     : ${a.peri?.toStringAsFixed(4)}°\n"
                    "     M     : ${a.M?.toStringAsFixed(4)}°",
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
