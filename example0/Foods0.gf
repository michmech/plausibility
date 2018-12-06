concrete Foods0 of Foods = open Predef in {
  param Plausibility = Plausible | Implausible;

  -- cat Comment;
  lincat Comment = {s : Str};

  -- fun Pred : Item -> Quality -> Comment;
  lin Pred item quality = {
    s = case plausibility of {
      Plausible => "ok";
      Implausible => "notok"
    }
  } where {
    -- if both the item and the quality are plausible, then the comment we are creating can also be plausible:
    plausibility = case <item.plausibility, quality.plausibility> of {
      <Plausible, Plausible> => Plausible;
      <_,_> => Implausible
    }
  };


  -- cat Item;
  lincat Item = {plausibility : Plausibility};

  -- fun This, That, These, Those : Kind -> Item;
  lin This kind = {plausibility = kind.plausibility};
  lin That kind = {plausibility = kind.plausibility};
  lin These kind = {plausibility = kind.plausibility};
  lin Those kind = {plausibility = kind.plausibility};


  -- cat Kind;
  lincat  Kind = {plausibility : Plausibility};

  -- fun Wine, Cheese, Fish, Pizza : Kind;
  lin Wine = {plausibility = Plausible};
  lin Cheese = {plausibility = Plausible};
  lin Fish = {plausibility = Plausible};
  lin Pizza = {plausibility = Plausible};

  -- fun Mod : Quality -> Kind -> Kind;
  lin Mod quality kind = {
    -- if both the quality and the kind are plausible, then the new kind we are creating is also plausible:
    plausibility = case <kind.plausibility, quality.plausibility> of {
        <Plausible, Plausible> => Plausible;
        <_, _> => Implausible
    };
  };


  -- cat Quality;
  lincat  Quality = {plausibility : Plausibility};

  -- fun Fresh, Warm, Italian, Expensive, Delicious, Boring : Quality;
  lin Fresh = {plausibility = Plausible};
  lin Warm = {plausibility = Plausible};
  lin Cold = {plausibility = Plausible};
  lin Italian = {plausibility = Plausible};
  lin French = {plausibility = Plausible};
  lin Expensive = {plausibility = Plausible};
  lin Cheap = {plausibility = Plausible};
  lin Delicious = {plausibility = Plausible};

  --  fun Very : Quality -> Quality;
  lin Very quality = {plausibility = quality.plausibility};

}
