import 'package:flutter/material.dart';
import 'package:project1_flutter/app/widgets/connect_card.dart';

class LiveUsers extends StatelessWidget {
  const LiveUsers({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: GridView.extent(
            padding: EdgeInsets.only(bottom: 86),
            childAspectRatio: 0.70,
            maxCrossAxisExtent: 300,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              ConnectCard(name: "WTF", subtitle: "WTF", onConnect: () {}),
              ConnectCard(name: "WTF", subtitle: "WTF", onConnect: () {}),
            ],
          ),
        ),
      ),
    );
  }
}
