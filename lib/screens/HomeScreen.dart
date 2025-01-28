import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:saborine/screens/receitas.dart'; 
import 'package:in_app_purchase/in_app_purchase.dart';
import '../models/recipets.dart';
import 'recipe_detail_screen.dart';

// ignore: use_key_in_widget_constructors
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
  bool _isAdRemoved = false; // Flag para verificar se o anúncio foi removido
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    _loadInterstitialAd();
    _initializeInAppPurchase();
  }

  void _initializeInAppPurchase() {
    // Inicializar compras dentro do app
    _subscription = InAppPurchase.instance.purchaseStream.listen((purchases) {
      _processPurchase(purchases);
    });
  }

  void _processPurchase(List<PurchaseDetails> purchases) {
    for (var purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased) {
        if (purchase.productID == 'remove_ads') {
          setState(() {
            _isAdRemoved = true; // Marca que o anúncio foi removido
          });
        }
      } else if (purchase.status == PurchaseStatus.error) {
        // Tratar erro de compra, por exemplo, exibir uma mensagem de erro
        print('Erro na compra: ${purchase.error?.message}');
      }
    }
  }

  Future<void> _buyRemoveAds() async {
    final ProductDetailsResponse response = await InAppPurchase.instance.queryProductDetails({'remove_ads'}.toSet());
    if (response.productDetails.isNotEmpty) {
      final ProductDetails productDetails = response.productDetails.first;
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
      try {
        await InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);
      } catch (e) {
        print('Erro na compra: $e');
      }
    } else {
      print('Produto não encontrado');
    }
  }

  void _loadBannerAd() {
    if (_isAdRemoved) return; // Não carrega anúncios se o usuário comprou a remoção

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
          print('Falha ao carregar o banner: $error');
        },
      ),
    );
    _bannerAd.load();
  }

  void _loadInterstitialAd() {
    if (_isAdRemoved) return; // Não carrega o intersticial se o usuário comprou a remoção

    InterstitialAd.load(
      adUnitId: 'ca-app-pub-1251208414172228/4014609111',
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          print('Falha ao carregar o anúncio intersticial: $error');
        },
      ),
    );
  }

  void _showInterstitialAd() {
    if (_interstitialAd != null && !_isAdRemoved) {
      _interstitialAd!.show();
      _loadInterstitialAd(); // Carrega um novo anúncio intersticial para a próxima vez
    }
  }

  @override
  void dispose() {
    _bannerAd.dispose();
    _subscription.cancel(); // Cancelar a assinatura do stream de compras
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Filtra as receitas conforme o título e a categoria selecionada
    List<Recipe> filteredRecipes = allRecipes.where((recipe) {
      final matchesCategory =
          selectedCategory == 'Todos' || recipe.category == selectedCategory;
      final matchesSearchQuery =
          recipe.title.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCategory && matchesSearchQuery;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Receitas saborine'),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: RecipeSearchDelegate(allRecipes),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 249, 125, 0),
              ),
              child: Text(
                'Categorias',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              title: Text('Todos'),
              onTap: () {
                setState(() {
                  selectedCategory = 'Todos';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Sobremesas'),
              onTap: () {
                setState(() {
                  selectedCategory = 'Sobremesas';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Pratos Principais'),
              onTap: () {
                setState(() {
                  selectedCategory = 'Pratos Principais';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Salgados'),
              onTap: () {
                setState(() {
                  selectedCategory = 'Salgados';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Remover Anúncios'),
              onTap: () async {
                await _buyRemoveAds();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (_isBannerAdLoaded && !_isAdRemoved)
              Container(
                alignment: Alignment.center,
                margin: EdgeInsets.symmetric(vertical: 10),
                child: AdWidget(ad: _bannerAd),
                height: 50,
              ),
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: filteredRecipes.length,
              itemBuilder: (context, index) {
                final recipe = filteredRecipes[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 5,
                  child: InkWell(
                    onTap: () {
                      _showInterstitialAd();  // Exibe o anúncio intersticial
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              RecipeDetailScreen(recipe: recipe),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Image.network(
                            recipe.imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            recipe.title,
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
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
          ],
        ),
      ),
    );
  }
}

class RecipeSearchDelegate extends SearchDelegate {
  final List<Recipe> recipes;

  RecipeSearchDelegate(this.recipes);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = recipes.where((recipe) {
      return recipe.title.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final recipe = results[index];
        return ListTile(
          title: Text(recipe.title),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RecipeDetailScreen(recipe: recipe),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = recipes.where((recipe) {
      return recipe.title.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final recipe = suggestions[index];
        return ListTile(
          title: Text(recipe.title),
          onTap: () {
            query = recipe.title;
            showResults(context);
          },
        );
      },
    );
  }
}
