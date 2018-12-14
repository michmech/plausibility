![very Italian pizza](very-italian-pizza.jpg)

# Plausibility filtering with Grammatical Framework

This document describes a technique called plausibility filtering which you can use to prevent a Grammatical Framework (GF) application grammar from generating semantically implausible sentences.

## Introduction

Application grammars written in [Grammatical Framework](http://www.grammaticalframework.org/) (GF) often overgenerate in the sense that they produce semantically implausible sentences. Take, for example, the well-known [Foods](https://github.com/GrammaticalFramework/gf-contrib/tree/master/foods) grammar which is often used in GF tutorials. This grammar parses and linearizes comments on food such as *this pizza is delicious* and *that Italian wine is expensive*. If you use this grammar for random generation it will randomly pick combinations of food items and food qualities and produce sentences, some of which will be perfectly normal (like the two examples above) while others will be "weird", implausible, such as *this pizza is very Italian* and *those hot fish are hot*.

GF grammars tend to overgenerate like this because GF's formalism of abstract grammars and abstract syntax trees, where the language-independent meaning of the sentences is suppossed to be described, is not expressive enough to capture all the semantic and pragmatic details you would need to bring in in order to block overgeneration. For example, in the Foods grammar, you would like to be able to encode the fact that some food qualities (eg. hot) can plausibly be applied only to some food items (eg. pizza) but not to others (eg. fish). There is no easy way to encode that constraint in GF's abstract grammars.

## Previous solutions (or rather, non-solutions)

I say that there is no *easy* way to express such constraints, but there are two somewhat *non-easy* ways which have been suggested before as solutions to this problem (for example in section 5.2.3 of the GF [Best Practices](http://www.molto-project.eu/sites/default/files/MOLTO_D2.3.pdf) document).

1. The first suggestion is to design a complex hierarchy of types and subtypes in your abstract grammar. So, for example, you would have one type for food items which can be described as hot, another for those which can be described as fresh and so on. I find this solution unsatisfactory because it causes more problems than it solves:

  - If an item belongs in more than one type, for example pizza which can be described both as hot and as fresh, then it needs to exist in your gramar more than once. This bloats the grammar up and misses a generalization. Ideally you want to have only one pizza entity on your grammar.

  - GF doesn't really *do* subtyping, you can only fake it with type coercion functions. This makes your abstract syntax trees more complex than they need to be.

2. The second suggestion is to use dependent types. The problem with dependent types is that not all GF runtimes support them – including, importantly, the brains of many GF programmers: dependent types are notoriously difficult to understand.

A third option, perhaps, would be not to worry about overgeneration at all and to leave that concern to the application in which the grammar is hosted. The application would be able to take each abstract syntax tree, evaluate its plausibility somehow, and then either ask the GF grammar to linearize it or not, before the linearized sentences are shown to the human user. In other words, the hosting application would put a kind of "plausibility filter" between the grammar and the human user. That is a reasonable proposition, its only disadvantage is that it has to be done outside GF. But, as I will explain below, we do not actually have to go outside GF to do this: we can build such a plausibility filter right in the GF grammar itself. Read on to understand how.

## My solution

The technique I am proposing here is based on one simple trick: if you cannot use the abstract grammar to describe semantics in all the necessary detail, then you use one of the concrete grammars instead. You add one additional concrete grammar to your application and this grammar, instead of linearizing into any particular language, will linearize into formal statements about the plausibility or otherwise of the sentence.

Concrete grammars are much more expressive than abstract grammars: you can have records, tables, parameters, `case of` code branching, functions and so on. With these, you can describe the semantic and pragmatic properties of things in your abstract syntax tree and then compute them compositionally up the tree. In the end, for each abstract syntax tree, the grammar linearizes into either the string `"ok"` (meaning the sentence is plausible) or `"notok"` (meaning the sentence is implausible).

```
> l Pred (That Cheese) Delicious
that cheese is delicious
ok

> l Pred (Those (Mod Warm (Mod Delicious Wine))) Warm
those hot delicious wines are hot
notok
```

This one additional concrete grammar in your application acts as an optional "plausiblity filter". It doesn't stop the grammar from generating or accepting implausible sentences, but it gives you a way of knowing whether a sentence is plausible or not. It is up to the application in which the grammar is hosted to use this information for something or ignore it.

In the rest of this document we will have a look at a few examples of plausibility filtering, all done in the Foods grammar. By the end, we will have transformed the Foods grammar from a grammar which overgenerates into a grammar which still overgenerates but always warns you when it has.

## Example 0: preparing the Foods grammar

The source code for this example can be found in the `example0` directory.

We're using the Foods grammar pretty much without change. The only changes I've made to the abstract syntax are:

- I added a few more `Quality` objects so we have a wider range to play with.
- I removed the `Boring` quality because I find it implausible to describe *any* food with that adjective.
- I changed the English linearization of the `Warm` quality from *warm* to *hot* because I find it more idiomatic in English to describe food as hot rather than warm.

The plausibility filter I've added is a concrete grammar called `Foods0.gf`. The `0` in the name is just an arbitrary "language" name. You can of course call this "language" anything you want but I am calling it "language zero" because this name is unlikely to conflict with any real language name and because the file neatly sorts alphabetically right after the abstract grammar `Foods.gf` and before any other concrete grammars.

Inside this grammar you will find a parameter called `Plausibility` which we will use everywhere to encode the fact that something is or isn't plausible.

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

Objects which are built from other objects with tree-building functions get their plausibility compositionally from their constituents. The default rule is that, if all child constituents are plausible, then the parent constituent is plausible too.

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

Notice that there are no strings anywhere. The only category that linearizes into a string is the topmost category `Comment`. It linearizes into `"ok"` if all its child constituents are plausible and `"notok"` if not.

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

For now, our plausibility filter linearizes into `"ok"` for all sentences, but we are now ready to start fleshing it out with more detail.

## Example 1: preventing overuse of 'very'

The source code for this example can be found in the `example1` directory. It builds on the code from example 0.

There are a few functions in the `Foods` grammar which are recursive. One of them is the `Very` function which can be applied to `Quality` objects again and again.

```
delicious
very delicious
very very delicious
very very very delicious
...
```

Let's change the plausibility filter (the `Foods0.gf` concrete grammar) so that it labels sentences as implausible if they have more than one 'very' attached to a `Quality`. And while we're at it, let's label things like *very Italian* as implausible too: it is weird to modify adjectives of nationality with 'very'.

We will add a new field to the linearization type of `Quality` called `gradable`. This tells the grammar whether the quality can be graded in any way, for example by modifying it with 'very' (or its equivalent in other concrete languages). Most qualities have this set to `PTrue` but some, like `Italian`, have it set to `PFalse`.

```
-- cat Quality;
lincat  Quality = {plausibility : Plausibility; gradable : PBool};

-- fun Fresh, Warm, Italian, Expensive, Delicious, Boring : Quality;
lin Fresh = {plausibility = Plausible; gradable = PTrue};
lin Warm = {plausibility = Plausible; gradable = PTrue};
...
lin Italian = {plausibility = Plausible; gradable = PFalse};
lin French = {plausibility = Plausible; gradable = PFalse};
...
```

When the `Very` function is asked to add 'very' to a quality, it checks whether the input quality is gradable, and takes that into consideration when deciding whether the output quality is plausible or not.

```
--  fun Very : Quality -> Quality;
lin Very quality = {
  -- if the quality is plausible and if it can have very, then the new quality is also plausible:
  plausibility = case <quality.plausibility, quality.gradable> of {
    <Plausible, PTrue> => Plausible;
    <_, _> => Implausible
  };
  -- the new quality will have a very, so it becomes ungradable:
  gradable = PFalse
};
```

Additionally, the `Very` function sets the output quality's `gradable` to `PFalse` to make sure that, if any further 'very' is added to it, the result will be implausible.

If a quality has the wrong number of 'veries' and is judged implausible, this fact will bubble up the syntax tree and will result in the entire sentence being declared implausible.

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

Let's do something more complicated now and turn our attention to the combinations of kinds (pizza, wine...) and qualities (delicious, expensive...).

- Let's change the plausibility filter so that, when "weird" combinations occur, the sentence is labelled as implausible. We will do this for kind-quality combinations that occur both in attribution (*fresh wine*) and in predication (*this wine is fresh*).

- When we have more than one quality modifying a kind attributively, such as *expensive delicious fresh Italian wine*, we want to label as implausible those cases when the same quality appears there twice, such as *fresh delicious fresh fish*. We want to disqualify not only those sentences where the two qualities are exactly the same, but also sentences where the two qualities are different but contradictory, for example *this hot cold pizza*.

- Simultaneously, let's label as implausible sentences such as *this fresh fish is fresh* where the same quality appears on both sides of the equation: inside the noun phrase (the "left-hand side") and in the predicate (the "right-hand side"). And, as above, we want to disqualify not only those sentences where the two qualities are exactly the same, but also sentences where the two qualities are different but contradictory, for example *this hot pizza is cold*.

First of all, let's have a think about how we want to formalize the concept of compatibility between kinds (pizza, wine...) and qualities (hot, expensive...). My suggestion is as follows. Each quality, when it is attached to a kind, modifies one of its **properties**. For example, *hot* modifies the *temperature* property, *expensive* modifies the *price* property, *cheap* also modifies the *price* property, and so on. That's one half of the story. The other half is that each kind has a certain set of properties for which can be modified. *Pizza* has the property *temperature* and so it can plausibly be modified by *hot*, while *fish* doesn't have that property so it cannot (more accurately, it can, but that renders the sentence implausible). So, the concept of properties is central here and we will use it to formalize compatibility and incompatibility between kinds and qualities. A quality and a kind are compatible if they share a property, and incompatible if they don't.

Let's start by adding to `Foods0.gf` a parameter for encoding properties.

```
-- semantic properties for regulating compatibility between kinds and qualities:
param Prop = NoProp | Taste | Price | Nationality | Temperature | Freshness;
```

To the linearization type of `Quality` we will add a field called `modifies` which tells us which property the quality modifies when it is attached to a kind. Notice that some qualities modify the same property.

```
-- cat Quality;
lincat  Quality = {plausibility : Plausibility; gradable : PBool; modifies : Prop};

-- fun Fresh, Warm, Italian, Expensive, Delicious, Boring : Quality;
lin Fresh = {plausibility = Plausible; gradable = PTrue; modifies = Freshness};
lin Warm = {plausibility = Plausible; gradable = PTrue; modifies = Temperature};
lin Cold = {plausibility = Plausible; gradable = PTrue; modifies = Temperature};
...
```

The linearization type of `Kind` needs something similar. One complication, however, is the fact that most kinds can be plausibly modified for more than one property. For example, *fish* can plausibly be modified for *taste*, *price* and *freshness*. So, in the linearization type of `Kind`, we will have a property called `modifiability` and it will be a table from `Prop` to `Plausibility`. Let' call it *the modifiability table*. It tells us whether it is or isn't plausible to modify the kind for a given property.

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
  -- if both the quality and the kind are plausible,
  -- then the new kind we are creating can also plausible:
  plausibility = case <kind.plausibility, quality.plausibility> of {
      <Plausible, Plausible> => kind.modifiability!quality.modifies;
                                --is it plausible to modify this kind with this quality?
      <_, _> => Implausible
  };
  -- the new kind can be modified by the same properties as the old kind, minus the quality's property:
  modifiability = unmodifiable kind.modifiability quality.modifies
};

...

-- take a modifiability table and set one property in it to false:
oper unmodifiable : (Prop => Plausibility) -> Prop -> (Prop => Plausibility) = \props,prop -> table {
  Taste => case prop of {Taste => Implausible; _ => props!Taste};
  Price => case prop of {Price => Implausible; _ => props!Price};
  Nationality => case prop of {Nationality => Implausible; _ => props!Nationality};
  Temperature => case prop of {Temperature => Implausible; _ => props!Temperature};
  Freshness => case prop of {Freshness => Implausible; _ => props!Freshness};
  _ => Plausible
};
```

The `Mod` function removes `quality.modifies` from the `kind`'s `modifiability` (using an oper called `unmodifiable`) and this has the effect that the `kind` can no longer be plausibly modified by a `quality` with the same `modifies`. For example, once a kind has been modified with something *cold*, the property *temperature* is removed from the the kind's modifiable properties and the kind can no longer be plausibly modified with either *cold* or *hot*.

```
Foods> p -lang=Eng "this hot fish is expensive" | l -lang=0
notok

Foods> p -lang=Eng "this hot cold pizza is expensive" | l -lang=0
notok

Foods> p -lang=Eng "this hot delicious pizza is expensive" | l -lang=0
ok
```

Now we need to propagate the modifiability information up from `Kind` to `Item`.

```
-- cat Item;
lincat Item = {plausibility : Plausibility; modifiability : Prop => Plausibility};

-- fun This, That, These, Those : Kind -> Item;
lin This kind = {plausibility = kind.plausibility; modifiability = kind.modifiability};
lin That kind = {plausibility = kind.plausibility; modifiability = kind.modifiability};
lin These kind = {plausibility = kind.plausibility; modifiability = kind.modifiability};
lin Those kind = {plausibility = kind.plausibility; modifiability = kind.modifiability};
```

Now our `Item` objects know too what they can be modified with. Finally, the `Pred` function, which combines an item and a quality to produce a sentence, will use this information to label certain sentences as implausible.

```
-- fun Pred : Item -> Quality -> Comment;
lin Pred item quality = {
  s = case plausibility of {
    Plausible => "ok";
    Implausible => "notok"
  }
} where {
  -- if both the item and the quality are plausible,
  -- then the comment we are creating can also be plausible:
  plausibility = case <item.plausibility, quality.plausibility> of {
    <Plausible, Plausible> => item.modifiability!quality.modifies;
                              --is it plausible to modify this ittem with this quality?
    <_,_> => Implausible
  }
};
```

With that, we have reached the grand finale: sentences such as *this fish is hot*, as well as sentences such as *this fresh fish is fresh*, are labelled as implausible.

```
Foods> p -lang=Eng "this fish is hot" | l -lang=0
notok

Foods> p -lang=Eng "this fresh fish is fresh" | l -lang=0
notok

Foods> p -lang=Eng "this hot pizza is cold" | l -lang=0
notok

Foods> p -lang=Eng "this hot pizza is delicious" | l -lang=0
ok
```

## Example 3: Enforcing ordered modification

The source code for this example can be found in the `example3` directory. It builds on the code from example 2.

The grammar we have so far allows the qualities that modify a kind attributively to appear in any order. This sometimes results in slightly disharmonious expressions such as *Italian delicious pizza*. It would be nicer to have the adjectives in the reverse order: *delicious Italian pizza*. So, let's modify the plausiblity filter so that it disqualifies sentences where the qualities are stacked in the "wrong" order.

But first, how would you formalize the concept of right or wrong order? My suggestion is as follows. When modifying anything, there is a fixed sequence of "slots", each of which can be occupied by zero, one or more qualities. The slots are ordered from "nearest" to "farthest" from the head noun as follows:

1. The first slot is for qualities which describe some **inherent**, unchangeable property of the kind, such as its nationality: *Italian pizza*.

2. The second slot is for qualities which describe some **physical** property which is changeable but independent of human judgment, such as temperature or freshness: *hot Italian pizza*.

3. The third slot is for qualities which describe some **evaluative** property which is the result of human judgment, such as taste or price: *delicious hot Italian pizza*.

When adding a quality to a kind, we need to know which slot the quality belongs to. And, once the quality has been added to the kind, all slots before it are "blocked". That is why it is implausible, for example, to add an **inherent** quality once a **physical** or **evaluative** property has been added. For example, once you've added *delicious* to *pizza*, you can no longer add *hot* or *Italian*. You can still add *expensive* though: the **evaluative** slot hasn't been blocked yet. Inside each slot, the qualities can plausiblity appear in any order: *expensive delicious pizza* and *delicious expensive pizza* are both plausible.

It seems reasonable to assume that this tendency for qualities to "stack up" in ordered slots is language-independent, at least in the small domain of our Foods grammar. In the linearizations, the slots are ordered in such a way that slot 1 is nearest the head noun and slot 3 is farthest. In languages where adjectives are before the head noun, this means that the slots are ordered from right to left:

- **evaluative** → **physical** → **inherenet** → noun  
  eg. *delicious hot Italian pizza*

And in languages where where adjectives are after the head noun, the slots are ordered from left to right:

- noun → **inherenet** → **physical** → **evaluative**  
  eg. *píotsa Iodálach te blasta* (example in Irish)  
  literally *pizza Italian hot delicious*

Now, let's implement this in our plausiblity filter. First, we need a parameter to tell us which slots exist.

```
-- the slots in which a kind can be modified:
param Slot = NoSlot | Inherent | Physical | Evaluative;
```

And we need an operation which can tell us, for any property, which slot it belongs in.

```
-- for a property, tell me which slot it is meant to occupy:
oper propToSlot : Prop -> Slot = \prop -> case prop of {
  Nationality => Inherent;
  Temperature | Freshness => Physical;
  Taste | Price => Evaluative;
  _ => NoSlot
};
```

Each `Kind` will have a new property, named `maxSlot`, which tells us what the highest-ranking slot is that already has at least one quality in it.

```
-- cat Kind;
lincat  Kind = {plausibility : Plausibility; maxSlot : Slot; modifiability : Prop => Plausibility;};

-- fun Wine, Cheese, Fish, Pizza : Kind;
lin Wine = {plausibility = Plausible; maxSlot = NoSlot; modifiability = table {
  Taste | Price | Nationality => Plausible;
  _ => Implausible
}};
...
```

For lexical kinds that have not been modified by any qualities yet, the `maxSlot` property is set to `NoSlot`, obviously. The `Mod` function upgrades this when the modifying the kind.

```
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
```

But, most importantly, the `Mod` function does this:

1. Find out which slot the input quality belongs to (using the `propToSlot` operation).
2. Find out whether that slot is already blocked (using the `slotBlocked` operation).
3. If the slot is already blocked, the output kind is labelled as implausible.

This gives us what we wanted: sentences where qualities appear in implausible orders are labelled as implausible.

```
Foods> p -lang=Eng "this hot Italian delicious pizza is expensive" | l -lang=0
notok

Foods> p -lang=Eng "this delicious hot Italian pizza is expensive" | l -lang=0
ok
```

## Conclusion

We have now updated the Foods grammar so that it always tells us whether the sentence it has generated is plausible or not, based on the criteria we have encoded in it.

But the main point of the three examples was to demonstrate that the technique of plausibility filtering, where you "hijack" a concrete grammar to act as a plausiblity filter, is expressive enough to allow you to "do" the sophisticated semantics you need in order to block overgeneration in GF application grammars. You can use the tools available to you in a concrete grammar, such as records, tables, parameters and operations, to record facts about the semantics and pragmatics of things, and then compute them compositionally up the tree.
