-- (c) 2009 Aarne Ranta under LGPL

concrete FoodsEng of Foods = {
  flags language = en_US;
  lincat
    Comment, Quality = {s : Str} ;
    Kind = {s : Number => Str} ;
    Item = {s : Str ; n : Number} ;
  lin
    Pred item quality =
      {s = item.s ++ copula ! item.n ++ quality.s} ;
    This  = det Sg "this" ;
    That  = det Sg "that" ;
    These = det Pl "these" ;
    Those = det Pl "those" ;
    Mod quality kind =
      {s = \\n => quality.s ++ kind.s ! n} ;
    Wine = regNoun "wine" ;
    Cheese = regNoun "cheese" ;
    Fish = noun "fish" "fish" ;
    Pizza = regNoun "pizza" ;
    Very a = {s = "very" ++ a.s} ;
    Fresh = adj "fresh" ;
    Warm = adj "warm" ;
    Cold = adj "cold" ;
    Italian = adj "Italian" ;
    French = adj "French" ;
    Expensive = adj "expensive" ;
    Cheap = adj "cheap" ;
    Delicious = adj "delicious" ;
  param
    Number = Sg | Pl ;
  oper
    det : Number -> Str ->
      {s : Number => Str} -> {s : Str ; n : Number} =
        \n,det,noun -> {s = det ++ noun.s ! n ; n = n} ;
    noun : Str -> Str -> {s : Number => Str} =
      \man,men -> {s = table {Sg => man ; Pl => men}} ;
    regNoun : Str -> {s : Number => Str} =
      \car -> noun car (car + "s") ;
    adj : Str -> {s : Str} =
      \cold -> {s = cold} ;
    copula : Number => Str =
      table {Sg => "is" ; Pl => "are"} ;
}
