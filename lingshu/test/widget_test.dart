import 'package:flutter_test/flutter_test.dart';

import 'package:lingshu/core/services/content_loader.dart';

void main() {
  test('内容数据仓库可实例化', () {
    final repo = ContentRepo();
    expect(repo.loaded, isFalse);
  });
}
