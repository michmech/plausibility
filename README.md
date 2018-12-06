![very Italian pizza](very-italian-pizza.jpg)

# Plausibility filtering with Grammatical Framework

This document describes a technique called plausibility filtering which you can use to prevent a Grammatical Framework (GF) application grammar from generating semantically implausible sentences.

## Introduction

Application grammars written in [Grammatical Framework](http://www.grammaticalframework.org/) (GF) often overgenerate in the sense that they produce semantically implausible sentences. For example, take the well-known [Foods](https://github.com/GrammaticalFramework/gf-contrib/tree/master/foods) grammar which is often used in GF tutorials. Thís grammar parses and linearizes comments on food such as *this pizza is delicious* and *that Italian wine is expensive*. If you use this grammar for random generation it will randomly pick combinations of food items and food qualities and produce sentences, some of which will be perfectly normal (like the two examples above) while others will be "weird", implausible, such as *this pizza is very Italian* and *those warm fish are warm*.

GF grammars tend to overgenerate like this because GF's formalism of abstract grammars and abstract syntax tress, where the language-independent semantics of the sentences is described, is not expressive enough to capture all the semantic and pragmatic details you would need to bring in in order to block overgeneration. For example, in the Foods grammar, you would like to be able to encode the fact that some food qualities (eg. warm) can plausibly be applied only to some food items (eg. pizza) but not to others (eg. fish). There is no easy way to encode that constraint in GF's abstract grammars.

## Previous solutions (or rather, non-solutions)

I say that there is no *easy* way to express such constraints, but there are two somewhat *non-easy* ways which have been suggested before as solutions to this problem (for example in section 5.2.3 of the GF [Best Practices](http://www.molto-project.eu/sites/default/files/MOLTO_D2.3.pdf) document).

1. The first suggestion is to design a complex hierarchy of types and subtypes in your abstract grammar. So, for example, you would have one type for food items which can be described as warm, another for those which can be described as fresh and so on. I find this solution unsatisfactory because it causes more problems than it solves:

  - If an item belongs in more than one type, for example pizza which can be described both as warm and as fresh, then it needs to exist in your gramar more than once. This bloats the grammar up and misses a generalization. Ideally you want to have only one pizza entity on your grammar.

  - GF doesn't really *do* subtyping, you can only fake it with type coercion functions. This makes your abstract syntax trees more complex than they need to be.

2. The second suggestion is to use dependent types. The problem with dependent types is that not all GF runtimes support them – including, importantly, the brains of many GF programmers: dependent types are notoriously difficult to understand.

A third option, perhaps, would be not to worry about overgeneration at all and to leave that concern to the application in which the grammar is hosted. The application would be able to take each abstract syntax tree, evaluate its plausibility somehow, and then either ask the GF grammar to linearize it or not, before the linearized sentences are shown to the human user. In other words, the hosting application would put a kind of "plausibility filter" between the grammar and the human user. That is a reasonable proposition, its only disadvantage is that it has to be done outside GF. But, as I will explain below, we do not actually have to go outside GF to do this: we can build such a plausibility filter right in the GF grammar itself. Read on to understand how.

## This solution

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

TBD

## Example 1: preventing overuse of 'very'

TBD

## Example 2: preventing implausible modification

TBD

## Example 3: preventing implausible predication

TBD
