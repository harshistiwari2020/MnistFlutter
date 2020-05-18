import 'package:collection_ext/iterables.dart';
import 'package:flttf/constants.dart';
import 'package:flttf/drawing_painter.dart';
import 'package:flttf/predictions.dart';
import 'package:flttf/recognizer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RecognizerScreen extends StatefulWidget {
  RecognizerScreen({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _RecognizerScreenState createState() => _RecognizerScreenState();
}

class _RecognizerScreenState extends State<RecognizerScreen> {
  final points = List<Offset>();
  final recognizer = Recognizer();
  bool modelReady = false;
  List predicts;
  List<Predictions> predictions = [];

  @override
  void initState() {
    super.initState();
    _initModel();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                child: Text(
                  'Write Digits Below',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        width: 1.5,
                        color: Colors.blue,
                      ),
                    ),
                    child: modelReady
                        ? _buildCanvas()
                        : const SizedBox(width: canvasSize, height: canvasSize),
                  ),
                  _buildClearButton(),
                ],
              ),
              Expanded(
                flex: 3,
                child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    color: Colors.grey.shade100,
                    alignment: Alignment.topCenter,
                    child: predictions.isEmpty
                        ? Text('Nothing Here!')
                        : listPredictions(predictions)),
              ),
            ],
          ),
        ),
      );

  Widget listPredictions(List<Predictions> pred) => ListView.builder(
        itemCount: pred.length,
        itemBuilder: (context, index) {
          print('In here ${pred[index].label}');
          return Center(
            child: Column(children: <Widget>[
              Text(
                pred[index].label.toString(),
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Confidence',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(
                '${pred[index].confidence.toString()}',
              )
            ]),
          );
        },
      );

  Widget _buildCanvas() => Builder(
        builder: (BuildContext context) => GestureDetector(
          onPanUpdate: (details) {
            if(predictions.isNotEmpty){
              predictions.clear();
            }
            _addPoint(context: context, offset: details.globalPosition);
          },
          onPanStart: (details) {
            _addPoint(context: context, offset: details.globalPosition);
          },
          onPanEnd: (details) {
            _addPoint(end: true);
          },
          child: ClipRect(
            child: CustomPaint(
              size: const Size(canvasSize, canvasSize),
              painter: DrawingPainter(
                offsetPoints: points,
              ),
            ),
          ),
        ),
      );


  Widget _buildClearButton() => Positioned(
        right: 0,
        child: IconButton(
          icon: const Icon(Icons.refresh, color: Colors.grey),
          onPressed: _onClear,
        ),
      );


  void _addPoint({
    BuildContext context,
    Offset offset,
    end = false,
  }) {
    if (end) {
      points.add(null);
      _recognize();
    } else {
      RenderBox renderBox = context.findRenderObject();
      setState(() {
        points.add(renderBox.globalToLocal(offset));
      });
    }
  }

  void _onClear() => setState(() {
        points.clear();
        predictions.clear();
      });
  void _clearPredictions() => setState((){
    predictions.clear();
  });
  Future _initModel() async {
    await recognizer.loadModel();
    debugPrint("model is loaded...");
    setState(() {
      modelReady = true;
    });
  }

  Future _recognize() async {
    final pred = await recognizer.recognize(points);
    debugPrint("prediction: [${pred.length}]$pred");
    setState(() {
      print('Prediction: ${pred[0]['confidence']}');
      for (var _pred in pred) {
        predictions.add(Predictions(
            confidence: _pred['confidence'], label: _pred['label']));
      }
      print(pred);
    });
  }

}
