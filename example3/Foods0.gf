concrete Foods0 of Foods = open Predef in {
  param Plausibility = Plausible | Implausible;

  -- semantic properties for regulating compatibility between kinds and qualities:
  param Prop = NoProp | Taste | Price | Nationality | Temperature | Freshness;

  -- the slots in which a kind can be modified:
  param Slot = NoSlot | Inherent | Physical | Evaluative;

  -- for a property, tell me which slot it is meant to occupy:
  oper propToSlot : Prop -> Slot = \prop -> case prop of {
    Nationality => Inherent;
    Temperature | Freshness => Physical;
    Taste | Price => Evaluative;
    _ => NoSlot
  };

  -- does maxSlot block slot?
  oper slotBlocked : Slot -> Slot -> PBool = \maxSlot,slot -> case <maxSlot,slot> of {
    <NoSlot, _> => PTrue;
    <Inherent, _> => PTrue;

    <Physical, Inherent> => PFalse;
    <Physical, _> => PTrue;

    <Evaluative, Inherent> => PFalse;
    <Evaluative, Physical> => PFalse;
    <Evaluative, _> => PTrue
  };

  -- take a modifiability table and set one property in it to false:
  oper unmodifiable : (Prop => Plausibility) -> Prop -> (Prop => Plausibility) = \props,prop -> table {
    Taste => case prop of {Taste => Implausible; _ => props!Taste};
    Price => case prop of {Price => Implausible; _ => props!Price};
    Nationality => case prop of {Nationality => Implausible; _ => props!Nationality};
    Temperature => case prop of {Temperature => Implausible; _ => props!Temperature};
    Freshness => case prop of {Freshness => Implausible; _ => props!Freshness};
    _ => Plausible
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
    plausibility = case <item.plausibility, quality.plausibility> of {
      <Plausible, Plausible> => item.modifiability!quality.modifies;
                                --is it plausible to modify this ittem with this quality?
      <_,_> => Implausible
    }
  };


  -- cat Item;
  lincat Item = {plausibility : Plausibility; modifiability : Prop => Plausibility};

  -- fun This, That, These, Those : Kind -> Item;
  lin This kind = {plausibility = kind.plausibility; modifiability = kind.modifiability};
  lin That kind = {plausibility = kind.plausibility; modifiability = kind.modifiability};
  lin These kind = {plausibility = kind.plausibility; modifiability = kind.modifiability};
  lin Those kind = {plausibility = kind.plausibility; modifiability = kind.modifiability};


  -- cat Kind;
  lincat  Kind = {plausibility : Plausibility; maxSlot : Slot; modifiability : Prop => Plausibility;};

  -- fun Wine, Cheese, Fish, Pizza : Kind;
  lin Wine = {plausibility = Plausible; maxSlot = NoSlot; modifiability = table {
    Taste | Price | Nationality => Plausible;
    _ => Implausible
  }};
  lin Cheese = {plausibility = Plausible; maxSlot = NoSlot; modifiability = table {
    Taste | Price | Nationality => Plausible;
    _ => Implausible
  }};
  lin Fish = {plausibility = Plausible; maxSlot = NoSlot; modifiability = table {
    Taste | Price | Freshness => Plausible;
    _ => Implausible
  }};
  lin Pizza = {plausibility = Plausible; maxSlot = NoSlot; modifiability = table {
    Taste | Price | Nationality | Temperature | Freshness => Plausible;
    _ => Implausible
  }};

  -- fun Mod : Quality -> Kind -> Kind;
  lin Mod quality kind = {
                   -- if both the quality and the kind are plausible,
                   -- then the new kind we are creating can also plausible:
    plausibility = case <kind.plausibility, quality.plausibility> of {
                                  -- if the slot this quality's property wants to occupy is not blocked yet,
                                  -- then the new kind we are creating can plausible:
        <Plausible, Plausible> => case (slotBlocked kind.maxSlot (propToSlot quality.modifies)) of {
          PTrue => kind.modifiability!quality.modifies; --is it plausible to modify this kind with this quality?
          PFalse => Implausible
        };
        <_, _> => Implausible
    };
    --the new max slot is that of the quality's property:
    maxSlot = propToSlot quality.modifies;
    -- the new kind can be modified by the same properties as the old kind, minus the quality's property:
    modifiability = unmodifiable kind.modifiability quality.modifies
  };


  -- cat Quality;
  lincat  Quality = {plausibility : Plausibility; gradable : PBool; modifies : Prop};

  -- fun Fresh, Warm, Italian, Expensive, Delicious, Boring : Quality;
  lin Fresh = {plausibility = Plausible; gradable = PTrue; modifies = Freshness};
  lin Warm = {plausibility = Plausible; gradable = PTrue; modifies = Temperature};
  lin Cold = {plausibility = Plausible; gradable = PTrue; modifies = Temperature};
  lin Italian = {plausibility = Plausible; gradable = PFalse; modifies = Nationality};
  lin French = {plausibility = Plausible; gradable = PFalse; modifies = Nationality};
  lin Expensive = {plausibility = Plausible; gradable = PTrue; modifies = Price};
  lin Cheap = {plausibility = Plausible; gradable = PTrue; modifies = Price};
  lin Delicious = {plausibility = Plausible; gradable = PTrue; modifies = Taste};

  --  fun Very : Quality -> Quality;
  lin Very quality = {
    -- if the quality is plausible and if it can have very, then the new quality is also plausible:
    plausibility = case <quality.plausibility, quality.gradable> of {
      <Plausible, PTrue> => Plausible;
      <_, _> => Implausible
    };
    -- the new quality will have a very, so it cannot get another very:
    gradable = PFalse;
    -- the new quality modifies the same semantic property as the old quality:
    modifies = quality.modifies
  };

}
