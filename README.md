![very Italian pizza](very-italian-pizza.jpg)

# Plausibility filtering with Grammatical Framework

This document describes a technique called plausibility filtering which you can use to prevent a Grammatical Framework (GF) application grammar from generating semantically implausible sentences.

## Introduction

Application grammars written in [Grammatical Framework](http://www.grammaticalframework.org/) (GF) often overgenerate in the sense that they produce semantically implausible sentences. Take, for example, the well-known [Foods](https://github.com/GrammaticalFramework/gf-contrib/tree/master/foods) grammar which is often used in GF tutorials. This grammar parses and linearizes comments on food such as *this pizza is delicious* and *that Italian wine is expensive*. If you use this grammar for random generation it will randomly pick combinations of food items and food qualities and produce sentences, some of which will be perfectly normal (like the two examples above) while others will be "weird", implausible, such as *this pizza is very Italian* and *those warm fish are warm*.

GF grammars tend to overgenerate like this because GF's formalism of abstract grammars and abstract syntax tress, where the language-independent semantics of the sentences is described, is not expressive enough to capture all the semantic and pragmatic details you would need to bring in in order to block overgeneration. For example, in the Foods grammar, you would like to be able to encode the fact that some food qualities (eg. warm) can plausibly be applied only to some food items (eg. pizza) but not to others (eg. fish). There is no easy way to encode that constraint in GF's abstract grammars.

## Previous solutions (or rather, non-solutions)

I say that there is no *easy* way to express such constraints, but there are two somewhat *non-easy* ways which have been suggested before as solutions to this problem (for example in section 5.2.3 of the GF [Best Practices](http://www.molto-project.eu/sites/default/files/MOLTO_D2.3.pdf) document).

1. The first suggestion is to design a complex hierarchy of types and subtypes in your abstract grammar. So, for example, you would have one type for food items which can be described as warm, another for those which can be described as fresh and so on. I find this solution unsatisfactory because it causes more problems than it solves:

  - If an item belongs in more than one type, for example pizza which can be described both as warm and as fresh, then it needs to exist in your gramar more than once. This bloats the grammar up and misses a generalization. Ideally you want to have only one pizza entity on your grammar.

  - GF doesn't really *do* subtyping, you can only fake it with type coercion functions. This makes your abstract syntax trees more complex than they need to be.

2. The second suggestion is to use dependent types. The problem with dependent types is that not all GF runtimes support them – including, importantly, the brains of many GF programmers: dependent types are notoriously difficult to understand.

A third option, perhaps, would be not to worry about overgeneration at all and to leave that concern to the application in which the grammar is hosted. The application would be able to take each abstract syntax tree, evaluate its plausibility somehow, and then either ask the GF grammar to linearize it or not, before the linearized sentences are shown to the human user. In other words, the hosting application would put a kind of "plausibility filter" between the grammar and the human user. That is a reasonable proposition, its only disadvantage is that it has to be done outside GF. But, as I will explain below, we do not actually have to go outside GF to do this: we can build such a plausibility filter right in the GF grammar itself. Read on to understand how.

## My solution

The technique I am proposing here is based on one simple trick: if you cannot use the abstract grammar to describe semanics in all the necessary detail, then you use one of the concrete grammars instead. You add one additional concrete grammar to your application and this grammar, instead of linearizing into any particular language, will linearize into formal statements about the plausibility or otherwise of the sentence.

Concrete grammars are much more expressive than abstract grammars: you can have records, tables, parameters, `case of` code branching, functions and so on. With these, you can describe the semantic and pragmatic properties of things in your abstract syntax tree and then compute them compositionally up the tree. In the end, for each abstract syntax tree, the grammar linearizes into either the string "ok" (meaning the sentence is plausible) or "notok" (meaning the sentence is implausible).

```
> l Pred (That Cheese) Delicious
that cheese is delicious
ok

> l Pred (Those (Mod Warm (Mod Delicious Wine))) Warm
those warm delicious wines are warm
notok
```

This one additional concrete grammar in your application acts as an optional "plausiblity filter". It doesn't stop the grammar from generating or accepting implausible sentences, but it gives you a way of knowing whether a sentence is plausible or not. It is up to the application in which the grammar is hosted to use this information for something or ignore it.

In the rest of this document we will have a look at a few examples of plausibility filtering, all done in the Foods grammar. By the end, we will have transformed the Foods grammar from a grammar which overgenerates into a grammar which still overgenerates but always warns you when it has.

## Example 0: preparing the Foods grammar

The source code for this example can be found in the `example0` directory.

We're using the Foods grammar pretty much without change. The only change I've made to the abstract syntax is adding a few more `Quality` objects so we have a wider range to play with later (in examples 2 and 3). Also, I've removed the `Boring` quality because I find it strange to describe food with that adjective, but that's my personal contention.

The plausibility filter I've added is a concrete grammar called `Foods0.gf`. The `0` in the name is just an arbitrary "language" name. You can of course call thus "language" anything you want but I am calling it "language zero" because this name is unlikely to conflict with any "real" language name and because the file neatly sorts alphabetically right after the abstract grammar Foods.gf and before any oher conrcete grammars.

Inside this grammar you will find a parameter called `Plausibility` which we will use everywhere to encode the fact something is or isn't plausible.

```
param Plausibility = Plausible | Implausible;
```

All categories from the abstract grammar (except the topmost one, `Comment`) have as their linearization type a record whose only field, called `plausiblity`, tells us whether the object is plausible or not.

```
lincat  Quality = {plausibility : Plausibility};
lincat  Kind = {plausibility : Plausibility};
lincat Item = {plausibility : Plausibility};
```

All lexical objects are by definition plausible.

```
lin Fresh = {plausibility = Plausible};
lin Warm = {plausibility = Plausible};
lin Cold = {plausibility = Plausible};
...
```

Objects which are built from oher objects with tree-building functions get their plausibility compsitionally from their constituents. The default rule is that, if all child constituents are plausible, then the parent constituent is plausible too.

```
-- fun Mod : Quality -> Kind -> Kind;
lin Mod quality kind = {
  -- if both the quality and the kind are plausible, then the new kind we are creating is also plausible:
  plausibility = case <kind.plausibility, quality.plausibility> of {
      <Plausible, Plausible> => Plausible;
      <_, _> => Implausible
  };
};
```

Notice that there are no strings anywhere. The only category that linearizes as a string is the topmost category `Comment`. It linearizes into `"ok"` if all its child constituents are plausible and `"notok"` if not.

```
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
```

For now, our plausibility filter linearizes as `"ok"` for all sentences, but we are nw ready to start fleshing it out with more detail.

## Example 1: preventing overuse of 'very'

The source code for this example can be found in the `example1` directory. It builds on the code from example 0.

There are a few places in the `Foods` grammar which are recursive. One of them is the `Very` function which can be applied to `Quality` objects again and again.

```
delicious
very delicious
very very delicious
very very very delicious
...
```

Let's change the plausibility filter (the `Foods0.gf` concerete grammar) so that it labels sentences as implausible if they have more than one 'very' attached to a `Quality`. And while we're at it, let's label things like *very Italian* as implausible too: it is weird to modify adjectives of nationality with 'very'.

We will add a new field to the linearization type of `Quality` called `canHaveVery`. This tells the grammar whether the quality can be modified by 'very' (or its equivalent in other concrete languages). Most qualities have this set to `PTrue` but some, like `Italian`, have it set to `PFalse`.

```
-- cat Quality;
lincat  Quality = {plausibility : Plausibility; canHaveVery : PBool};

-- fun Fresh, Warm, Italian, Expensive, Delicious, Boring : Quality;
lin Fresh = {plausibility = Plausible; canHaveVery = PTrue};
lin Warm = {plausibility = Plausible; canHaveVery = PTrue};
...
lin Italian = {plausibility = Plausible; canHaveVery = PFalse};
lin French = {plausibility = Plausible; canHaveVery = PFalse};
...
```

When the `Very` function is asked to add 'very' to a quality, it checks whether the quality can have 'very', and takes that into consideration when deciding whether the new quality is plausible or not.

```
--  fun Very : Quality -> Quality;
lin Very quality = {
  -- if the quality is plausible and if it can have very, then the new quality is also plausible:
  plausibility = case <quality.plausibility, quality.canHaveVery> of {
    <Plausible, PTrue> => Plausible;
    <_, _> => Implausible
  };
  -- the new quality will already have a very, so it cannot get another very:
  canHaveVery = PFalse
};
```

The `Very` function also sets the new quality's `canHaveVery` to `PFalse` to make sure that, if any further 'very' is added to it, the result will be implausible.

If a quality has ghe wrong number of 'veries' and is judged implausible, this fact will bubble up the syntax tree and will result in the entire sentence being declared implausible.

```
Foods> p -lang=Eng "this Italian wine is very very delicious" | l -lang=0
notok

Foods> p -lang=Eng "this very Italian wine is very delicious" | l -lang=0
notok

Foods> p -lang=Eng "this Italian wine is very delicious" | l -lang=0
ok
```

## Example 2: preventing implausible modification

The source code for this example can be found in the `example2` directory. It builds on the code from example 1.

Let's do something more complicated and turn our attention to the combinations of kinds (pizza, wine...) and qualities (delicious, expensive...). Let's change the plausibility filter so that, when "weird" combinations occur, such as *warm wine* or *fresh cheese*, the sentence is labelled as implausible. And while were at it, let's also limit the number of qualities that can modify a kind to just one, to avoid pile-ups of adjecives such as *expensive delicious fresh Italian wine*. We'll do both these things at the same time.

First of all, let's have a think about how we want to formalize the concept of compatibility between kinds (pizza, wine...) and qualities (warm, expensive...). My suggestion is as follows. Each quality, when it is attached to a kind, modifies one of its **properties**. For example, *warm* modifies the *temperature* property, *expensive* modifies the *price* property, *cheap* also modifies the *price* property, and so on. That's one half of the story. The other half is that each kind has a certain set of properties which can be modified. *Pizza* has the property *temperature* and so it can plausibly be modified by *warm*, while *fish* doesn't have that property so it cannot (more accurately, it can, but that renders the sentence implausible). So, the concept of properties is central here and we will use it to formalize compatibility and incompatibility between kinds and qualities. A quality and a kind are compatible if they share a property, and incompatible if they don't.

Let's start by adding to `Foods0.gf` a parameter for encoding properties.

```
-- semantic properties for regulating compatibility between kinds and qualities:
param Prop = Taste | Price | Nationality | Temperature | Freshness;
```

To the linearization type of `Quality` we will add a field called `modifies` which tells us which property the quality modifies when it is attached to a kind. Notice that some qualities modify the same quality.

```
-- cat Quality;
lincat  Quality = {plausibility : Plausibility; canHaveVery : PBool; modifies : Prop};

-- fun Fresh, Warm, Italian, Expensive, Delicious, Boring : Quality;
lin Fresh = {plausibility = Plausible; canHaveVery = PTrue; modifies = Freshness};
lin Warm = {plausibility = Plausible; canHaveVery = PTrue; modifies = Temperature};
lin Cold = {plausibility = Plausible; canHaveVery = PTrue; modifies = Temperature};
...
```

The linearization type of `Kind` needs something similar. One complication, however, is the fact that most kinds can be plausibly modified for more than one property. For example, *fish* can plausibly be modified for *taste*, *price* and *freshness*. So, in the linearization type of `Kind`, we will have a property called `modifiability` and it will be a table from `Prop` to `Plausibility`. The table will tell us whether it is or isn't plausible to modify the kind for a given property.

```
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
```

Now we have all the necessary data in place on both sides (the quality side and the kind side). What is left is to connect them together. This will happen in the `Mod` function which takes a quality and a kind and produces a new kind. This functiom has to check whether the two input objects have compatible properties and declare the result plausible or implausible accordingly.

```
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
```

The `Mod` function also sets the `modifiability` field of the output kind to `table {_ => Implausible}`. This has the effect that once a kind has been modified by a quality, it cannot plausibly be modified further. This is how we make sure that we never have more than one adjective in front of a noun, which is what we wanted.

```
Foods> p -lang=Eng "this warm fish is expensive" | l -lang=0
notok

4 msec
Foods> p -lang=Eng "this delicious fresh fish is expensive" | l -lang=0
notok

1 msec
Foods> p -lang=Eng "this fresh fish is expensive" | l -lang=0
ok
```

## Example 3: preventing implausible predication

The source code for this example can be found in the `example3` directory. It builds on the code from example 2.

In example 2 we eliminated implausible kind-quality combinations when the kind and the quality sit together in the same noun phrase, such as *this warm fish is...*. Now let's do the same for kind-quality combinations that occur in predication, such as *this fish is warm*. We want sentences like this to be labelled as implausible because the kind *fish* is incompatible with the quality *warm*.

Simultanesously, let's label as implausible sentences such as *this fresh fish is fresh* where the same quality appears on both sides of the equation: inside the noun phrase (the "left-hand side") and in the predicate (the "right-hand side"). We want to disqualify not only those sentences where the two qualities are exactly the same, but also sentences where the two qualities are different but modify the same property, for example *this warm pizza is cold*.

Whatever we do, we must not forget to also account for the fact that the noun phrase on the left-hand side may be modified by nothing at all, as in *this fish is fresh*. For that, we will add one more value, `NoProp`, to the `Prop` parameter.

```
param Prop = NoProp | Taste | Price | Nationality | Temperature | Freshness;
```

Furthermore, we will add a new field to the linearization type of `Kind`, called `modifiedBy`, to tell us which property the kind has already been modified for, if any.

```
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
...
```

Kinds that have not been modified by anything yet have the `modifiedBy` field set to `NoProp`. When they do get modified by something, they `Mod` function sets this field to the property being modified.

```
-- fun Mod : Quality -> Kind -> Kind;
lin Mod quality kind = {

  ...

  -- the new kind can be modified by the same things as the old kind:
  modifiability = kind.modifiability;

  -- store information about semantic property this kind is modified with:
  modifiedBy = quality.modifies
};
```

What do we have so far? We have `Kind` objects which know two things: (1) which properties they can be modified for (stored in the `modifiability` table) and (2) which property they have already been modified for, if any (stored in the `modifiedBy` property). Now we need to propagate this information up fro `Kind` to `Item`.

```
-- cat Item;
lincat Item = {plausibility : Plausibility; modifiability : Prop => Plausibility; modifiedBy : Prop};

-- fun This, That, These, Those : Kind -> Item;
lin This kind = {plausibility = kind.plausibility; modifiedBy = kind.modifiedBy; modifiability = kind.modifiability};
lin That kind = {plausibility = kind.plausibility; modifiedBy = kind.modifiedBy; modifiability = kind.modifiability};
lin These kind = {plausibility = kind.plausibility; modifiedBy = kind.modifiedBy; modifiability = kind.modifiability};
lin Those kind = {plausibility = kind.plausibility; modifiedBy = kind.modifiedBy; modifiability = kind.modifiability};
```

Now our `Item` objects know these two things too. Finally, the `Comment` function, which combines an item and a quality to produce a sentence, will use this information to label certain sentences as implausible.

```
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
```

The `Comment` function makes use of an operation called `sameProp` which returns `PTrue` or `PFalse` depending on whether (1) the property the item is modified for and (2) the property he quality modifies, are compatible.

```
oper sameProp : Prop -> Prop -> PBool = \prop1,prop2 -> case <prop1, prop2> of {
  <Taste, Taste> => PTrue;
  <Price, Price> => PTrue;
  <Nationality, Nationality> => PTrue;
  <Temperature, Temperature> => PTrue;
  <Freshness, Freshness> => PTrue;
  <_, _> => PFalse
};
```

This ensures that sentences such as *this fish is warm*, as well as sentences such as *this fresh fish is fresh*, are labelled as implausible. With that, we have achieved what we wanted!

```
Foods> p -lang=Eng "this fish is warm" | l -lang=0
notok

Foods> p -lang=Eng "this fresh fish is fresh" | l -lang=0
notok

Foods> p -lang=Eng "this warm pizza is cold" | l -lang=0
notok

Foods> p -lang=Eng "this warm pizza is delicious" | l -lang=0
ok
```

## Digression: a return to example 2

In example 3 we broke one of the things we built in example 2. In example 2, we wanted to prevent adjectives from piling up inside the noun phrase, such as *expensive delicious fresh Italian wine*. We had this code in the `Mod` function in example 2:

```
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
```

Once `Mod` has been applied, the `modifiability` field is `Implausible` for all properties, and we use that fact to label any further modification as implausible. But we broke that because we needed to preserve the `modifiability` field and propagate it up the tree all the way to `Item`:

```
-- fun Mod : Quality -> Kind -> Kind;
lin Mod quality kind = {

  ...

  -- the new kind can be modified by the same things as the old kind:
  modifiability = kind.modifiability;

  -- store information about semantic property this kind is modified with:
  modifiedBy = quality.modifies
};
```

This means we can no longer use the `modifiability` field as a signal of the fact the kind has already been modified by something. We can use the `modifiedBy` field, however: if its value is anything other than `NoProp`, then the kind has already been modified and any further modification makes it implausible. So we use that field when computing the plausibility of the output kind:

```
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
```

With that, we have fixed what we had broken when we added code from exmple 3 to the code we carried over from example 2.

## Conclusion

We have now updated the Foods grammar so that it always tells us whether the sentence it has generated is plausible or not, based on the criteria we have encoded in it. But the main point of the three examples was to demonstrate that the technique of plausibility filtering, where you "hijack" a concrete grammar to act as a plausiblity filter, is expressive enough to allow you to "do" the sophisticated semantics you need in order to block overgeneration in GF application grammars.
