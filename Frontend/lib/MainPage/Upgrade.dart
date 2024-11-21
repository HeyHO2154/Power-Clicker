import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../Login.dart';

class Upgrade extends StatefulWidget {
  @override
  _UpgradeState createState() => _UpgradeState();
}

class _UpgradeState extends State<Upgrade> {
  Random random = Random();
  int totalPoints = 0;
  bool isFactoryActive = false;
  DateTime? factoryEndTime;
  Timer? refreshTimer;
  TextEditingController _userIdController = TextEditingController();
  List<ProductDetails> _products = [];

  @override
  void initState() {
    super.initState();
    _initializeGoogleInApp();
    _fetchPoints();
    _loadProducts(); // 상품 정보 로드
    _loadFactoryStatus();
    refreshTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      _checkFactoryStatus();
    });
  }

  void _initializeGoogleInApp() {
    InAppPurchase.instance.purchaseStream.listen((purchaseDetailsList) {
      _handlePurchaseUpdates(purchaseDetailsList);
    });
  }
  Future<void> _loadProducts() async {
    const Set<String> productIds = {'point_1000', 'point_5500', 'point_12000'};
    final ProductDetailsResponse response =
    await InAppPurchase.instance.queryProductDetails(productIds);

    if (response.error != null) {
      print("Failed to load products: ${response.error!.message}");
      _showErrorDialog("No products, please try again");
      return;
    }

    if (response.productDetails.isEmpty) {
      print("No products found.");
      _showErrorDialog("No products, please try again");
      return;
    }

    setState(() {
      _products = response.productDetails;
    });
    print("Products loaded successfully: $_products");
  }
  void _buyProduct(ProductDetails productDetails) {
    try {
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
      InAppPurchase.instance.buyConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      print("구매 요청 중 예외 발생: $e");
      _showErrorDialog("Error, please try again");
    }
  }
  void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) {
    for (var purchaseDetails in purchaseDetailsList) {
      switch (purchaseDetails.status) {
        case PurchaseStatus.purchased:
          _grantPoints(purchaseDetails.productID);
          InAppPurchase.instance.completePurchase(purchaseDetails);
          break;
        case PurchaseStatus.pending:
          print("결제 대기 중...");
          break;
        case PurchaseStatus.restored:
          print("복원된 구매: ${purchaseDetails.productID}");
          InAppPurchase.instance.completePurchase(purchaseDetails);
          break;
        case PurchaseStatus.error:
          print("Purchase error: ${purchaseDetails.error}");
          break;
        default:
          break;
      }
    }
  }
  Future<void> _grantPoints(String productId) async {
    int pointsToGrant = 0;

    // 구매한 상품 ID에 따라 지급할 포인트 결정
    switch (productId) {
      case 'point_1000':
        pointsToGrant = 1000;
        break;
      case 'point_5500':
        pointsToGrant = 5500;
        break;
      case 'point_12000':
        pointsToGrant = 12000;
        break;
      default:
        print("Unknown ID: $productId");
        return;
    }

    // `_increasePoints` 메서드를 호출하여 포인트 증가 처리
    await _increasePoints(pointsToGrant);

    // 성공적인 포인트 지급 로그
    print("$pointsToGrant 포인트가 지급되었습니다 (상품 ID: $productId).");
  }


  Future<void> _fetchPoints() async {
    final response = await http.get(
        Uri.parse("${Login.url}/api/getPoints?user_id=${Login.userId}"));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        totalPoints = data['points'];
      });
    } else {
      print("포인트 정보를 가져오는 중 오류 발생: ${response.body}");
    }
  }

  Future<void> _increasePoints(int points) async {
    final response = await http.post(
      Uri.parse("${Login.url}/api/increase"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_id": Login.userId, "points": points}),
    );

    if (response.statusCode == 200) {
      setState(() {
        totalPoints += points;
      });
    } else {
      print("포인트 증가 중 오류 발생: ${response.body}");
    }
  }

  Future<void> _decreasePoints(int points) async {
    final response = await http.post(
      Uri.parse("${Login.url}/api/decrease"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_id": Login.userId, "points": points}),
    );

    if (response.statusCode == 200) {
      setState(() {
        totalPoints -= points;
      });
    } else {
      print("포인트 감소 중 오류 발생: ${response.body}");
    }
  }

  Future<void> _updateUserId() async {
    await _fetchPoints();
    if (totalPoints >= 1000) {
      final response = await http.post(
        Uri.parse("${Login.url}/api/updateUserId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": Login.userId,
          "new_user_id": _userIdController.text,
        }),
      );

      if (response.statusCode == 200) {
        print("아이디 변경 성공: ${response.body}");
        await _updateLocalUserId(_userIdController.text);
        setState(() {
          Login.userId = _userIdController.text;
          _userIdController.clear();
        });
        _decreasePoints(1000);
      } else if (response.statusCode == 409) {
        _showErrorDialog("Name already taken");
      } else {
        _showErrorDialog("Name change failed");
      }
    } else {
      _showErrorDialog("Not enough points");
    }
  }

  Future<void> _updateLocalUserId(String newUserId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', newUserId);
  }

  Future<void> _toggleFactoryActivation() async {
    if (isFactoryActive) {
      _deactivateFactory(4000);
    } else if (totalPoints >= 5000) {
      await _decreasePoints(5000);
      setState(() {
        isFactoryActive = true;
        factoryEndTime = DateTime.now().add(Duration(hours: 3));
      });
      _saveFactoryStatus();
    }
  }

  Future<void> _deactivateFactory(int pointsToReturn) async {
    await _increasePoints(pointsToReturn);
    setState(() {
      isFactoryActive = false;
      factoryEndTime = null;
    });
    _removeFactoryStatus();
  }

  Future<void> _saveFactoryStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFactoryActive', isFactoryActive);
    await prefs.setString(
        'factoryEndTime', factoryEndTime?.toIso8601String() ?? '');
  }

  Future<void> _loadFactoryStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? savedFactoryStatus = prefs.getBool('isFactoryActive');
    String? savedEndTimeString = prefs.getString('factoryEndTime');

    if (savedFactoryStatus == true && savedEndTimeString != null) {
      DateTime savedEndTime = DateTime.parse(savedEndTimeString);
      if (savedEndTime.isAfter(DateTime.now())) {
        setState(() {
          isFactoryActive = true;
          factoryEndTime = savedEndTime;
        });
      } else {
        _deactivateFactory(6000);
      }
    }
  }

  Future<void> _removeFactoryStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('isFactoryActive');
    await prefs.remove('factoryEndTime');
  }

  void _checkFactoryStatus() {
    if (isFactoryActive && factoryEndTime != null) {
      if (factoryEndTime!.isBefore(DateTime.now())) {
        _deactivateFactory(6000);
      } else {
        setState(() {});
      }
    }
  }

  String _formatFactoryEndTime() {
    if (factoryEndTime == null) return '';
    Duration remaining = factoryEndTime!.difference(DateTime.now());
    final hours = remaining.inHours.toString().padLeft(2, '0');
    final minutes = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "Time left for +6,000 P: $hours:$minutes:$seconds";
  }
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Ok"),
          ),
        ],
      ),
    );
  }
  @override
  void dispose() {
    refreshTimer?.cancel();
    InAppPurchase.instance.purchaseStream.drain(); // 리스너 해제
    super.dispose();
  }

  Widget _buildPointBox(String points, int increaseAmount, String imagePath, {String? bonus}) {
// `_products`가 비어 있는 경우 초기 처리
    if (_products.isEmpty) {
      print("상품 정보가 없습니다.");
      return SizedBox.shrink(); // 빈 위젯 반환
    }

    final product = _products.firstWhere(
          (p) => p.id == (increaseAmount == 1000
          ? "point_1000"
          : increaseAmount == 5500
          ? "point_5500"
          : "point_12000"),
      orElse: null, // orElse를 사용하지 않고 사전 체크를 활용
    );

// 상품이 없는 경우 처리
    if (product == null) {
      print("상품을 찾을 수 없습니다.");
      return SizedBox.shrink();
    }


    return GestureDetector(
      onTap: () => _buyProduct(product),
      child: Stack(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(10, 20, 10, 10),
            width: 150,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.lightBlue, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 0),
                Image.asset(imagePath, width: 80, height: 80),
                SizedBox(height: 5),
                Text(
                  points,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellow.shade900,
                  ),
                ),
                SizedBox(height: 0),
              ],
            ),
          ),
          if (bonus != null)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                  ),
                ),
                child: Text(
                  bonus,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.all(0),
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Text(
                  "$totalPoints P",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellow,
                  ),
                ),
                Text(
                  "Upgrade to Get More Points!",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "( Factory : Auto Points for every 3 Hour )",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Change Name",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _userIdController,
                        decoration: InputDecoration(
                          hintText: "${Login.userId}",
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: totalPoints >= 1000 ? _updateUserId : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        "Change (1,000 P)",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Get Points",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 160,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildPointBox(
                          "+1,000 P", 1000, "assets/money1.png"),
                      SizedBox(width: 16),
                      _buildPointBox(
                          "+5,500 P", 5500, "assets/money2.png",
                          bonus: "+10%"),
                      SizedBox(width: 16),
                      _buildPointBox(
                          "+12,000 P", 12000, "assets/money3.png",
                          bonus: "+20%"),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                "Factory(Auto Points)",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ColorFiltered(
                      colorFilter: isFactoryActive
                          ? ColorFilter.mode(
                          Colors.transparent, BlendMode.multiply)
                          : ColorFilter.mode(Colors.grey, BlendMode.saturation),
                      child: Image.asset("assets/factory.png",
                          width: MediaQuery
                              .of(context)
                              .size
                              .width - 40),
                    ),
                    Positioned(
                      child: ElevatedButton(
                        onPressed: isFactoryActive || totalPoints >= 5000 ? _toggleFactoryActivation : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isFactoryActive ? Colors.green : Colors.lightBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          isFactoryActive ? (factoryEndTime!.isAfter(DateTime.now()) ? "Get 4,000 P now.." : "Get 6,000 P !!") : "Active Factory (5000 P)",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                if (isFactoryActive)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      factoryEndTime!.isAfter(DateTime.now())
                          ? _formatFactoryEndTime()
                          : "You've got 6,000 P from Factory!",
                      style: TextStyle(fontSize: 16, color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
