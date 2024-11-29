import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../main.dart';
import 'package:http/http.dart' as http;

import 'MainPage.dart';

class Shop extends StatefulWidget {
  @override
  _ShopPageState createState() => _ShopPageState();
}

class _ShopPageState extends State<Shop> {
  int points = 0;
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final List<String> _productIds = ['point_1000', 'point_6000', 'point_12000'];
  Map<String, ProductDetails> _products = {};
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = _inAppPurchase.purchaseStream.listen(
          (List<PurchaseDetails> purchases) {
        for (var purchase in purchases) {
          if (purchase.status == PurchaseStatus.purchased) {
            _handlePurchaseSuccess(purchase);
          } else if (purchase.status == PurchaseStatus.error) {
            _handlePurchaseError(purchase);
          }
        }
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel(); // 구독 해제
    super.dispose();
  }


  Future<void> _getPointValue() async {
    final url = Uri.parse('${MyApp.url}/user/point');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': MyApp.user_id,
        'points': 0
      }), //여기서의 points는 더해줄 값을 의미(0은 단순 포인트 조회)
    );

    if (response.statusCode == 200) {
      setState(() {
        points = int.parse(response.body);
      });
    }
  }

  Future<void> _initializeProducts() async {
    final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(_productIds.toSet());
    if (response.notFoundIDs.isNotEmpty) {
      print('Some products were not found: ${response.notFoundIDs}');
    }
    setState(() {
      _products = {for (var product in response.productDetails) product.id: product};
    });
  }

  Future<void> _purchaseProduct(String productId) async {
    final ProductDetails? productDetails = _products[productId];
    if (productDetails != null) {
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
      _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
    } else {
      print('Product not found: $productId');
    }
  }

  void _handlePurchaseSuccess(PurchaseDetails purchase) {
    // 포인트 추가 로직
    print('Purchase successful: ${purchase.productID}');
    if (purchase.productID == 'point_1000') {
      setState(() {
        points += 1000;
      });
    } else if (purchase.productID == 'point_5500') {
      setState(() {
        points += 6000;
      });
    } else if (purchase.productID == 'point_12000') {
      setState(() {
        points += 12000;
      });
    }
  }

  void _handlePurchaseError(PurchaseDetails purchase) {
    print('Purchase error: ${purchase.error?.message}');
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // 뒤로 가기 키 막기
        return false;
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/Theme/cat.png'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.5), BlendMode.darken),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(0.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 40.0, bottom: 15.0, right: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 뒤로 가기 버튼
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: Color(0xFFB8860B), // 어두운 황금색
                          size: 40, // 아이콘 크기 (원하는 크기로 설정)
                        ),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MainPage(),
                            ),
                          );
                        },
                      ),
                      // 내 정보 제목
                      Text(
                        '상점',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD4AF37),
                          shadows: [
                            Shadow(
                              blurRadius: 10,
                              color: Colors.black54,
                              offset: Offset(4, 4),
                            ),
                          ],
                        ),
                      ),
                      // 코인 아이콘과 포인트 표시
                      Row(
                        children: [
                          Image.asset(
                            'assets/UI/coin.png',
                            height: 50, // 코인 아이콘 크기
                          ),
                          SizedBox(width: 5),
                          Text(
                            '$points',
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w600,
                              color: Colors.amberAccent,
                              shadows: [
                                Shadow(
                                  blurRadius: 4,
                                  color: Colors.black38,
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: 150), //임시로 아이템, 테마상점 생기기 전까지 중앙배치
                        SizedBox(height: 20),
                        _buildSection(
                          title: '코인 구매',
                          child: _buildPaidPointsSection(),
                        ),
                        SizedBox(height: 20),
                        _buildSection(
                          title: '코인 무료 충전',
                          child: _buildFreePointsSection(),
                        ),
                        // SizedBox(height: 20),
                        // _buildSection(
                        //   title: '테마 구매',
                        //   child: _buildThemePurchaseSection(),
                        // ),
                        // SizedBox(height: 20),
                        // _buildSection(
                        //   title: '아이템 구매',
                        //   child: _buildItemPurchaseSection(),
                        // ),
                        // SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  // 구분선 스타일 섹션 생성
  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Color(0xFFD4AF37), width: 1.5), // 금색 테두리
        boxShadow: [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 6,
            offset: Offset(2, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
  // 1. 포인트 유료 구매
  Widget _buildPaidPointsSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildPointPurchaseButton("+1,000", 'point_1000', imagePath: 'assets/UI/Cash/money1.png'),
        _buildPointPurchaseButton("+6,000", 'point_6000', label: "+10%", imagePath: 'assets/UI/Cash/money2.png'),
        _buildPointPurchaseButton("+12,000", 'point_12000', label: "+20%", imagePath: 'assets/UI/Cash/money3.png'),
      ],
    );
  }
  Widget _buildPointPurchaseButton(String points, String productId, {String? label, required String imagePath}) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        GestureDetector(
          onTap: () {
            _purchaseProduct(productId); // 결제 함수 호출
          },
          child: Container(
            width: 110,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Color(0xFFD4AF37), width: 1.5), // 금색 테두리
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  imagePath, // 이미지 경로 추가
                  width: 80, // 이미지 너비
                ),
                Text(
                  points,
                  style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        if (label != null)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              label,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
      ],
    );
  }



  // 2. 포인트 무료 충전
  Widget _buildFreePointsSection() {
    return Row(
      children: [
        Text(
          '남은 시간: 00:00:00',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        Spacer(),
        ElevatedButton(
          onPressed: "123" == "00:00:00" ? () {} : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amberAccent,
            disabledBackgroundColor: Colors.grey,
          ),
          child: Text('포인트 받기!'),
        ),
      ],
    );
  }

  // 3. 테마 구매
  Widget _buildThemePurchaseSection() {
    return Row(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Color(0xFFD4AF37), width: 1.5), // 금색 테두리
          ),
          child: Image.asset('assets/Theme/forest_friends.png', fit: BoxFit.cover),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '숲속 친구들 테마',
                style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 5),
              Text(
                '귀여운 동물들이 등장하는 숲속 테마입니다. 사슴, 다람쥐, 고슴도치 등이 포함됩니다.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '구매 00:00:00',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  ElevatedButton(
                    onPressed: () {}, // 구매 버튼
                    child: Text('구매'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 4. 아이템 구매
  Widget _buildItemPurchaseSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildItemCard("판사 봉", "x5", 'assets/Item/judge_baton.png'),
        _buildItemCard("방탄복", "x3", 'assets/Item/bulletproof.png'),
        _buildItemCard("정치적 연설", "x10", 'assets/Item/political_speach.png'),
      ],
    );
  }

  Widget _buildItemCard(String name, String quantity, String imagePath) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Color(0xFFD4AF37), width: 1.5), // 금색 테두리
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(imagePath, width: 40, height: 40, fit: BoxFit.cover),
          SizedBox(height: 5),
          Text(name, style: TextStyle(color: Colors.white, fontSize: 14)),
          SizedBox(height: 5),
          Text(quantity, style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

}
