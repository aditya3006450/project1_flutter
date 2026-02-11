import 'package:flutter/material.dart';

class ConnectCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final VoidCallback onConnect;

  const ConnectCard({
    super.key,
    required this.name,
    required this.subtitle,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: Card(
                elevation: 0,
                child: SizedBox(width: double.infinity),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(subtitle, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  Card(
                    shape: const CircleBorder(),
                    child: IconButton(
                      onPressed: onConnect,
                      icon: Icon(Icons.add),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
