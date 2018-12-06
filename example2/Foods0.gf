concrete Foods0 of Foods = open Predef in {
  param Plausibility = Plausible | Implausible;

  -- semantic properties for regulating compatibility between kinds and qualities:
  param Prop = Taste | Price | Nationality | Temperature | Freshness;

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
  lincat  Kind = {plausibility : Plausibility; modifiability : Prop => Plausibility};

  -- fun Wine, Cheese, Fish, Pizza : Kind;
  lin Wine = {plausibility = Plausible; modifiability = table {
    Taste | Price | Nationality => Plausible;
    _ => Implausible
  }};
  lin Cheese = {plausibility = Plausible; modifiability = table {
    Taste | Price | Nationality => Plausible;
    _ => Implausible
  }};
  lin Fish = {plausibility = Plausible; modifiability = table {
    Taste | Price | Freshness => Plausible;
    _ => Implausible
  }};
  lin Pizza = {plausibility = Plausible; modifiability = table {
    Taste | Price | Nationality | Temperature | Freshness => Plausible;
    _ => Implausible
  }};

  -- fun Mod : Quality -> Kind -> Kind;
  lin Mod quality kind = {
    -- if both the quality and the kind are plausible then the new kind we are creating can also plausible:
    plausibility = case <kind.plausibility, quality.plausibility> of {
        <Plausible, Plausible> => kind.modifiability!quality.modifies;
                                  --is it plausible to modify this kind with this quality?
        <_, _> => Implausible
    };
    -- the new kind cannot be plausibly modified by anything anymore:
    modifiability = table {_ => Implausible}
  };


  -- cat Quality;
  lincat  Quality = {plausibility : Plausibility; canHaveVery : PBool; modifies : Prop};

  -- fun Fresh, Warm, Italian, Expensive, Delicious, Boring : Quality;
  lin Fresh = {plausibility = Plausible; canHaveVery = PTrue; modifies = Freshness};
  lin Warm = {plausibility = Plausible; canHaveVery = PTrue; modifies = Temperature};
  lin Cold = {plausibility = Plausible; canHaveVery = PTrue; modifies = Temperature};
  lin Italian = {plausibility = Plausible; canHaveVery = PFalse; modifies = Nationality};
  lin French = {plausibility = Plausible; canHaveVery = PFalse; modifies = Nationality};
  lin Expensive = {plausibility = Plausible; canHaveVery = PTrue; modifies = Price};
  lin Cheap = {plausibility = Plausible; canHaveVery = PTrue; modifies = Price};
  lin Delicious = {plausibility = Plausible; canHaveVery = PTrue; modifies = Taste};

  --  fun Very : Quality -> Quality;
  lin Very quality = {
    -- if the quality is plausible and if it can have very, then the new quality is also plausible:
    plausibility = case <quality.plausibility, quality.canHaveVery> of {
      <Plausible, PTrue> => Plausible;
      <_, _> => Implausible
    };
    -- the new quality will have a very, so it cannot get another very:
    canHaveVery = PFalse;
    -- the new quality modifies the same semantic property as the old quality:
    modifies = quality.modifies
  };

}
