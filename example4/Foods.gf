abstract Foods = {
  flags startcat = Comment;

  cat Comment;
  fun Pred : Item -> Quality -> Comment;

  cat Item;
  fun This, That, These, Those : Kind -> Item;

  cat Kind;
  fun Wine, Cheese, Fish, Pizza : Kind;
  fun Mod : Quality -> Kind -> Kind;

  cat Quality;
  fun Fresh, Warm, Cold, Italian, French, Expensive, Cheap, Delicious : Quality;
  fun Very : Quality -> Quality;
}
