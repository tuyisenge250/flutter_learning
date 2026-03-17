import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'counter_model.dart';

void main() {
  runApp(
    // Step 1: Wrap app with ChangeNotifierProvider
    // This makes CounterModel available to all child widgets
    ChangeNotifierProvider(
      create: (context) => CounterModel(), // Initialize the state
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const CounterScreen(),
    );
  }
}

class CounterScreen extends StatelessWidget {
  const CounterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Counter Example'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'You have pushed the button this many times:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            
            // Step 2: Use Consumer to listen to state changes
            // Only this widget rebuilds when count changes
            Consumer<CounterModel>(
              builder: (context, counter, child) {
                return Text(
                  '${counter.count}',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                );
              },
            ),
            
            const SizedBox(height: 40),
            
            // Buttons row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Decrement button
                ElevatedButton(
                  onPressed: () {
                    // Step 3: Use context.read() to update state
                    // read() doesn't listen for changes, just calls the method
                    context.read<CounterModel>().decrement();
                  },
                  child: const Icon(Icons.remove),
                ),
                
                const SizedBox(width: 20),
                
                // Reset button
                ElevatedButton(
                  onPressed: () {
                    context.read<CounterModel>().reset();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text('Reset'),
                ),
                
                const SizedBox(width: 20),
                
                // Increment button
                ElevatedButton(
                  onPressed: () {
                    context.read<CounterModel>().increment();
                  },
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            
            const SizedBox(height: 40),
            
            // Info card explaining Provider
            const InfoCard(),
          ],
        ),
      ),
    );
  }
}

// This widget doesn't rebuild when counter changes
// because it doesn't consume the state
class InfoCard extends StatelessWidget {
  const InfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'How Provider Works:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '1. CounterModel holds the state (count)',
            style: TextStyle(fontSize: 14),
          ),
          Text(
            '2. Consumer listens for changes',
            style: TextStyle(fontSize: 14),
          ),
          Text(
            '3. Buttons use read() to update state',
            style: TextStyle(fontSize: 14),
          ),
          Text(
            '4. notifyListeners() triggers rebuild',
            style: TextStyle(fontSize: 14),
          ),
          Text(
            '5. Only Consumer widget rebuilds!',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
