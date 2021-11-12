import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'dart:math';

class Candidate {
  Candidate({
    required this.name,
    required this.count,
  });

  final String name;
  final int count;
}

class CandidateList extends StateNotifier<List<Candidate>> {
  CandidateList(this.ref) : super([]);

  final Ref ref;

  int? operator [](String? key) {
    return state.firstWhere((c) => c.name == key).count;
  }

  void operator []=(String key, int value) {
    state = [
      for (final c in state)
        if (c.name == key) Candidate(name: c.name, count: value) else c,
    ];
  }

  void setCandidate(List<String> keys) {
    state = keys.map((k) => Candidate(name: k, count: 0)).toList();
  }

  void inc(String key) {
    int point = ref.read(pointProvider);
    int v = state.firstWhere((c) => c.name == key).count;
    int diff = pow(v + 1, 2) - pow(v, 2) as int;

    if (point >= diff) {
      ref.read(pointProvider.state).state -= diff;
      this[key] = v + 1;
    }
  }

  void dec(String key) {
    int v = state.firstWhere((c) => c.name == key).count;

    if (v <= 0) return;

    int diff = pow(v, 2) - pow(v - 1, 2) as int;

    ref.read(pointProvider.state).state += diff;
    this[key] = v - 1;
  }
}

final pointProvider = StateProvider((ref) => 99);
final candidateProvider = StateNotifierProvider<CandidateList, List<Candidate>>(
    (ref) => CandidateList(ref));

final List<String> candidatesList = [];

void main() async {
  // read candidate list
  WidgetsFlutterBinding.ensureInitialized();
  (await rootBundle.loadString("assets/candidate.txt"))
      .split("\n")
      .forEach((d) => candidatesList.add(d));
  candidatesList.shuffle();

  runApp(
    const ProviderScope(child: MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: Home());
  }
}

class CandidatesView extends HookConsumerWidget {
  const CandidatesView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final candidates = ref.watch(candidateProvider.notifier);

    Widget _trailing(String k) {
      return SizedBox(
        width: 150,
        child: Row(
          children: [
            IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () {
                  candidates.dec(k);
                }),
            HookConsumer(builder: (context, ref, _) {
              final c = ref.watch(candidateProvider);
              return Text('${c.firstWhere((n) => n.name == k).count}');
            }),
            IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  candidates.inc(k);
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
            final k = candidatesList[index];

            return _makeTile(k);
          },
          itemCount: candidatesList.length,
        ));
  }
}

class Home extends HookConsumerWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(candidateProvider.notifier).setCandidate(candidatesList);
    final TextEditingController _controller = TextEditingController();

    return Scaffold(
        appBar: AppBar(title: const Text('Whats your favorite language')),
        body: Container(
          margin: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          child: SingleChildScrollView(
              child: Column(
            children: [
              HookConsumer(builder: (context, ref, _) {
                final point = ref.watch(pointProvider);
                return Text('Total Point:$point');
              }),
              Row(
                children: [
                  Flexible(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          hintText: "Enter your id"),
                    ),
                  ),
                  ElevatedButton(onPressed: () {}, child: const Text("Submit"))
                ],
              ),
              const CandidatesView(),
            ],
          )),
        ));
  }
}
