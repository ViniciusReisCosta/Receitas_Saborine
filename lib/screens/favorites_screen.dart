import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recipets.dart';
import 'receitas.dart'; // Importação do arquivo receita.dart
import 'recipe_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late SharedPreferences _prefs;
  List<Recipe> _favoriteRecipes = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    _prefs = await SharedPreferences.getInstance();
    List<String> favoriteTitles = _prefs.getStringList('favoriteRecipes') ?? [];

    // Alteração aqui
    List<Recipe> allRecipes = getExampleRecipes();

    setState(() {
      _favoriteRecipes = allRecipes
          .where((recipe) => favoriteTitles.contains(recipe.title))
          .toList();
    });
  }

  void _navigateToRecipeDetail(Recipe recipe) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailScreen(recipe: recipe),
      ),
    );
    _loadFavorites(); // Atualiza a lista ao voltar
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: _favoriteRecipes.isEmpty
          ? Center(child: Text('Nenhuma receita favoritada ainda.'))
          : ListView.builder(
              itemCount: _favoriteRecipes.length,
              itemBuilder: (context, index) {
                final recipe = _favoriteRecipes[index];
                return ListTile(
                  leading: Image.network(recipe.imageUrl, width: 50, height: 50, fit: BoxFit.cover),
                  title: Text(recipe.title),
                  subtitle: Text(recipe.description),
                  trailing: Icon(Icons.favorite, color: Colors.red),
                  onTap: () => _navigateToRecipeDetail(recipe),
                );
              },
            ),
    );
  }
}
