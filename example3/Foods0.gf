concrete Foods0 of Foods = open Predef in {
  param Plausibility = Plausible | Implausible;

  -- semantic properties for regulating compatibility between kinds and qualities:
  param Prop = NoProp | Taste | Price | Nationality | Temperature | Freshness;
  oper sameProp : Prop -> Prop -> PBool = \prop1,prop2 -> case <prop1, prop2> of {
    <Taste, Taste> => PTrue;
    <Price, Price> => PTrue;
    <Nationality, Nationality> => PTrue;
    <Temperature, Temperature> => PTrue;
    <Freshness, Freshness> => PTrue;
    <_, _> => PFalse
  };

  -- cat Comment;
  lincat Comment = {s : Str};

  -- fun Pred : Item -> Quality -> Comment;
  lin Pred item quality = {
    s = case plausibility of {
      Plausible => "ok";
      Implausible => "notok"
    }
  } where {
    -- if both the item and the quality are plausible,
    -- and if the item is not already modified by the same semantic property that the quality carries,
    -- then the comment we are creating can also be plausible:
    plausibility = case <item.plausibility, quality.plausibility, (sameProp item.modifiedBy quality.modifies)> of {
      <Plausible, Plausible, PFalse> => item.modifiability!quality.modifies;
                                        --is it plausible to modify this ittem with this quality?
      <_,_, _> => Implausible
    }
  };


  -- cat Item;
  lincat Item = {plausibility : Plausibility; modifiability : Prop => Plausibility; modifiedBy : Prop};

  -- fun This, That, These, Those : Kind -> Item;
  lin This kind = {plausibility = kind.plausibility; modifiedBy = kind.modifiedBy; modifiability = kind.modifiability};
  lin That kind = {plausibility = kind.plausibility; modifiedBy = kind.modifiedBy; modifiability = kind.modifiability};
  lin These kind = {plausibility = kind.plausibility; modifiedBy = kind.modifiedBy; modifiability = kind.modifiability};
  lin Those kind = {plausibility = kind.plausibility; modifiedBy = kind.modifiedBy; modifiability = kind.modifiability};


  -- cat Kind;
  lincat  Kind = {plausibility : Plausibility; modifiability : Prop => Plausibility; modifiedBy : Prop};

  -- fun Wine, Cheese, Fish, Pizza : Kind;
  lin Wine = {plausibility = Plausible; modifiedBy = NoProp; modifiability = table {
    Taste | Price | Nationality => Plausible;
    _ => Implausible
  }};
  lin Cheese = {plausibility = Plausible; modifiedBy = NoProp; modifiability = table {
    Taste | Price | Nationality => Plausible;
    _ => Implausible
  }};
  lin Fish = {plausibility = Plausible; modifiedBy = NoProp; modifiability = table {
    Taste | Price | Freshness => Plausible;
    _ => Implausible
  }};
  lin Pizza = {plausibility = Plausible; modifiedBy = NoProp; modifiability = table {
    Taste | Price | Nationality | Temperature | Freshness => Plausible;
    _ => Implausible
  }};

  -- fun Mod : Quality -> Kind -> Kind;
  lin Mod quality kind = {
    -- if both the quality and the kind are plausible,
    -- and if the kind is not already modified by something,
    -- then the new kind we are creating can also plausible:
    plausibility = case <kind.plausibility, quality.plausibility, kind.modifiedBy> of {
        <Plausible, Plausible, NoProp> => kind.modifiability!quality.modifies;
                                          --is it plausible to modify this kind with this quality?
        <_, _, _> => Implausible
    };
    -- the new kind can be modified by the same things as the old kind:
    modifiability = kind.modifiability;

    -- store information about semantic property this kind is modified with:
    modifiedBy = quality.modifies
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
