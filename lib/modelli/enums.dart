enum Allergen {
  cerealsContainingGluten,
  crustaceans,
  eggs,
  fish,
  peanuts,
  soybeans,
  milk,
  nuts,
  celery,
  mustard,
  sesameSeeds,
  sulphurDioxideAndSulphites,
  lupin,
  molluscs;

  String get displayName {
    switch (this) {
      case Allergen.cerealsContainingGluten:
        return 'Cereali contenenti glutine';
      case Allergen.crustaceans:
        return 'Crostacei';
      case Allergen.eggs:
        return 'Uova';
      case Allergen.fish:
        return 'Pesce';
      case Allergen.peanuts:
        return 'Arachidi';
      case Allergen.soybeans:
        return 'Soia';
      case Allergen.milk:
        return 'Latte';
      case Allergen.nuts:
        return 'Frutta a guscio';
      case Allergen.celery:
        return 'Sedano';
      case Allergen.mustard:
        return 'Senape';
      case Allergen.sesameSeeds:
        return 'Semi di sesamo';
      case Allergen.sulphurDioxideAndSulphites:
        return 'Anidride solforosa e solfiti';
      case Allergen.lupin:
        return 'Lupino';
      case Allergen.molluscs:
        return 'Molluschi';
    }
  }

  String get englishName {
    switch (this) {
      case Allergen.cerealsContainingGluten:
        return 'cereals_containing_gluten';
      case Allergen.crustaceans:
        return 'crustaceans';
      case Allergen.eggs:
        return 'eggs';
      case Allergen.fish:
        return 'fish';
      case Allergen.peanuts:
        return 'peanuts';
      case Allergen.soybeans:
        return 'soybeans';
      case Allergen.milk:
        return 'milk';
      case Allergen.nuts:
        return 'nuts';
      case Allergen.celery:
        return 'celery';
      case Allergen.mustard:
        return 'mustard';
      case Allergen.sesameSeeds:
        return 'sesame_seeds';
      case Allergen.sulphurDioxideAndSulphites:
        return 'sulphur_dioxide_and_sulphites';
      case Allergen.lupin:
        return 'lupin';
      case Allergen.molluscs:
        return 'molluscs';
    }
  }
}
