import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';

class Asteroid {
  final int spkid;
  final String fullName;
  final String pdes;

  Asteroid({required this.spkid, required this.fullName, required this.pdes});

  factory Asteroid.fromJson(List<dynamic> json) {
    return Asteroid(spkid: json[0], fullName: json[1], pdes: json[2]);
  }
}

Future<List<Asteroid>> fetchAsteroids() async {
  final url = Uri.parse(
    'https://ssd-api.jpl.nasa.gov/sbdb_query.api?fields=spkid,full_name,pdes&sb-kind=a&limit=30',
  );

  final response = await http.get(url);

  if (response.statusCode == 200) {
    final jsonData = json.decode(response.body);

    List<dynamic> data = jsonData['data'];
    return data.map((item) => Asteroid.fromJson(item)).toList();
  } else {
    throw Exception("Failed to load asteroids");
  }
}

class AsteroidListScreen extends StatelessWidget {
  const AsteroidListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Asteroids")),
      body: FutureBuilder<List<Asteroid>>(
        future: fetchAsteroids(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No asteroids found"));
          }

          final asteroids = snapshot.data!;

          return ListView.builder(
            itemCount: asteroids.length,
            itemBuilder: (context, index) {
              final asteroid = asteroids[index];
              return ListTile(
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.blueAccent),
                  borderRadius: BorderRadius.circular(1),
                ),
                leading: Text(asteroid.spkid.toString()),
                title: Text(asteroid.fullName),
              );
            },
          );
        },
      ),
    );
  }
}
