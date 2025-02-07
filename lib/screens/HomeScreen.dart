import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:saborine/models/recipets.dart';
import 'package:saborine/screens/favorites_screen.dart';
import 'package:saborine/screens/receitas.dart';
import 'package:saborine/screens/recipe_detail_screen.dart';
import 'package:saborine/screens/buyscreen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Recipe> allRecipes = getExampleRecipes();
  String selectedCategory = 'Todos';
  String searchQuery = '';
  late BannerAd _bannerAd;
  bool _isBannerAdLoaded = false;
  InterstitialAd? _interstitialAd;
  bool _isAdRemoved = false;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  int _selectedIndex = 0;
  bool isSearch = false; // Controlador para pesquisa na AppBar
  TextEditingController _searchController = TextEditingController();

  List<String> categories = ['Todos', 'Doces', 'Salgados', 'Vegetariano', 'Vegan'];

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    _loadInterstitialAd();
    _initializeInAppPurchase();
    _searchController.addListener(() {
      setState(() {
        searchQuery = _searchController.text;
      });
    });
  }

  void _initializeInAppPurchase() {
    _subscription = InAppPurchase.instance.purchaseStream.listen((purchases) {
      _processPurchase(purchases);
    });
  }

  void _processPurchase(List<PurchaseDetails> purchases) {
    for (var purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased) {
        if (purchase.productID == 'remove_ads') {
          setState(() {
            _isAdRemoved = true;
          });
        }
      }
    }
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-1251208414172228/7442175667',
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isBannerAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          print('Falha ao carregar o BannerAd: $error');
        },
      ),
    );
    _bannerAd.load();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-1251208414172228/4014609111',
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          setState(() {
            _interstitialAd = ad;
          });
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('Falha ao carregar o InterstitialAd: $error');
        },
      ),
    );
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void dispose() {
    _bannerAd.dispose();
    _interstitialAd?.dispose();
    _subscription.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 1:
        return FavoritesScreen();
      case 2:
        return BuyScreen();
      default:
        return _buildHomeScreen();
    }
  }

  Widget _buildHomeScreen() {
    // Filtragem das receitas com base no nome e na categoria
    List<Recipe> filteredRecipes = allRecipes.where((recipe) {
      final matchesCategory = selectedCategory == 'Todos' || recipe.category == selectedCategory;
      final matchesSearchQuery = recipe.title.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCategory && matchesSearchQuery;
    }).toList();

    return Column(
      children: [
        // Exibição do banner de anúncios, se necessário
        if (_isBannerAdLoaded && !_isAdRemoved)
          Container(
            alignment: Alignment.center,
            margin: EdgeInsets.symmetric(vertical: 10),
            child: AdWidget(ad: _bannerAd),
            height: 50,
          ),
        // Exibição das receitas filtradas em uma GridView
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.all(10),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: filteredRecipes.length,
            itemBuilder: (context, index) {
              final recipe = filteredRecipes[index];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 5,
                child: InkWell(
                  onTap: () async {
                    // Mostrar o anúncio intersticial se ele estiver carregado
                    if (_interstitialAd != null) {
                      await _interstitialAd!.show();
                      setState(() {
                        _interstitialAd = null; // Limpa o interstitial após mostrar
                      });
                      _loadInterstitialAd(); // Carrega um novo anúncio
                    }

                    // Navegar para a tela de detalhes da receita
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RecipeDetailScreen(recipe: recipe)),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Image.network(recipe.imageUrl, fit: BoxFit.cover, width: double.infinity),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          recipe.title,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.orange,
            ),
            child: Text(
              'Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            title: Text('Remover Anúncios'),
            onTap: () {
              _purchaseRemoveAds();
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('Filtrar por Categoria'),
            onTap: () async {
              final selectedCategory = await showDialog<String>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text('Selecione a Categoria'),
                    content: SingleChildScrollView(
                      child: Column(
                        children: categories.map((category) {
                          return ListTile(
                            title: Text(category),
                            onTap: () {
                              Navigator.pop(context, category);
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              );

              if (selectedCategory != null) {
                setState(() {
                  this.selectedCategory = selectedCategory;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  void _purchaseRemoveAds() async {
    final ProductDetailsResponse response = await InAppPurchase.instance.queryProductDetails({'remove_ads'});

    if (response.notFoundIDs.isEmpty) {
      final product = response.productDetails.first;
      final purchaseParam = PurchaseParam(productDetails: product);
      await InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(hintText: 'Pesquise por receita'),
              )
            : Text('Receitas Saborine'),
        actions: [
          IconButton(
            icon: Icon(isSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                isSearch = !isSearch;
                if (!isSearch) {
                  _searchController.clear();
                }
              });
            },
          ),
        ],
        backgroundColor: Colors.orange,
      ),
      drawer: _buildDrawer(),
      body: _getSelectedScreen(),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Início'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favoritos'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Compras'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onTabSelected,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}
