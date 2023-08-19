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
- How did we make it less painful?
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

<!-- dprint-ignore-start -->

<!--
When I talk about modules in this talk, I'm primarily talking about
the syntax and its associated layout on disk.

This begs the question; if we're migrating to this, what were we using?
-->

---
clicks: 2 # Hack; default is miscounted
---

<!-- dprint-ignore-end -->

# TypeScript pre-modules

## 

The opposite of modules: _scripts_ 😱. Each file declared a _global_ namespace,
usually `ts`.

```ts {|3|9|}
// @filename: src/compiler/parser.ts
namespace ts {
    export function createSourceFile(sourceText: string): SourceFile {/* ... */}
}

// @filename: src/compiler/program.ts
namespace ts {
    export function createProgram(): Program {
        const sourceFile = createSourceFile(text);
    }
}
```

<v-clicks at="0">

- Declarations are exported using `export`
- Other namespaces can reference exported declarations _implicitly_

</v-clicks>

<!--
Fun fact; namespaces were originally called "internal modules".
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
(function(ts) {
    function createProgram() {
        const sourceFile = ts.createSourceFile(text);
    }
    ts.createProgram = createProgram;
})(ts || (ts = {}));
```

<v-click>
<Arrow x1="289" y1="410" x2="289" y2="345" color="orangered" />

Surprise! Not so implicit now, are you?
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

# What if someone wants to import our code?

## 

All of this output is declared global, but we can cheat.

In some random file included in `tsconfig.json`, declare this:

```ts
namespace ts {
    if (typeof module !== "undefined" && module.exports) module.exports = ts;
}
```

Emits as:

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

With namespaces, we don't have to write imports, ever! 😅

- Everything _feels_ local
- When we write new code, we don't have to add any new imports
- Moving code from one file to another doesn't require modifying imports
- `tsc` "bundles" our code thanks to `prepend`

But...

---

# Nobody writes code like this anymore!

- We completely miss out on "dogfooding" our own module experience
  - e.g. modern module resolution, auto-imports, import sorting, organization...
- We can't use any tooling that needs imports, or that skips `tsc`
- We have to maintain `prepend`... but nobody uses it _except us_ 🥴

We want to be able to write:

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

_Oh, and also..._

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
-->

---

# How can we change a huge, moving project?

## 

Certainly not by hand! We'll **_programmatically_** migrate the codebase.

- Automate as much as possible through **_code transformation_**
- Make the inevitable hand-modifications **_as easy as possible to rebase_**
- Perform the migration **_in steps_**, to make debugging and review easier
  - Not to mention, we don't want to lose our `git` history!

<img src="/img/clippy.png">

<style>
img {
    height: 50%;
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
- The tool automates **_everything_**

<br>

Like spoilers?

Watch the migration happen in real time:
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

# The transformation steps

---

# Step 1: Unindent

- We're moving all of our code up one block, and so there's one fewer indent!
- Do this early so later changes don't contain whitespace modification
  - Helps `git` track the code, and us review later changes

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

<Arrow x1="468" y1="260" x2="468" y2="310" color="orangered" />
<Arrow x1="243" y1="387" x2="243" y2="347" color="orangered" />

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

Thanks to the previous steps, all this step _appears_ to do is:

- Delete `namespace ts {}`
- Add an import

Everything else stays the same!

```diff
-namespace ts {
+import * as ts from "./_namespaces/ts";
+
 export function createSourceFile(sourceText: string): ts.SourceFile {
     const scanner = ts.createScanner(sourceText);
 }
-}
```

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

# Nested "namespace barrels"

## 

Namespaces can be nested, like:

```ts
// @filename: src/compiler/performance.ts
namespace ts.performance {
    export function mark(label: string) {/* ... */}
}
```

This too can be emulated using reexports:

```ts
// @filename: src/compiler/performance.ts
export function mark(label: string) {/* ... */}

// @filename: src/compiler/_namespaces/ts.performance.ts;
export * from "../performance";

// @filename: src/compiler/_namespaces/ts.ts
export * as performance from "./ts.performance";
```

---

# Merging "namespace barrels"

## 

To emulate project references and `prepend`, we can merge modules!

```ts
// @filename: src/server/_namespaces/ts.ts
export * from "../../compiler/_namespaces/ts";
export * from "../../services/_namespaces/ts";
export * from "../../deprecatedCompat/_namespaces/ts";

// @filename: src/server/project.ts
import * as ts from "./_namespaces/ts";
```

This "namespace barrel" provides a "view" per-project that mimics the `ts`
namespace we _used to_ observe before modules.

---

# Also, this gives us our public API!

## 

Say, `typescript.js`.

```ts
// @filename: src/typescript/_namespaces/ts.ts
export * from "../../compiler/_namespaces/ts";
export * from "../../services/_namespaces/ts";
export * from "../../deprecatedCompat/_namespaces/ts";

// @filename: src/typescript/typescript.ts
import * as ts from "./_namespaces/ts";

export = ts; // <-- This is what API consumers see!
```

Convenient!

---

# Step 4: Convert to named imports

## 

After step 3, we're left with fully qualified imports, like:

```ts
import * as ts from "./_namespaces/ts";

export function createSourceFile(sourceText: string): ts.SourceFile {
    const scanner = ts.createScanner(sourceText);
}
```

This step transforms the above into:

```ts
import { createScanner, SourceFile } from "./_namespaces/ts";

export function createSourceFile(sourceText: string): SourceFile {
    const scanner = createScanner(sourceText);
}
```

This is _almost_ our desired code, but still through "namespace barrels".

---

# ... and then draw the rest of the owl

## 

At this point, we're done with the bulk transformation.

But, we're not done yet!

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

- Our old outputs were a handful of large-ish bundles produced by `outFile`
  - Not looking to change the status quo quite yet
- Lots of bundlers to choose from; I went with `esbuild`
  ([esbuild.github.io](https://esbuild.github.io))
- Obviously, it's fast; ~200 ms to build `tsc.js`
- Features scope hoisting, tree shaking, enum inlining
  - Great for performance and package size
- We maintain a mode in our build which uses solely `tsc`, just to be sure

<img
  src="/img/esbuild.svg"
  alt="esbuild logo"
  height="87"
  width="100" />

<style>
img {
    height: 50%;
    margin-left: auto;
    margin-right: auto;
}
</style>

---

# Messing with `esbuild`'s output

## 

Before, our output looked like this, giving us both CommonJS and global script
support:

```ts
var ts;
(function(ts) {/* ... */})(ts || (ts = {}));
// ...
(function(ts) {
    // Remember this?
    if (typeof module !== "undefined" && module.exports) module.exports = ts;
})(ts || (ts = {}));
```

`esbuild` equivalent using `--format=iife --global-name=ts --footer="if ..."`:

```ts
var ts = (() => {
    // ...
    return {/* ... */};
})();
if (typeof module !== "undefined" && module.exports) module.exports = ts;
```

---

# `d.ts` bundling

- Along with "bundled" `.js` files, `tsc`'s `outFile` also produced `.d.ts`
  files
  - But now we're using esbuild, which doesn't produce `d.ts` files
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

# How did it go?

## 

Great! 👍

- Core development loop performance boost
  - New build is faster in general, and `esbuild` means we can skip typechecking
- Performance speedup from `esbuild`'s scope hoisting (10-20% or so)
- Package size reduction (63.8 MB -> 37.4 MB)
  - Tree shaking in bundles, 2 space indent, general cleanup
- Dogfooding!
  - Discovered and fixed a few auto-import bugs
  - Spawned an effort to better handle import organization and ecosystem
    integration
- `prepend` is deprecated; to be removed in TS 5.5

---

# What's next?

## 

There's no way I can fit all of this in, but:

- Shipping ESM?
  - Still some blockers, but looking hopeful!
  - Probably works for executables (`tsc`, `tsserver`, ...)?
  - Maybe an ESM API "for free"?
- Getting rid of `_namespaces`, somehow?
  - These also fix problems with cycles in our codebase, of which there are many
- Untangling things so we can be tree shaken?
- Minification? Other optimizers?
  - Downstream patchers make this challenging 😢

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
