import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;

class PointController extends GetxController {
  PointController(List<String> list) {
    for (var c in list) {
      candidates[c] = 0;
    }
  }

  RxInt point = RxInt(99);
  final candidates = RxMap();

  void clear() {
    candidates.updateAll((key, value) => 0);
    point.value = 99;
  }

  void inc(String key) {
    int v = candidates[key];
    int diff = pow(v + 1, 2) - pow(v, 2) as int;

    if (point >= diff) {
      point -= diff;
      candidates[key] = v + 1;
    }
  }

  void dec(String key) {
    int v = candidates[key];

    if (v <= 0) return;

    int diff = pow(v, 2) - pow(v - 1, 2) as int;

    point += diff;
    candidates[key] = v - 1;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  List<String> clist =
      (await rootBundle.loadString("assets/candidate.txt")).split("\n");
  clist.shuffle();
  Get.put(PointController(clist));

  runApp(const GetMaterialApp(home: Home()));
}

class CandidatesView extends StatelessWidget {
  const CandidatesView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final PointController pc = Get.find();

    Widget _trailing(String k) {
      return SizedBox(
        width: 150,
        child: Row(
          children: [
            IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () {
                  pc.dec(k);
                }),
            Obx(() => Text("${pc.candidates[k]}")),
            IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  pc.inc(k);
                })
          ],
        ),
      );
    }

    Widget _makeTile(String k) {
      return Container(
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.black38))),
        child: ListTile(
          title: Text(k),
          trailing: _trailing(k),
        ),
      );
    }

    return Container(
        padding: const EdgeInsets.all(3),
        child: ListView.builder(
          shrinkWrap: true,
          itemBuilder: (BuildContext context, int index) {
            final k = pc.candidates.keys.elementAt(index);

            return _makeTile(k);
          },
          itemCount: pc.candidates.length,
        ));
  }
}

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  Future<String> submit(String id, String postdata) async {
    return postdata;
  }

  @override
  Widget build(context) {
    const String title = "Whats your favorite language";

    final PointController pc = Get.find();
    final TextEditingController controller = TextEditingController();

    return Scaffold(
        appBar: AppBar(title: const Text(title)),
        body: Container(
          margin: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          child: SingleChildScrollView(
              child: Column(
            children: [
              Obx(() => Text("Total Point:${pc.point}")),
              Row(
                children: [
                  Flexible(
                    child: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          hintText: "Enter your id",
                        )),
                  ),
                  ElevatedButton(
                      onPressed: () async {
                        String post = "";
                        pc.candidates.forEach((key, value) {
                          if (value != 0) {
                            post += "${key.trim()}:$value, ";
                          }
                        });
                        String res = await submit(controller.text, post);
                        Get.dialog(AlertDialog(
                          title: const Text(title),
                          content: Text(res),
                          actions: [
                            TextButton(
                                onPressed: () {
                                  pc.clear();
                                  Get.back();
                                },
                                child: const Text("Close")),
                          ],
                        ));
                      },
                      child: const Text("Submit")),
                ],
              ),
              const CandidatesView(),
            ],
          )),
        ));
  }
}
