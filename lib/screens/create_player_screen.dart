import 'package:flutter/material.dart';

import '../core/game_engine.dart';
import '../models/player.dart';

class CreatePlayerScreen extends StatefulWidget {
  final GameEngine engine;

  const CreatePlayerScreen({
    super.key,
    required this.engine,
  });

  @override
  State<CreatePlayerScreen> createState() =>
      _CreatePlayerScreenState();
}

class _CreatePlayerScreenState
    extends State<CreatePlayerScreen> {
  final _formKey = GlobalKey<FormState>();

  final firstNameController =
      TextEditingController();

  final lastNameController =
      TextEditingController();

  final nationalityController =
      TextEditingController(
    text: 'Polska',
  );

  final heightController =
      TextEditingController(
    text: '178',
  );

  final ageController =
      TextEditingController(
    text: '18',
  );

  PlayerPosition selectedPosition =
      PlayerPosition.winger;

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    nationalityController.dispose();
    heightController.dispose();
    ageController.dispose();

    super.dispose();
  }

  // ==========================================================
  // UTWORZENIE ZAWODNIKA
  // ==========================================================

  void createPlayer() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final age =
        int.parse(ageController.text);

    final height =
        int.parse(heightController.text);

    widget.engine.createPlayer(
      firstName:
          firstNameController.text.trim(),

      lastName:
          lastNameController.text.trim(),

      nationality:
          nationalityController.text.trim(),

      age: age,

      height: height,

      position:
          selectedPosition,

      // Na tym etapie bazowe statystyki
      // generujemy automatycznie.
      pace: 60,
      shooting: 60,
      passing: 60,
      dribbling: 60,
      defending: 60,
      physical: 60,
    );

    Navigator.pop(context);
  }

  // ==========================================================
  // NAZWA POZYCJI
  // ==========================================================

  String positionName(
    PlayerPosition position,
  ) {
    switch (position) {
      case PlayerPosition.goalkeeper:
        return 'BRAMKARZ';

      case PlayerPosition.defender:
        return 'OBROŃCA';

      case PlayerPosition.midfielder:
        return 'POMOCNIK';

      case PlayerPosition.winger:
        return 'SKRZYDŁOWY';

      case PlayerPosition.striker:
        return 'NAPASTNIK';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF080A0F),

      appBar: AppBar(
        title: const Text(
          'NOWA KARIERA',
        ),
        backgroundColor:
            const Color(0xFF080A0F),
      ),

      body: SafeArea(
        child: Form(
          key: _formKey,

          child: ListView(
            padding:
                const EdgeInsets.all(16),

            children: [
              // ==================================================
              // NAGŁÓWEK
              // ==================================================

              const Text(
                'STWÓRZ ZAWODNIKA',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight:
                      FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Rozpocznij swoją piłkarską karierę.',
                style: TextStyle(
                  color: Colors.white54,
                ),
              ),

              const SizedBox(height: 24),

              // ==================================================
              // IMIĘ
              // ==================================================

              TextFormField(
                controller:
                    firstNameController,

                decoration:
                    const InputDecoration(
                  labelText: 'Imię',
                  border:
                      OutlineInputBorder(),
                  prefixIcon:
                      Icon(Icons.person),
                ),

                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Wpisz imię.';
                  }

                  if (value.trim().length <
                      2) {
                    return 'Imię jest za krótkie.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 14),

              // ==================================================
              // NAZWISKO
              // ==================================================

              TextFormField(
                controller:
                    lastNameController,

                decoration:
                    const InputDecoration(
                  labelText: 'Nazwisko',
                  border:
                      OutlineInputBorder(),
                  prefixIcon:
                      Icon(Icons.badge),
                ),

                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Wpisz nazwisko.';
                  }

                  if (value.trim().length <
                      2) {
                    return 'Nazwisko jest za krótkie.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 14),

              // ==================================================
              // NARODOWOŚĆ
              // ==================================================

              TextFormField(
                controller:
                    nationalityController,

                decoration:
                    const InputDecoration(
                  labelText: 'Narodowość',
                  border:
                      OutlineInputBorder(),
                  prefixIcon:
                      Icon(Icons.flag),
                ),

                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Wpisz narodowość.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 14),

              // ==================================================
              // WIEK
              // ==================================================

              TextFormField(
                controller:
                    ageController,

                keyboardType:
                    TextInputType.number,

                decoration:
                    const InputDecoration(
                  labelText: 'Wiek',
                  border:
                      OutlineInputBorder(),
                  prefixIcon:
                      Icon(Icons.cake),
                ),

                validator: (value) {
                  final age =
                      int.tryParse(
                    value ?? '',
                  );

                  if (age == null) {
                    return 'Wpisz prawidłowy wiek.';
                  }

                  if (age < 16 ||
                      age > 35) {
                    return 'Wiek musi być od 16 do 35 lat.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 14),

              // ==================================================
              // WZROST
              // ==================================================

              TextFormField(
                controller:
                    heightController,

                keyboardType:
                    TextInputType.number,

                decoration:
                    const InputDecoration(
                  labelText: 'Wzrost (cm)',
                  border:
                      OutlineInputBorder(),
                  prefixIcon:
                      Icon(Icons.height),
                ),

                validator: (value) {
                  final height =
                      int.tryParse(
                    value ?? '',
                  );

                  if (height == null) {
                    return 'Wpisz prawidłowy wzrost.';
                  }

                  if (height < 150 ||
                      height > 220) {
                    return 'Wzrost musi być od 150 do 220 cm.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 24),

              // ==================================================
              // POZYCJA
              // ==================================================

              const Text(
                'POZYCJA',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              DropdownButtonFormField<
                  PlayerPosition>(
                value:
                    selectedPosition,

                decoration:
                    const InputDecoration(
                  border:
                      OutlineInputBorder(),
                  prefixIcon:
                      Icon(
                    Icons.sports_soccer,
                  ),
                ),

                items: PlayerPosition
                    .values
                    .map(
                      (position) {
                        return DropdownMenuItem<
                            PlayerPosition>(
                          value: position,

                          child: Text(
                            positionName(
                              position,
                            ),
                          ),
                        );
                      },
                    )
                    .toList(),

                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    selectedPosition =
                        value;
                  });
                },
              ),

              const SizedBox(height: 30),

              // ==================================================
              // START KARIERY
              // ==================================================

              SizedBox(
                width:
                    double.infinity,

                height: 54,

                child:
                    ElevatedButton.icon(
                  onPressed:
                      createPlayer,

                  icon: const Icon(
                    Icons.play_arrow,
                  ),

                  label: const Text(
                    'ROZPOCZNIJ KARIERĘ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Twój zawodnik rozpocznie karierę '
                'z podstawowymi statystykami. '
                'Rozwój będzie zależał od treningów, '
                'meczów, formy oraz decyzji w trakcie kariery.',
                textAlign:
                    TextAlign.center,

                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
