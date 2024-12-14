import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import '../main.dart';
import 'package:http/http.dart' as http;

import 'MainPage.dart';

class Shop extends StatefulWidget {
  @override
  _ShopPageState createState() => _ShopPageState();
}

class _ShopPageState extends State<Shop> {
  int points = 0;
  bool _isButtonActive = true;
  String remainingTime = "00:00:00";
  Timer? _timer;
  int time_second = 1800;

  //광고 변수
  RewardedInterstitialAd? _rewardedInterstitialAd;
  bool _isAdLoaded = false; // 광고 로드 상태(로드 안됐는데도 버튼 눌리기 방지용)

  //인앱결제 변수
  final List<String> _productIds = ['point2_1000', 'point_6000', 'point_12000'];
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  List<ProductDetails> _products = [];

  @override
  void initState() {
    super.initState();
    _loadRewardedAd();
    _initializeInAppPurchase();
    _inAppPurchase.purchaseStream.listen((purchases) {
      for (final purchase in purchases) {
        if (purchase.status == PurchaseStatus.purchased) {
          // 구매 완료 시 포인트 추가
          _handlePurchase(purchase.productID);
          _inAppPurchase.completePurchase(purchase); // 구매 완료 처리
        } else if (purchase.status == PurchaseStatus.error) {
          print('Purchase error: ${purchase.error}');
        }
      }
    });
    _initializePage(); // 순차적으로 실행하도록 별도 메서드 호출
  }

  Future<void> _initializePage() async {
    await _checkCooltime(); // 쿨타임 확인
    await _getPointValue(0);
  }

  @override
  void dispose() {
    MyApp.bgmPlayer.resume();
    _timer?.cancel();
    _rewardedInterstitialAd?.dispose(); // 광고 객체 해제
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

  Future<void> _initializeInAppPurchase() async {
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) {
      print('In-app purchases are not available.');
      return;
    }

    final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(_productIds.toSet());
    if (response.error == null) {
      setState(() {
        _products = response.productDetails;
      });
    } else {
      print('Error fetching product details: ${response.error}');
    }
  }
  void _buyProduct(ProductDetails product) {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    _inAppPurchase.buyConsumable(purchaseParam: purchaseParam, autoConsume: true);
  }
  void _handlePurchase(String productId) {
    int pointsToAdd = 0;
    if (productId == 'point_1000') {
      pointsToAdd = 1000;
    } else if (productId == 'point_6000') {
      pointsToAdd = 6000;
    } else if (productId == 'point_12000') {
      pointsToAdd = 12000;
    }
    _getPointValue(pointsToAdd); // 백엔드에 포인트 추가 요청
  }


  void _loadRewardedAd() {
    RewardedInterstitialAd.load(
      //adUnitId: 'ca-app-pub-3940256099942544/5354046379', // 테스트 ID
      adUnitId: 'ca-app-pub-4725119578294745/9459280599', // 보상형 전면 광고 ID
      request: AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          setState(() {
            _rewardedInterstitialAd = ad;
            _isAdLoaded = true; // 광고 로드 완료
          });
        },
        onAdFailedToLoad: (error) {
          print('Rewarded Interstitial Ad failed to load: $error');
          setState(() {
            _isAdLoaded = false; // 광고 로드 실패
          });
        },
      ),
    );
  }
  Future<void> _onFreePointsClicked() async {
    if (!_isAdLoaded) {
      print('Ad is not loaded yet.');
      return; // 광고가 로드되지 않은 경우 버튼이 반응하지 않음
    }

    MyApp.bgmPlayer.pause();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int newCooltime = DateTime.now().millisecondsSinceEpoch + time_second * 1000; // 30분 후
    await prefs.setInt('cooltime', newCooltime);

    setState(() {
      _isButtonActive = false;
      _isAdLoaded = false; // 광고가 사용된 후 다시 로드 필요
    });

    _startTimer(time_second * 1000); // 30분 타이머 시작

    //광고 실행
    if (_rewardedInterstitialAd != null) {
      _rewardedInterstitialAd!.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
        await _getPointValue(1000); // 포인트 업데이트
        SharedPreferences prefs = await SharedPreferences.getInstance();
        int newCooltime = DateTime.now().millisecondsSinceEpoch + time_second * 1000; // 쿨타임 설정
        await prefs.setInt('cooltime', newCooltime);

        setState(() {
          _isButtonActive = false;
        });

        MyApp.bgmPlayer.resume(); // 광고 종료 후 BGM 재개
        _startTimer(time_second * 1000); // 타이머 시작
      });

      // 광고가 끝난 후 새 광고 로드
      _loadRewardedAd();
    }
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

  String formatWithComma(int number) {
    return NumberFormat('#,###').format(number);
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
              image: AssetImage('assets/Theme/${MyApp.currentTheme}.png'),
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
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => Shop()),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5), // 반투명 검은색
                            borderRadius: BorderRadius.circular(20), // 모서리 둥글게
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 0), // 내부 여백
                          child: Row(
                            mainAxisSize: MainAxisSize.min, // 내용에 맞게 크기 조정
                            children: [
                              Image.asset(
                                'assets/UI/coin.png',
                                height: 50, // 아이콘 크기 설정
                              ),
                              SizedBox(width: 5), // 아이콘과 텍스트 간격
                              Text(
                                '${formatWithComma(points)}',
                                style: TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.amberAccent, // 금색 강조
                                  shadows: [
                                    Shadow(blurRadius: 4, color: Colors.black38, offset: Offset(2, 2))
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
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
                          title: lang('코인 획득 - [ Ad ]'),
                          child: _buildFreePointsSection(),
                        ),
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
      padding: EdgeInsets.fromLTRB(16, 16, 16, 24), // 좌, 상, 우, 하 순서
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
            // 인앱 상품 구매
            final product = _products.firstWhere((p) => p.id == productId);
            if (product != null) {
              _buyProduct(product);
            } else {
              print('Product not found: $productId');
            }
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 110,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Color(0xFFD4AF37), width: 3), // 금색 테두리
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      imagePath, // 이미지 경로 추가
                      width: 90, // 이미지 너비
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10), // 금색 테두리 박스와 가격 간격
              Row(
                mainAxisAlignment: MainAxisAlignment.center, // 가로 정렬: 중앙
                children: [
                  Text(
                    points,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.amberAccent, // 금색 강조
                      shadows: [
                        Shadow(blurRadius: 4, color: Colors.black38, offset: Offset(2, 2))
                      ],
                    ),
                  ),
                  Image.asset(
                    'assets/UI/coin.png', // 코인 이미지 경로
                    height: 30, // 이미지 크기
                  ),
                ],
              ),
            ],
          ),
        ),
        if (label != null)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.5, vertical: 1.5),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              label,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
            backgroundColor: Colors.green,
            disabledBackgroundColor: Colors.grey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10), // 모서리 반경 조정
            ),
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          ),
          child: _isButtonActive
              ? Row(
            mainAxisAlignment: MainAxisAlignment.center, // 가로 정렬: 중앙
            children: [
              Text(
                "+1,000",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.amberAccent, // 금색 강조
                  shadows: [
                    Shadow(blurRadius: 4, color: Colors.black38, offset: Offset(2, 2))
                  ],
                ),
              ),
              SizedBox(width: 8), // 텍스트와 아이콘 사이 간격
              Icon(
                Icons.video_library, // 광고를 암시하는 아이콘
                color: Colors.orange, // 강조 색상
                size: 22, // 아이콘 크기
              ),
              // Image.asset(
              //   'assets/UI/coin.png', // 코인 이미지 경로
              //   height: 33, // 이미지 크기
              // ),
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