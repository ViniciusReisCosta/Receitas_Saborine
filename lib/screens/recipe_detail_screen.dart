import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recipets.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  RecipeDetailScreen({required this.recipe});

  @override
  _RecipeDetailScreenState createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late BannerAd _bannerAd;
  bool _isBannerAdLoaded = false;
  bool _isFavorite = false;
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    _loadFavorites();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-1251208414172228/7442175667',
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          print('Falha ao carregar o anúncio: $error');
        },
      ),
    );
    _bannerAd.load();
  }

  Future<void> _loadFavorites() async {
    _prefs = await SharedPreferences.getInstance();
    List<String> favoriteRecipes = _prefs.getStringList('favoriteRecipes') ?? [];
    setState(() {
      _isFavorite = favoriteRecipes.contains(widget.recipe.title);
    });
  }

  Future<void> _toggleFavorite() async {
    List<String> favoriteRecipes = _prefs.getStringList('favoriteRecipes') ?? [];
    setState(() {
      if (_isFavorite) {
        favoriteRecipes.remove(widget.recipe.title);
      } else {
        favoriteRecipes.add(widget.recipe.title);
      }
      _isFavorite = !_isFavorite;
    });
    await _prefs.setStringList('favoriteRecipes', favoriteRecipes);
  }

  @override
  void dispose() {
    _bannerAd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe.title),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : Colors.white,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 1.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: screenWidth,
                  height: screenHeight * 0.35,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(widget.recipe.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Descrição',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  widget.recipe.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Ingredientes',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: widget.recipe.ingredients.length,
                  itemBuilder: (context, index) {
                    String ingredient = widget.recipe.ingredients[index];
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        ingredient,
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  },
                ),
                SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Modo de Preparo',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 8),
                for (var step in widget.recipe.steps)
                  Padding(
                    padding: const EdgeInsets.all(9.0),
                    child: Text(
                      '- $step',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                SizedBox(height: 16),
                // Adicionando o anúncio de banner
                if (_isBannerAdLoaded)
                  Container(
                    alignment: Alignment.center,
                    child: AdWidget(ad: _bannerAd),
                    width: _bannerAd.size.width.toDouble(),
                    height: _bannerAd.size.height.toDouble(),
                  ),
                SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
