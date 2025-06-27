import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tic_tac_toe/ai_player.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;

  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _getThemeMode(),
      home: HomePage(
        prefs: prefs,
      ),
    );
  }

  ThemeMode _getThemeMode() {
    bool isDarkMode = prefs.getBool('isDarkMode') ?? false;
    return isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }
}

class HomePage extends StatefulWidget {
  final SharedPreferences prefs;
  const HomePage({super.key, required this.prefs});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  AIPlayer? aiPlayer;

  bool oTurn = true;
  int oScore = 0;
  int xScore = 0;
  List<String> displayElement = ['', '', '', '', '', '', '', '', ''];
  int filledBoxes = 0;
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadThemeMode();
    aiPlayer = AIPlayer(); // Initialize AIPlayer here
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _saveThemeMode(isDarkMode);
    }
  }

  _loadThemeMode() {
    bool savedIsDarkMode = widget.prefs.getBool('isDarkMode') ?? false;
    setState(() {
      isDarkMode = savedIsDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: isDarkMode ? Colors.black38 : Colors.white,
        title: Text(
          'Tic Tac Toe',
          style: TextStyle(color: _getTextColor()),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            onPressed: () {
              setState(() {
                isDarkMode = !isDarkMode;
                _saveThemeMode(isDarkMode);
              });
            },
          ),
        ],
      ),
      backgroundColor: isDarkMode ? Colors.black38 : Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(30),
                child: Text(
                  'Player X',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _getTextColor()),
                ),
              ),
              Text(
                "= $xScore",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _getTextColor(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(30),
                child: Text(
                  'Player 0',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _getTextColor(),
                  ),
                ),
              ),
              Text(
                "= $oScore",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _getTextColor(),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 50,
          ),
          SizedBox(
            height: 500,
            child: GridView.builder(
                itemCount: 9,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3),
                itemBuilder: (BuildContext context, int index) {
                  return GestureDetector(
                    onTap: () {
                      _tapped(index);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _getBorderColor(),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          displayElement[index],
                          style:
                              TextStyle(color: _getTextColor(), fontSize: 35),
                        ),
                      ),
                    ),
                  );
                }),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: MaterialButton(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40)),
              minWidth: double.infinity,
              height: 50,
              color: Colors.deepOrangeAccent,
              onPressed: _clearScoreBoard,
              child: const Text(
                "Clear Score Board",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTextColor() {
    return isDarkMode ? Colors.white : Colors.black;
  }

  Color _getBorderColor() {
    return isDarkMode ? Colors.white : Colors.black;
  }

  void _tapped(int index) {
    setState(() {
      if (oTurn && displayElement[index] == '') {
        displayElement[index] = 'X';
        filledBoxes++;
      } else if (!oTurn && displayElement[index] == '') {
        displayElement[index] = 'O';
        filledBoxes++;
      }
      oTurn = !oTurn;
      _checkWinner();

      // Check if it's the AI's turn
      if (!oTurn && filledBoxes < 9) {
        int aiMoveIndex = aiPlayer!.findBestMove(displayElement);
        _tapped(aiMoveIndex);
      }
    });
  }

  /// Checks for a winner using the same winning-combination logic as the AI.
  /// This reduces duplicate loops and ensures consistent win detection.
  void _checkWinner() {
    final result = AIPlayer.findWinningCombination(displayElement);
    if (result.isNotEmpty) {
      _showWinDialog(result[0]);
    } else if (filledBoxes == 9) {
      _showDrawDialog();
    }
  }

  void _showDrawDialog() {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Draw"),
            actions: [
              OutlinedButton(
                  onPressed: () {
                    _clearScoreBoard();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Play Again'))
            ],
          );
        });
  }

  void _clearScoreBoard() {
    setState(() {
      xScore = 0;
      oScore = 0;
      for (int i = 0; i < 9; i++) {
        displayElement[i] = '';
      }
    });
    filledBoxes = 0;
  }

  void _showWinDialog(String winner) {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("\" $winner\" is winner!!!"),
            actions: [
              OutlinedButton(
                  onPressed: () {
                    _clearScoreBoard();
                    Navigator.pop(context);
                  },
                  child: const Text('Play Again'))
            ],
          );
        });
    if (winner == 'O') {
      oScore++;
    } else if (winner == 'X') {
      xScore++;
    }
  }

  // Save Theme Mode here,
  Future<void> _saveThemeMode(bool isDarkMode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
  }
}
