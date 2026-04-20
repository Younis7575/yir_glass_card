import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yir_glass_card/yir_glass_card.dart';

void main() {
  test('YirGlassCard creates successfully', () {
    final card = YirGlassCard(
      width: 100,
      height: 100,
      color:   Colors.blue,
      
    );

    expect(card.width, 100);
    expect(card.height, 100);
  });
}