import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  RewardedInterstitialAd? _rewardedInterstitialAd; // 보상형 전면 광고
  bool _isAdLoaded = false;
  bool _isButtonActive = true;
  String remainingTime = "00:00:00";
  Timer? _timer;
  int time_second = 20;



  @override
  void initState() {
    super.initState();
    _initializeProducts();
    _getPointValue(0);
    _loadRewardedInterstitialAd(); // 보상형 전면 광고 로드
    _checkCooltime(); // 쿨타임 확인
  }

  @override
  void dispose() {
    // 스트림 구독 해제
    if (_subscription != null) {
      _subscription!.cancel();
      _subscription = null;
    }
    _timer?.cancel();
    _rewardedInterstitialAd?.dispose();
    super.dispose();
  }


  Future<void> _getPointValue(n) async {
    final url = Uri.parse('${MyApp.url}/user/point');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': MyApp.user_id,
        'points': n
      }), //여기서의 points는 더해줄 값을 의미(0은 단순 포인트 조회)
    );

    if (response.statusCode == 200) {
      setState(() {
        points = int.parse(response.body);
      });
    }
  }

  Future<void> _initializeProducts() async {
    if (_products.isNotEmpty) return;

    final ProductDetailsResponse response =
    await _inAppPurchase.queryProductDetails(_productIds.toSet());
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
      final PurchaseParam purchaseParam = PurchaseParam(
          productDetails: productDetails);
      _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
    } else {
      print('Product not found: $productId');
    }
  }

  void _loadRewardedInterstitialAd() {
    RewardedInterstitialAd.load(
      //adUnitId: 'ca-app-pub-3940256099942544/5354046379', // 테스트 ID
      adUnitId: 'ca-app-pub-4725119578294745/9459280599', // 보상형 전면 광고 ID
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          setState(() {
            _rewardedInterstitialAd = ad;
            _isAdLoaded = true;
          });
          print('Rewarded Interstitial Ad loaded.');
        },
        onAdFailedToLoad: (error) {
          print('Failed to load rewarded interstitial ad: ${error.message}');
        },
      ),
    );
  }

  void _showRewardedInterstitialAd() {
    if (_rewardedInterstitialAd != null && _isAdLoaded) {
      _rewardedInterstitialAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          setState(() {
            points += reward.amount.toInt(); // 포인트 지급
          });
          _getPointValue(1000);
        },
      );
      // 광고 재로드
      _rewardedInterstitialAd = null;
      _isAdLoaded = false;
      _loadRewardedInterstitialAd();
    } else {
      print('Rewarded interstitial ad is not ready yet');
    }
  }

  Future<void> _onFreePointsClicked() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int newCooltime = DateTime.now().millisecondsSinceEpoch + time_second * 1000; // 30분 후
    await prefs.setInt('cooltime', newCooltime);

    _showRewardedInterstitialAd(); // 보상형 전면 광고 표시
    setState(() {
      _isButtonActive = false;
    });

    _startTimer(time_second * 1000); // 30분 타이머 시작
  }


  // 쿨타임 확인 및 버튼 상태 관리
  Future<void> _checkCooltime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? cooltime = prefs.getInt('cooltime');

    if (cooltime == null) {
      // 쿨타임이 없으면 버튼 활성화
      setState(() {
        _isButtonActive = true;
        remainingTime = "00:00:00";
      });
    } else {
      // 현재 시간과 쿨타임의 차이 계산
      int currentTime = DateTime.now().millisecondsSinceEpoch;
      int diff = (cooltime - currentTime);

      if (diff > 0) {
        // 쿨타임이 남아 있으면 버튼 비활성화
        setState(() {
          _isButtonActive = false;
        });
        _startTimer(diff);
      } else {
        // 쿨타임이 끝났으면 버튼 활성화
        prefs.remove('cooltime');
        setState(() {
          _isButtonActive = true;
          remainingTime = "00:00:00";
        });
      }
    }
  }

  // 타이머 시작 (1초 단위로 남은 시간 업데이트)
  void _startTimer(int diff) {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) async {
      int remainingMillis = diff - timer.tick * 1000;
      if (remainingMillis <= 0) {
        timer.cancel();
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.remove('cooltime');
        setState(() {
          _isButtonActive = true;
          remainingTime = "00:00:00";
        });
      } else {
        setState(() {
          int seconds = (remainingMillis ~/ 1000) % 60;
          int minutes = (remainingMillis ~/ 60000) % 60;
          int hours = (remainingMillis ~/ 3600000);
          remainingTime = "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
        });
      }
    });
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
                        lang('상점'),
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
                          title: lang('코인 구매'),
                          child: _buildPaidPointsSection(),
                        ),
                        SizedBox(height: 20),
                        _buildSection(
                          title: lang('코인 무료 충전'),
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
    return Center(
      child: SizedBox(
        width: 160, // 버튼의 고정 너비
        height: 50, // 버튼의 고정 높이
        child: ElevatedButton(
          onPressed: _isButtonActive ? _onFreePointsClicked : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.yellow.shade800,
            disabledBackgroundColor: Colors.grey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10), // 모서리 반경 조정
            ),
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          ),
          child: _isButtonActive
              ? Row(
            mainAxisSize: MainAxisSize.min, // 내용 크기에 맞춤
            children: [
              Text(
                '+1,000 ',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Image.asset(
                'assets/UI/coin.png', // 코인 이미지 경로
                height: 40, // 이미지 크기
              ),
            ],
          )
              : Text(
            remainingTime, // 버튼 비활성화 시 남은 시간 표시
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ),
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

String lang(String textKey) {
  final localizedTexts = {
    'KOR': {
      '상점': '상점',
      '코인 구매': '코인 구매',
      '코인 무료 충전': '코인 무료 충전',
      '시간': '시간',
    },
    'ENG': {
      '상점': 'Shop',
      '코인 구매': 'Buy Coins',
      '코인 무료 충전': 'Free Coin Charge',
      '시간': 'Time',
    },
    'ARA': {
      '상점': 'متجر',
      '코인 구매': 'شراء العملات',
      '코인 무료 충전': 'شحن العملات المجاني',
      '시간': 'الوقت',
    },
    'CHN': {
      '상점': '商店',
      '코인 구매': '购买金币',
      '코인 무료 충전': '免费金币充电',
      '시간': '时间',
    },
    'JPA': {
      '상점': 'ショップ',
      '코인 구매': 'コイン購入',
      '코인 무료 충전': 'コイン無料チャージ',
      '시간': '時間',
    },
    'GER': {
      '상점': 'Laden',
      '코인 구매': 'Münzen kaufen',
      '코인 무료 충전': 'Kostenlose Münzaufladung',
      '시간': 'Zeit',
    },
    'RUS': {
      '상점': 'Магазин',
      '코인 구매': 'Покупка монет',
      '코인 무료 충전': 'Бесплатная зарядка монет',
      '시간': 'Время',
    },
    'FRA': {
      '상점': 'Magasin',
      '코인 구매': 'Acheter des pièces',
      '코인 무료 충전': 'Recharge gratuite de pièces',
      '시간': 'Temps',
    },
    'ESP': {
      '상점': 'Tienda',
      '코인 구매': 'Comprar monedas',
      '코인 무료 충전': 'Recarga gratuita de monedas',
      '시간': 'Tiempo',
    },
  };

  return localizedTexts[MyApp.currentLanguage]?[textKey] ?? textKey;
}