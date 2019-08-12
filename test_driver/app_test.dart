import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';
void main() {
  group('Trackmart', () {
    FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });
    test('check flutter driver health', () async {
      Health health = await driver.checkHealth();
      print(health.status);
    });
    test('Flutter drive methods demo', () async {

      await driver.tap(find.byValueKey('request'));
      await driver.enterText('Hello !');
      await driver.waitFor(find.text('Hello !'));
      await driver.enterText('World');
      await driver.waitForAbsent(find.text('Hello !'));
      print('World');
      await driver.waitFor(find.byValueKey('request'));
      await driver.tap(find.byValueKey('request'));
      print('Button clicked');
      await driver.waitFor(find.byValueKey('rate'));
      await driver.scrollIntoView(find.byValueKey('rate'));
      await driver.waitFor(find.text('No requested deliveries'));
      print('I found you buddy !');
    });
    tearDownAll(() async {
      if (driver != null) {
        await driver.close();
      }
    });
  });
}