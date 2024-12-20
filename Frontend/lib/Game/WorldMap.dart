import 'package:flutter/material.dart';

class WorldMap extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ClipRect(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return InteractiveViewer(
                panEnabled: true, // 드래그 가능
                boundaryMargin: EdgeInsets.all(double.infinity), // 드래그 제한 없음
                minScale: 1.0, // 최소 확대 비율
                maxScale: 5.0, // 최대 확대 비율
                child: FittedBox(
                  child: SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxWidth * (8 / 16), // 사진 원본 비율 유지
                    child: Image.asset(
                      'assets/map.jpg',
                      fit: BoxFit.fill, // 원본 비율 유지
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
