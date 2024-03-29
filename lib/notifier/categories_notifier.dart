import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:hostess/model/categories.dart';

class CategoriesNotifier with ChangeNotifier {
  List<Categories> _categoriesList = [];

  UnmodifiableListView<Categories> get categoriesList =>
      UnmodifiableListView(_categoriesList);

  set categoriesList(List<Categories> categoriesList) {
    _categoriesList = categoriesList;
    notifyListeners();
  }
}
