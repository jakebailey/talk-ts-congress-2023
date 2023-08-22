---
css: unocss
highlighter: shiki
canvasWidth: 850
favicon: /favicon.ico
download: true
exportFilename: slides
lineNumbers: true
fonts:
  mono: "Source Code Pro Bold"
---

# Migrating TypeScript to Modules

<h2 id="cover-subtitle">The Fine Details</h2>

<br>
<br>
<br>
<br>

## Jake Bailey

#### Senior Software Engineer, TypeScript @ Microsoft

<br>
<br>

[jakebailey.dev/talk-ts-congress-2023](https://jakebailey.dev/talk-ts-congress-2023)

<style>
    h1 {
        font-size: 3rem !important;
        /* margin-bottom: 0 !important; */
    }
    #cover-subtitle {
        font-size: 2rem;
        font-style: italic;
        opacity: 0.5;
    }
    p {
        text-align: right;
    }
</style>

---

# What are we talking about?

<LightOrDark>
<template #dark><img class="main" src="/img/pr.png"></template>
<template #light><img class="main" src="/img/pr_light.png"></template>
</LightOrDark>

More details at
[jakebailey.dev/go/module-migration-blog](https://jakebailey.dev/go/module-migration-blog)

<v-click>

<div>
<LightOrDark>
<template #dark><img class="zoom" src="/img/pr.png"></template>
<template #light><img class="zoom" src="/img/pr_light.png"></template>
</LightOrDark>
</div>

</v-click>

<style>
img.main {
  height: 75%;
  margin-left: auto;
  margin-right: auto;
  margin-bottom: 4%;
}
img.zoom {
  position: absolute;
  left: 57%;
  top: 18%;
  height: 45px;
  width: 320px;
  object-fit: none;
  object-position: 97% 19%;
  border: 2px solid orangered;
}
</style>

<!--
First off, what are we even talking about?

In November of last year, I sent this PR. This was the culmination of many months of work.
A huge PR (some 280K lines) which completely changed the structure of our codebase.

We talked about much of
this change's effects on our blog, but there's a lot of stuff we didn't
get to talk about, and that's what I'm going to go over today.
-->

---

# An outline

- What even is a "migration to modules"?
- Why was it so challenging?
- How did I make it less painful?
- How did the migration _actually_ work under the hood?
- How did it go and what's next?

---

# What even _are_ modules?

## 

A few different definitions... two most critical are:

- Modules are a _syntax_ (`import`, `export`)
- Modules are an _output format_ (ESM, CommonJS, SystemJS, AMD, UMD, IIFE, ...)

<br>

```ts
// @filename: src/someFile.ts
export function sayHello(name: string) { // Export from one file...
    console.log(`Hello, ${name}!`);
}

// @filename: src/index.ts
import { sayHello } from "./someFile"; // ... import it in another.

sayHello("TypeScript Congress");
```

<v-click>
<Arrow x1="600" y1="150" x2="450" y2="150" color="orangered" />
</v-click>

<!--
When I talk about modules in this talk, I'm primarily talking about
the syntax and its associated layout on disk.

This begs the question; if we're migrating to this, what were we using?
-->

---

# TypeScript pre-modules

## 

The opposite of modules is... scripts 😱 Everything is placed within _global_
namespaces.

```ts
// @filename: src/compiler/parser.ts
namespace ts {
    export function createSourceFile(sourceText: string): SourceFile {/* ... */}
}

// @filename: src/compiler/program.ts
namespace ts {
    export function createProgram(): Program {
        const sourceFile = createSourceFile(text);
}
```

<v-click>
<Arrow x1="220" y1="320" x2="277" y2="300" color="orangered" />
</v-click>

Fun fact: namespaces were originally called "internal modules".

<!--
parser.ts defines the function createSourceFile, "exporting it"
That makes it visible to other declarations of the ts namespace,
so createProgram can use it, _implicitly_.
-->

---

# Emitting namespaces

## 

Namespaces turn into plain objects and functions.

```ts
var ts;
// was: src/compiler/parser.ts
(function(ts) {
    function createSourceFile(sourceText) {/* ... */}
    ts.createSourceFile = createSourceFile;
})(ts || (ts = {}));

// was: src/compiler/program.ts
var ts;
(function(ts) {
    function createProgram() {
        const sourceFile = ts.createSourceFile(text);
    }
    ts.createProgram = createProgram;
})(ts || (ts = {}));
```

<v-click>
<Arrow x1="380" y1="300" x2="298" y2="345" color="orangered" />
</v-click>

---

# "Bundling" with `prepend`

```json
// @filename: src/tsc/tsconfig.json
{
    "compilerOptions": { "outFile": "../../built/local/tsc.js" },
    "references": [
        { "path": "../compiler", "prepend": true },
        { "path": "../executeCommandLine", "prepend": true }
    ]
}
```

Makes `tsc` emit:

```ts
var ts;
// Cram all of src/compiler/**/*.ts and src/executeCommandLine/**/*.ts on top.
(function(ts) {/*...*/})(ts || (ts = {}));
// ...
// was: src/tsc/tsc.ts
(function(ts) { ts.executeCommandLine(...); })(ts || (ts = {}));
```

<!--
Did you know that TypeScript has been a bundler this whole time?
-->

---

# What if someone wants to import us?

## 

Our outputs are constructed global scripts, but we're tricky.

```ts
namespace ts {
    if (typeof module !== "undefined" && module.exports) module.exports = ts;
}
```

Emits like:

```ts
var ts;
(function(ts) {/* ... */})(ts || (ts = {}));
// ...
(function(ts) {
    if (typeof module !== "undefined" && module.exports) module.exports = ts;
})(ts || (ts = {}));
```

---

# Namespaces have some upsides

## 

With namespaces, we don't have to write imports, ever!

- When adding code, no new imports
- When moving code, no changed imports
- `tsc` "bundles" our code using `prepend`

But...

---

# Nobody writes code like this anymore!

- We don't get to dogfood modules
- We can't use external tools
- We have to maintain `prepend`... but nobody uses it _except us_ 🥴

<br>

What we want:

```ts
// @filename: src/compiler/parser.ts
export function createSourceFile(sourceText: string): SourceFile {/* ... */}

// @filename: src/compiler/program.ts
import { createSourceFile } from "./parser";

export function createProgram(): Program {
    const sourceFile = createSourceFile(text);
}
```

---

# We know what we want; let's do it

## 

The question is... how can we:

- Actually make the switch ...
- ... while maintaining the same behavior ...
- ... and preserving a compatible API?

<!-- dprint-ignore-start -->

---
layout: center
---

<!-- dprint-ignore-end -->

# The challenge

---

# TypeScript is huge!

<LightOrDark>
<template #dark><TSReleaseByLines theme="dark" /></template>
<template #light><TSReleaseByLines theme="light" /></template>
</LightOrDark>

<!--
This is a over a quarter of a million non-test lines which are
going to have to change.
-->

---

# TypeScript changes often!

<LightOrDark>
<template #dark><img class="main" src="/img/changes.png"></template>
<template #light><img class="main" src="/img/changes_light.png"></template>
</LightOrDark>

<v-click>

<div>
<LightOrDark>
<template #dark><img class="zoom" src="/img/changes.png"></template>
<template #light><img class="zoom" src="/img/changes_light.png"></template>
</LightOrDark>
</div>

</v-click>

That's an average of ~5 commits a weekday.

<style>
img.main {
  height: 75%;
  margin-left: auto;
  margin-right: auto;
  margin-bottom: 4%;
}
img.zoom {
  position: absolute;
  left: 10%;
  top: 45%;
  height: 70px;
  width: 338px;
  object-fit: none;
  object-position: 5% 30.5%;
  border: 2px solid orangered;
}
</style>

<!--
Oh, and did I mention that there were over 1000 commits to main
in the 9 months from when I started to when I merged the change?
This isn't a trick of us merging branches; each commit is an
individual merged PR.

Average of 5 commits a weekday; even one commit would invalidate
the whole thing.

Any solution not only needs to handle the size of the code, but
also make it as easy as possible to apply to main even when it changes.

These are contributing factors in why it took so long to do this,
along with loads of other little problems discovered along the way.
CommonJS and the import/export syntax it works with has been around
since the launch of TypeScript in 2012; ESM itself was added in 2015.
First actual filed issue for "migrate" is 2019 with an actual effort
that stalled.

It took me like 8-9 months of dedicated work to get it to the finish line.
-->

---

# How can we change a huge, moving project?

## 

Certainly not by hand! Automate _everything_.

- Code transformation where possible
- `git` patches to store manual changes
- Done stepwise, for debugging, review, `git blame` preservation

<img src="/img/clippy.png">

<style>
img {
    height: 50%;
    margin-top: 2%;
    margin-left: auto;
    box-shadow: 0px 0px 4px #FFFFFF;
    border-radius: 4px;
}
</style>

---

# What does the migration tool look like?

- Code transformation is performed with `ts-morph`
  - An extremely helpful TypeScript API wrapper by David Sherret ❤️
    ([ts-morph.com](https://ts-morph.com))
- Manual changes are managed by `git` with `.patch` files!
  - `git format-patch` dumps commits to disk
  - `git am` applies the patches during the migration
  - If a patch fails to apply, `git` pauses for us!

<br>
<br>
<br>
<br>

[jakebailey.dev/go/module-migration-demo](https://jakebailey.dev/go/module-migration-demo)

<!-- dprint-ignore-start -->

<!--
ts-morph is really great for doing TS-to-TS transformation.
When I started, we were using TS's own transformation system for this,
but our stack is much more focused on JS emit, not perfect source preservation.

This genius patching idea came from a former team member, Eli.
-->

---
layout: center
---

<!-- dprint-ignore-end -->

# Code transformation

---

# Step 1: Unindent

## 

Eventually, we _will_ pull the code out of the namespaces, one block higher.

If we do it early, later diffs will be cleaner, and git will remember.

From:

```ts
namespace ts {
    export function createSourceFile(sourceText: string): SourceFile {/* ... */}
}
```

Into:

<!-- dprint-ignore-start -->

```ts
namespace ts {
export function createSourceFile(sourceText: string): SourceFile {/* ... */}
}
```

<!-- dprint-ignore-end -->

<!--
This is a silly one, but modules have their code one indent level above namespaces.
If we unindent the code now, then later steps will be easier to review and git will better
track the code through `git blame`.
-->

---

# Step 2: Make namespace accesses explicit

## 

Namespace accesses are implicit, but imports will be explicit.

From:

```ts
export function createSourceFile(sourceText: string): SourceFile {
    const scanner = createScanner(sourceText);
}
```

Into:

```ts
export function createSourceFile(sourceText: string): ts.SourceFile {
    const scanner = ts.createScanner(sourceText);
}
```

<v-click>
<Arrow x1="468" y1="260" x2="468" y2="310" color="orangered" />
<Arrow x1="243" y1="387" x2="243" y2="347" color="orangered" />
</v-click>

<br>

This will make the next step clearer.

<!--
Note the `ts.` at the bottom.

The next step will show why this is helpful.
-->

---

# Step 3: Replace namespaces with imports

## 

Given:

<!-- dprint-ignore-start -->

```ts
namespace ts {
export function createSourceFile(sourceText: string): ts.SourceFile {
    const scanner = ts.createScanner(sourceText);
}
}
```

<!-- dprint-ignore-end -->

We'll convert this into:

```ts
import * as ts from "./_namespaces/ts";

export function createSourceFile(sourceText: string): ts.SourceFile {
    const scanner = ts.createScanner(sourceText);
}
```

---

# Step 3: Replace namespaces with imports

## 

As a diff:

```diff
-namespace ts {
+import * as ts from "./_namespaces/ts";
+
 export function createSourceFile(sourceText: string): ts.SourceFile {
     const scanner = ts.createScanner(sourceText);
 }
-}
```

Everything inside is unchanged!

But, what the heck is this `_namespaces` import?

<!--
This is the big one!
-->

---

# Introducing... "namespace barrels"

## 

Using reexports, we can build modules whose exports match the API of the old
namespaces.

```ts
// @filename: src/compiler/_namespaces/ts.ts
export * from "../core";
export * from "../corePublic";
export * from "../debug";
// ...

// @filename: src/compiler/checker.ts
import * as ts from "./_namespaces/ts";

// Use `ts` exactly like the old namespace!
const id = ts.factory.createIdentifier("foo");
```

These are often referred to in the JS community as "barrel modules".

For us, these become our namespaces, so let's just call them "namespace
barrels"!

---

# Emulating namespace behaviors

## 

Most namespace behavior can be emulated with modules.

```ts
// Emulate nested namespaces like `namespace ts.performance {}`
// @filename: src/compiler/_namespaces/ts.ts
export * as performance from "./ts.performance";

// Emulate `prepend` by reexporting multiple namespace barrels
// @filename: src/typescript/_namespaces/ts.ts
export * from "../../compiler/_namespaces/ts";
export * from "../../services/_namespaces/ts";
export * from "../../deprecatedCompat/_namespaces/ts";

// Export the entire ts namespace for public use
// @filename: src/typescript/typescript.ts
import * as ts from "./_namespaces/ts";
export = ts;
```

---

# Step 4: Convert to named imports

## 

After step 3, we're left with namespace imports, like:

```ts
import * as ts from "./_namespaces/ts";

export function createSourceFile(sourceText: string): ts.SourceFile {
    const scanner = ts.createScanner(sourceText);
}
```

This step converts them to named imports:

```ts
import { createScanner, SourceFile } from "./_namespaces/ts";

export function createSourceFile(sourceText: string): SourceFile {
    const scanner = createScanner(sourceText);
}
```

<!--
This is _almost_ our desired code, but still through "namespace barrels".
-->

---

# The tedious work is done!

## 

At this point, we're done with the bulk transformation.

But, we're not all the way there yet.

<img src="/img/draw_owl.jpg">

<style>
img {
    height: 50%;
    margin-top: 7%;
    margin-left: auto;
    margin-right: auto;
}
</style>

---

# Manual changes

## 

- After the automated transform steps, there are _29_ manual changes!
- This is obviously scary; any changes to main could conflict
- But, we are using `git` to manage these!
- If we run the migration, `git` will pause, just like a rebase. Just:
  1. Fix the problem
  1. `git am --continue`
  1. Ask the migration tool to dump the patches

<!-- dprint-ignore-start -->

<!--  -->

---
layout: center
---

<!-- dprint-ignore-end -->

# Some manual change highlights

<!--
Remember, there are 29 of these, I can't go through them all here.
Check out the PR or migration tool to see all of them.
-->

---

# Bundling with `esbuild`

- We still needed to bundle
- Lots of bundlers to choose from; I went with `esbuild`
  ([esbuild.github.io](https://esbuild.github.io))
- Obviously, it's fast; ~200 ms to build `tsc.js`
- Features scope hoisting, tree shaking, enum inlining
- We maintain a mode in our build which uses solely `tsc`, just to be sure

<img
  src="/img/esbuild.svg"
  alt="esbuild logo"
  height="87"
  width="100" />

<style>
img {
  height: 50%;
  margin-top: 5%;
  margin-left: auto;
  margin-right: auto;
}
</style>

---

# `d.ts` bundling

- Without `tsc`'s `prepend`, someone needs to bundle `d.ts` files
- I ended up rolling my own `d.ts` bundler (~400 LoC)
- Definitely not for external use; it's very specific to our API

```ts
// Something like...
namespace ts {
    function createSourceFile(): SourceFile;

    namespace server {
        namespace protocol {
            // ...
        }
    }
}
export = ts;
```

<!--
Many other alternatives considered, api-extractor, rollup-plugin-dts,
tsup, dts-bundler-generator
-->

---

# Complete build overhaul

## 

- Our old build was handled `gulp`; had gotten somewhat convoluted and hard to
  change
- With modules, the build steps are quite different!
- Build completely replaced, reimplemented using an all new task runner (~500
  LoC)
  - Plain JS functions with an explicit dependency graph, as parallel as
    possible
- It's called `hereby`, don't use it, thanks 😅

```ts
export const buildSrc = task({
    name: "build-src",
    description: "Builds the src project (all code)",
    dependencies: [generateDiagnostics],
    run: () => buildProject("src"),
});
```

<!--
Old build had been gulp since 2016, `jake` before that.

Feature complete at ~500 lines of code. Maybe if I had worked on this
months later, I would have tried `wireit`.
 -->

---

# We did it! How has it turned out?

Great! 👍

For TypeScript users:

- 10-20% speedup from `esbuild`'s scope hoisting
- 43% package size reduction (63.8 MB -> 37.4 MB)
- No API change

For the TypeScript team:

- Core development loop improvement
- Dogfooding!
- `prepend` is deprecated; to be removed in TS 5.5

<!--
Package size reduction from tree shaking, 2 space indents,
deleting typescriptServices.js

Dogfooding:
- Found some auto import bugs and fixed them
- Spawned an effort to try and make TS better match other tooling for import organization
-->

---

# What's next?

## 

There's way too much exciting stuff to talk about, but:

- Getting rid of `_namespaces`, somehow?
- Shipping ESM?
  - Probably works for executables (`tsc`, `tsserver`, ...)?
  - Maybe an ESM API "for free"?
- Untangling things so we can be tree shaken?
  - Could we have `@typescript/*` packages?
- Minification? Other optimizers?
  - Downstream patchers make this challenging 😢

<!--
- namespace barrels also help fix cycles
- ESM likely works for our executables, maybe even an ESM API "for free"
  - Even if not, we are modules so we can actually make an ESM API; before we couldn't.
- Minification is hard because project patch us; yarn, ts-patch, prettier
  - I've been trying to figure out ways we can address the main reasons people patch us.

In any case, exciting stuff ahead.
-->

---

# Thanks!

<br>
<br>

Find me at: [jakebailey.dev](https://jakebailey.dev)

The migration PR:
[jakebailey.dev/go/module-migration-pr](https://jakebailey.dev/go/module-migration-pr)

The migration tool:
[jakebailey.dev/go/module-migration-tool](https://jakebailey.dev/go/module-migration-tool)

Module migration blog:
[jakebailey.dev/go/module-migration-blog](https://jakebailey.dev/go/module-migration-blog)

Watch the migration in real time:
[jakebailey.dev/go/module-migration-demo](https://jakebailey.dev/go/module-migration-demo)

<style>
a {
  position: absolute;
  left: 50%;
}
</style>

<!--
So with that, thanks for watching! Feel free to check me out at jakebailey.dev,
and check out some of the migration goodies.
 -->
