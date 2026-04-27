# How to Write a Good SoCG / SODA-Style Paper

A comprehensive, practical guide to writing a theoretical-CS paper of
the kind that appears in SoCG, SODA, ESA, ICALP, STOC, FOCS, WADS,
ISAAC, and the journals *Algorithmica*, *Discrete & Computational
Geometry*, *SIAM Journal on Computing*, *Journal of the ACM*, *CGTA*,
and similar venues.

This guide assumes you have a result — an algorithm, a bound, a
construction, an experimental comparison — and that you have
*already* convinced yourself it is correct. It tells you how to
translate "I have a result" into "I have a paper a reviewer will
accept".

It is written as a companion to `bibliography_guide.md` in this
folder. Read that one for bibliography conventions; read this one
for everything else.

The running example throughout is a paper on the *Descending Greedy
Filter* (DGF) spanner, which is a real paper being written in this
directory (`dgf2.tex`). The specific examples are concrete because
generic writing advice is almost useless — every section below tells
you exactly what to do, shows you what it looks like, and then gives
you the DGF paper as a worked case.

---

## Table of contents

1. [Before you write a single word](#1-before-you-write-a-single-word)
2. [The anatomy of a theory paper](#2-the-anatomy-of-a-theory-paper)
3. [Title and abstract](#3-title-and-abstract)
4. [The introduction (the hardest section)](#4-the-introduction-the-hardest-section)
5. [Preliminaries and notation](#5-preliminaries-and-notation)
6. [Main technical sections: definitions, theorems, proofs](#6-main-technical-sections-definitions-theorems-proofs)
7. [Algorithms: pseudocode, correctness, complexity](#7-algorithms-pseudocode-correctness-complexity)
8. [Experiments, when you have them](#8-experiments-when-you-have-them)
9. [Related work](#9-related-work)
10. [Conclusion, open problems, acknowledgments](#10-conclusion-open-problems-acknowledgments)
11. [The appendix question](#11-the-appendix-question)
12. [Writing style: clarity, precision, voice](#12-writing-style-clarity-precision-voice)
13. [Mathematical notation and typography](#13-mathematical-notation-and-typography)
14. [Figures, tables, and algorithms blocks](#14-figures-tables-and-algorithms-blocks)
15. [The revision and review cycle](#15-the-revision-and-review-cycle)
16. [SoCG vs SODA vs journals: concrete differences](#16-socg-vs-soda-vs-journals-concrete-differences)
17. [Twenty mistakes that get papers desk-rejected or flamed](#17-twenty-mistakes-that-get-papers-desk-rejected-or-flamed)
18. [Final checklist](#18-final-checklist)

---

## 1. Before you write a single word

Writing the paper is the **last** step of research, but the first
step of writing. Before you open the `.tex` file:

### 1.1 Decide the one-sentence result

You must be able to state the contribution in **one sentence**, of
the form "We show that $X$ can be done with $Y$ guarantee, improving
the previous best of $Z$." If you can't, you don't yet have a paper
— you have a collection of observations.

Test: ask a colleague outside your subfield "what does your paper
say?" and answer in one sentence. If you need two, something is off.

For the DGF paper, the one-sentence result is:

> We introduce the Descending Greedy Filter (DGF), a new geometric
> $t$-spanner construction that processes edges in order of
> decreasing length, and show empirically that it produces sparser,
> lighter spanners than the classical greedy construction while
> preserving the exact stretch guarantee $t$.

Notice what this sentence does: it names the object (DGF), states
what it computes ($t$-spanner), and states the comparison baseline
(greedy spanner) with the axes of improvement (sparser, lighter)
and the thing that is *preserved* (exact stretch). A SoCG reviewer
reading this sentence knows immediately what your paper is about and
whether they want to read it.

### 1.2 Identify the target venue

The venue shapes everything — length, style, expected depth, typical
introduction length, and even *which* related work to cite. In rough
order of "how polished the paper needs to be":

- **arXiv preprint**: no page limit, no format, mostly for priority
  and dissemination. Low bar.
- **Workshop / short venue** (CCCG, EuroCG, ALENEX): 6–12 pages,
  lighter review, often no formal proceedings.
- **Mid-tier conference** (WADS, ISAAC, SWAT, LATIN, MFCS): 12–16
  pages LIPIcs, peer-reviewed, real proceedings.
- **Top conference** (SoCG, ESA, ICALP, STACS): 15–20 pages LIPIcs,
  heavy peer review, 2–3 reviewers per paper, 20–30% accept rate.
- **Very top conference** (SODA, STOC, FOCS, ITCS): 20–25 pages
  (SODA is often tighter), brutal peer review, 20–25% accept rate,
  reviewer rebuttal usually allowed.
- **Journal** (SICOMP, *Algorithmica*, *DCG*, *CGTA*): no page
  limit, 6–18 months of review, often two or three revision rounds.

The DGF paper as currently drafted is natural for **SoCG** (main
result is geometric, experiments are secondary), for **ESA Track A**
(algorithmic + experimental) or **ALENEX** (experimental-first), and
for the journal *Computational Geometry: Theory and Applications* as
a full version.

### 1.3 Know the prior work *completely* before you start

You should be able to draw, on a napkin, a timeline of the 10–20
most important papers in the area, who cites whom, and what each one
contributed. For spanners, the minimum is:

- Chew '89: Delaunay $\to$ first geometric spanner.
- Yao '82, Clarkson '87, Keil '88: Yao / $\Theta$ graphs.
- Althöfer–Das–Dobkin–Joseph–Soares '93 (ADDJS93): **greedy spanner**,
  sparsity $O(n)$, weight $O(\mathrm{wt}(\mathrm{MST}))$ for doubling metrics.
- Chandra–Das–Narasimhan–Soares '95 (CDNS95): leapfrog property.
- Das–Narasimhan–Salowe '95 (DNS95), Das–Heffernan–Narasimhan '93 (DHN93):
  weight bounds.
- Gudmundsson–Levcopoulos–Narasimhan '02 (GLN02): fast greedy-like
  constructions.
- Bose–Carmi–Farshi–Maheshwari–Smid '10 (BCFMS10): greedy spanner in
  near-quadratic time.
- Alewijnse–Bouts–ten Brink–Buchin '15 (ABBB15): greedy spanner in
  linear space.
- Filtser–Solomon '20 (FS20): existential optimality of greedy.
- Le–Solomon '22 (LS22): truly optimal Euclidean spanners.
- Borradaile–Le–Wulff-Nilsen '19 (BLW19): greedy is optimal in
  doubling metrics.
- Narasimhan–Smid '07 (NS07): the canonical textbook.

If you don't know this list cold, stop writing and go read.

### 1.4 Write an outline *before* the LaTeX

An outline is a bulleted list with:

- Every section and subsection title.
- Every theorem, lemma, and definition statement (one line each).
- Every figure, with a one-line caption.
- The single claim that each paragraph makes.

You should be able to read the outline in five minutes and get the
entire paper's logical structure. If you can't, the outline isn't
done.

---

## 2. The anatomy of a theory paper

Every SoCG/SODA paper has the same skeleton, which is a light
variant of the IMRAD structure used in empirical sciences. Sections
appear in this order, with these rough length budgets (for a 15-page
LIPIcs paper):

| Section | Length | Purpose |
|---|---|---|
| Abstract | 150–250 words | The one-paragraph version of the paper. |
| 1. Introduction | 2–4 pages | Motivate, state result, compare to prior, outline. |
| 2. Preliminaries / Notation | 0.5–1.5 pages | Fix definitions and notation. |
| 3. Main technical section(s) | 6–10 pages | Definitions, lemmas, theorems, proofs. |
| 4. Experiments (if any) | 1–3 pages | Empirical evidence. |
| 5. Related work | 1–2 pages | How this fits in; often folded into §1. |
| 6. Conclusion / Open problems | 0.5–1 page | What's left. |
| References | 1–2 pages | Typically 30–60 entries. |
| Appendix (optional) | Any length, doesn't count | Proofs, extra experiments. |

A common variant moves the related-work discussion to the end of
the introduction (§1.3 or §1.4 typically), and drops "Section 5"
entirely. In a 12-page ESA paper with tight limits this is
universal; in a 15-page SoCG paper either works.

The DGF paper as drafted in `dgf2.tex` follows this structure:

- Abstract (50 lines)
- §1 Introduction
- §2 Algorithm (= "Main technical section, part 1")
- §3 Conjectures for DGF
- §4 Minimal $t$-spanners (def.)
- §5 Filtering arbitrary spanners
- §6 Conjectures for minimal spanners
- §7 Binary-search implementation
- §8 Experiments
- §9 Related work + comparisons
- Bibliography

This is a correct and natural shape for a SoCG submission. The one
structural issue is that §3–§6 alternate "definition / conjecture /
algorithm", which makes the paper jump; a single "Conjectures"
section or a single "Theory" section would read more smoothly. See
§6.3 below.

---

## 3. Title and abstract

### 3.1 Title

A good title is:

- **Short**: 6–12 words.
- **Concrete**: names the object and the property, not the technique.
- **Self-contained**: someone who reads only the title should know
  roughly what the paper is about.
- **Non-cute, or only *mildly* cute**: "On …" is standard; a pun is
  fine if it doesn't sacrifice clarity; a title that requires
  reading the abstract to decode it is too cute.

Good:

- "Computing the Greedy Spanner in Near-Quadratic Time" — object
  (greedy spanner), property (near-quadratic-time computation).
- "The Greedy Spanner is Existentially Optimal" — object, property,
  punchy.
- "Geometric Spanner Networks" — a textbook title; wouldn't work for
  a paper.
- "Descending Greedy Filter: A New Construction for Light Geometric
  Spanners" — for DGF this would beat the current "Descending Greedy
  Filter" because it names the property being optimized (lightness).

Bad:

- "A New Approach to Spanners" — says nothing.
- "On Some Properties of Certain Filtered Spanners" — hedged,
  vague, negative signal.
- "SPANNERIZER: A Framework for Spanner Construction" — the framing
  is wrong for CG theory (even if fine for systems).

### 3.2 Abstract

The abstract is the single most-read paragraph of the paper. Every
program-committee member and every reviewer reads it; many readers
read nothing else. Structure:

1. **Sentence 1 — the object**: "A geometric $t$-spanner of a point
   set $P$ is a graph in which..." Define the setting.
2. **Sentence 2 — the gap**: "Known constructions achieve $X$; it
   is open whether $Y$ is possible." State what's missing.
3. **Sentences 3–5 — the result**: "We introduce the Descending
   Greedy Filter (DGF), ... We prove/show/conjecture that ..."
4. **Sentences 6–7 — the technique**: one sentence on *how*,
   one sentence on *why it matters*.
5. **Sentence 8 — the experiments / corollaries / extensions**:
   optional.

Do **not** use the abstract for motivation, for anecdotes, for
historical context, or for acknowledgments. It is 150–250 words of
technical content.

The current DGF abstract:

```
We present a new construction of geometric spanners, which we call
the Descending Greedy Filter (DGF). [...] Experiments on random
point sets in the unit square with n in {2000, 5000} and
t in {1.01, 1.1, 1.5} show that DGF and its variants consistently
produce spanners with fewer edges and lower total weight than the
classical greedy spanner, while preserving the exact stretch
guarantee.
```

This is a good abstract — it states the object, the result, the
conjectures, and the experimental evidence. It could be tightened in
one direction: the algorithmic complexity of the binary-search
implementation (one of the real technical contributions) is buried
at the end; moving it to the second-from-last sentence would improve
its salience.

### 3.3 A rule of thumb for the abstract

Draft the abstract **last**, not first. It is the condensation of a
finished paper, not its seed. Many experienced authors rewrite the
abstract three or four times during the revision phase, because each
pass through the paper sharpens what the core result actually is.

---

## 4. The introduction (the hardest section)

The introduction is where papers are accepted or rejected. A strong
result with a weak introduction often gets rejected; a modest result
with a strong introduction often gets accepted. You should spend
20–30% of your writing time here.

### 4.1 The funnel structure

The canonical shape for a theory-paper introduction is a **funnel**
that moves from the general to the specific in four to six stages:

1. **Broad motivation** (1 paragraph). What is the object, why does
   anyone care? "Geometric spanners are a central object in
   computational geometry, with applications to network design,
   approximation algorithms, ..."
2. **The specific problem** (1–2 paragraphs). What *specific*
   question are you asking? Why is it open? "The greedy spanner is
   widely regarded as the state of the art. However, ..."
3. **Your contribution** (1 paragraph). What do *you* do? State the
   results crisply, as a bulleted or itemized list if there are
   several.
4. **Technical overview / key ideas** (1–2 paragraphs). *How* do you
   do it? What is the main insight? (This is the paragraph that
   reviewers reread before writing the review — make it count.)
5. **Related work** (1–2 paragraphs, or a subsection). How does
   this compare to prior work? This is often §1.3 or §1.4, not a
   separate top-level section.
6. **Paper organization** (3–5 lines). "The rest of the paper is
   organized as follows: §2 ..., §3 ..."

For a 15-page paper the entire introduction is 2–4 pages (roughly
1200–2400 words).

### 4.2 Concrete template for §1

Below is a skeleton you can fill in. Each line is one paragraph.

> **¶1** *(motivation)* — What is a spanner, why do we care, one
> canonical application.
>
> **¶2** *(the landscape)* — The greedy spanner is the gold
> standard. We summarize its guarantees: $O(n)$ edges,
> $O(\mathrm{wt}(\mathrm{MST}))$ weight, stretch $t$, $O(n^2 \log n)$
> time.
>
> **¶3** *(the question)* — Can we do *strictly better* than greedy
> in practice? Empirical work \cite{FG09, ABBB15} shows greedy
> dominates — but does "dominates" mean "is optimal among minimal
> $t$-spanners"?
>
> **¶4** *(our contribution, bulleted)* — We:
>   - introduce DGF, a descending-order dual to greedy;
>   - define *minimal* $t$-spanners and conjecture $O(n)$ edges and
>     $O(\mathrm{wt}(\mathrm{MST}))$ weight for *every* minimal
>     $t$-spanner (not just greedy);
>   - give a binary-search implementation that reduces APSP calls;
>   - empirically show DGF beats greedy on both metrics.
>
> **¶5** *(the key idea)* — Why does DGF work? The insight is
> that removing the longest useless edge first lets shorter edges
> "inherit" its role, which greedy cannot do.
>
> **¶6** *(related work)* — Pointer-dense tour of the spanner
> literature, grouped by theme (greedy, alternative constructions,
> experimental studies, minimality).
>
> **¶7** *(organization)* — "Section 2 …, Section 3 …, …"

### 4.3 The "contribution paragraph" is sacred

Every reviewer looks for this paragraph and will quote from it. It
should answer three questions **explicitly**:

1. **What is new?** (Never leave this implicit.)
2. **Why is it non-trivial?** (Say this directly: "The main
   difficulty is …".)
3. **What is the comparison to the best prior result?** (Give a
   precise quantitative statement: $O(n^2)$ vs. $O(n^2 \log n)$,
   sparsity $2.5n$ vs. $1.8n$, etc.)

Bad:

> We propose a new spanner construction and show it has good
> properties.

Good:

> We introduce the Descending Greedy Filter (DGF). Unlike the
> greedy spanner, which processes edges in ascending order of
> length, DGF starts with the complete graph and removes edges in
> descending order whenever doing so preserves the stretch. We
> prove DGF produces a $t$-spanner in $O(n^2)$ space and
> $O(n^5)$ time via naive APSP, which we reduce to
> $O(k \log n \cdot T_{\mathrm{APSP}})$ via a recursive binary
> search where $k$ is the number of output edges. We conjecture,
> and empirically verify on random point sets, that DGF has
> $O(n)$ edges and total weight $O(\mathrm{wt}(\mathrm{MST}))$ —
> matching greedy — and that on average it achieves **3–8% fewer
> edges and 2–5% lower total weight** than greedy for $t$ in
> $\{1.01, 1.1, 1.5\}$.

The italicized numbers are what a program-committee member will
remember. Be specific.

### 4.4 The "technical overview" paragraph

For a strong SoCG/SODA submission, include a paragraph that
**sketches the key proof idea or algorithmic trick in English
prose**. This is different from the contribution paragraph: it tells
the reader *why the result is true*, not *what it says*.

Format:

> The key observation is that [one-sentence insight]. More
> precisely, [two or three sentences that make this insight
> technical, with named objects]. The resulting algorithm [one
> sentence on shape]; the main difficulty is [one sentence on the
> hard part], which we overcome by [one sentence on the trick].

A reviewer reading this paragraph should be able to reconstruct, at
a high level, why the theorem is true. If they cannot, either the
paragraph is too vague or the result really is opaque.

---

## 5. Preliminaries and notation

### 5.1 What goes here

- **Notation**: $P = \{p_1, \dots, p_n\}$, $|pq|$ for Euclidean
  distance, $\delta_G(p, q)$ for graph distance, $\mathrm{wt}(G)$
  for total edge weight, $G[S]$ for induced subgraph, etc.
- **Definitions of standard objects**: what a $t$-spanner is, what
  the stretch factor is, what a doubling metric is. Even if "every
  reader knows", writing it down fixes your specific choice.
- **Assumptions that hold for the entire paper**: "Throughout, $P$
  is in general position (no three collinear, no four cocircular)."
- **One-line reminders** of well-known theorems you will use: WSPD,
  Callahan–Kosaraju, leapfrog.

### 5.2 What does *not* go here

- Long historical surveys — those go in related work.
- Proofs — those go in the technical section.
- Anything you will use only once — fold it into the section that
  uses it.

### 5.3 A good test

If the preliminaries section is more than 1.5 pages for a SoCG
paper, it is probably doing too much. Either you are over-explaining
known material, or you have accidentally started the technical
development.

---

## 6. Main technical sections: definitions, theorems, proofs

This is the bulk of the paper (6–10 pages). The conventions here are
strong; deviating from them makes reviewers suspicious.

### 6.1 The definition / lemma / theorem / proof rhythm

A technical section develops material in a regular rhythm:

1. **Informal motivation** (one paragraph): "We would like to
   show X. Intuitively, the reason X holds is …"
2. **Definition(s)** of new objects, stated formally.
3. **Lemma(s)** establishing technical building blocks.
4. **Proof(s)** of the lemmas, marked by `\begin{proof} … \end{proof}`.
5. **Theorem**: the main result of the section.
6. **Proof of the theorem**, typically using the lemmas.
7. **Corollaries or remarks**: immediate consequences.

Do not prove a theorem "inline" in the middle of a paragraph. Every
non-trivial statement gets a labeled environment.

### 6.2 Numbering and labeling

Use a **single counter** shared between theorems, lemmas, and
corollaries, so a reader can find "Theorem 3.4" by scanning for
either "3.4" or "Theorem 3.4":

```latex
\newtheorem{theorem}{Theorem}[section]
\newtheorem{lemma}[theorem]{Lemma}
\newtheorem{corollary}[theorem]{Corollary}
\newtheorem{proposition}[theorem]{Proposition}
\theoremstyle{definition}
\newtheorem{definition}[theorem]{Definition}
\theoremstyle{remark}
\newtheorem{remark}[theorem]{Remark}
```

Every labeled environment gets a `\label{thm:name}` with a
type-prefix (`thm:`, `lem:`, `def:`, `cor:`, `conj:`), and is
referenced by `\cref{thm:name}` using the `cleveref` package (which
adds the word "Theorem" automatically and consistently).

### 6.3 Proof style

A SoCG/SODA proof is **complete and concise**, in that order. The
aim is that a graduate student familiar with the area can read the
proof linearly and verify every step; you do not write for your
supervisor.

Proof structure:

- **State what is being shown**, if it is not obvious from context:
  "We show that $G$ is a $t$-spanner."
- **Name the structure of the argument**: "by induction on $n$", "by
  case analysis on the position of $p$", "by contradiction, suppose
  …", "by a reduction to Lemma 3.2".
- **Deduce the conclusion**, step by step, in full sentences that
  happen to contain equations. Do not let a string of equations do
  the work of a proof — each equation is justified by the
  surrounding prose.
- **End with `\end{proof}`**, which produces a `∎` by default.

Example of a clean proof (lightly adapted from a DGF lemma):

> **Lemma 3.2.** *If $E$ is the edge set held by DGF at any point
> during its execution, then $(P, E)$ is a $t$-spanner of $P$.*
>
> *Proof.* By induction on the number of iterations completed. At
> iteration $0$, $E$ is the complete graph, which is trivially a
> $t$-spanner. Assume the claim after $i$ iterations. In iteration
> $i + 1$, DGF considers a candidate edge $e$ and tentatively
> removes it. If the resulting graph is still a $t$-spanner, the
> invariant is maintained; if not, DGF restores $e$ and $E$ is
> unchanged. In either case the invariant holds after $i + 1$
> iterations. Taking $i = |L|$ gives the claim. ∎

Note the features: named structure ("by induction"), explicit
invariant, full sentences, and a last sentence that closes the loop
on the induction.

### 6.4 The "conjecture" environment

When you have not proved a result but believe it strongly, state it
as a `\begin{conjecture}`, give the experimental or partial
theoretical evidence immediately after, and **do not dress it up as
a theorem**. A conjecture clearly labeled as such is fine in a SoCG
paper (several of Carmi's papers state open conjectures); a
conjecture called a theorem is a career-limiting move.

The DGF paper correctly uses this pattern:

```latex
\begin{conjecture}[sparsity of DGF]\label{conj:dgf-edges}
|E_f| = O(n).
\end{conjecture}
```

A good convention: **one `conjecture` per paper, rarely two**. If
you have four conjectures, merge them into one "unifying conjecture"
with several parts; otherwise the paper looks speculative.

### 6.5 Structural tip: one theme per section

Each section should have a single headline result. If §3 is "the
algorithm runs in $O(n^2)$ time" and §4 is "the output has $O(n)$
edges", do not intermix. If §3 is about DGF and §4 is about the more
general filtering procedure, the sparsity and weight conjectures for
both can go in a *single* unified §5, not split across §3 and §6.
This is the one restructuring I would recommend for the DGF
paper as currently drafted.

---

## 7. Algorithms: pseudocode, correctness, complexity

A clean algorithmic contribution has three parts: pseudocode, a
correctness argument, and a complexity analysis. Each gets its own
labeled subsection.

### 7.1 Pseudocode conventions

- Use `algorithmic` or `algpseudocode` (already in `dgf2.tex`), not
  ad-hoc `verbatim`.
- **Name every variable** with a meaningful letter or short word.
  Use $E$ for an edge set, $G$ for a graph, $P$ for a point set,
  $p_i$ for a point. Never `x`, `y`, `aux1` in pseudocode.
- Include **input and output declarations**:

  ```latex
  \Statex \textbf{Input:} A point set $P \subset \mathbb{R}^d$, a
          stretch $t > 1$.
  \Statex \textbf{Output:} An edge set $E$ such that $(P, E)$ is a
          $t$-spanner of $P$.
  ```

- **Number lines** (`\begin{algorithmic}[1]`) so you can refer to
  "line 7 of Algorithm 2".
- Keep pseudocode **under one column height** when possible. A
  three-page pseudocode block is a signal that the algorithm isn't
  yet cleanly factored; extract a sub-procedure.

### 7.2 Correctness

A correctness subsection proves that the algorithm returns an object
with the stated property. It typically proceeds by identifying a
**loop invariant**, proving it is established, preserved, and
implies the postcondition.

For DGF the invariant is "$(P, E)$ is a $t$-spanner of $P$", and the
correctness argument is almost trivial because the check-and-revert
structure enforces the invariant directly. That is a *good* thing:
simple correctness is a feature. Do not inflate it.

### 7.3 Complexity

Give **both** the worst-case bound and, if relevant, a bound in
terms of output size. For DGF:

$$
   T_{\mathrm{DGF}}(n, m, k)
   \;=\; O\bigl(m \log m\bigr)
         \;+\; O\bigl(m \cdot T_{\mathrm{APSP}}(n, m)\bigr)
         \;=\; O(n^5)
$$

with $m = \Theta(n^2)$, and the binary-search variant reduces the
second term to $O(k \log m \cdot T_{\mathrm{APSP}})$ where $k$ is
the output size.

Always state:

- **Time**, **space**, and when relevant **number of oracle calls**.
- What you are measuring against (RAM model, pointer machine,
  algebraic decision tree).
- Any hidden dependence on $t$, dimension $d$, or the spread of the
  point set.

### 7.4 Extraction: the "oracle" pattern

Many spanner algorithms use an APSP check or a distance oracle as a
subroutine. Make this explicit: define an oracle $\mathcal{O}$
with a well-typed interface, and state both a generic bound in
terms of $T_{\mathcal{O}}$ and a concrete bound when you plug in a
specific implementation. This is the pattern used in BCFMS10 and
ABBB15, and it is what the DGF paper does correctly.

---

## 8. Experiments, when you have them

Not every SoCG paper has experiments; many have none. But **when you
do**, the experimental section has strong conventions.

### 8.1 What an experimental section must report

1. **Hypothesis**: a concrete, falsifiable claim. "DGF produces
   fewer edges than greedy on random point sets in the unit square
   for $t \in \{1.01, 1.1, 1.5\}$."
2. **Instance generator**: what inputs you test on, with the random
   seed or the recipe to regenerate. "Points are drawn uniformly
   iid from $[0, 1]^2$; we average over 100 trials per
   configuration."
3. **Implementation**: language, platform, machine, optimization
   level, library versions. "Julia 1.10 on macOS; LightGraphs.jl
   for Dijkstra; single-threaded."
4. **Measured quantities**: edge count, total weight, wall-clock
   time, possibly memory.
5. **Plots and tables**, with error bars or min/max bands.
6. **Conclusion**: *exactly what the data shows*, with no
   over-claiming. "DGF produces 3–8% fewer edges than greedy
   across all tested configurations; the gap narrows as $t \to 1$."

### 8.2 Reproducibility

The experimental section should make a third-party reproduction
*possible in principle*:

- Give the pseudocode of the data-generation procedure in an
  appendix, or give the exact parameters.
- Publish the code (GitHub, archived with a Software Heritage or
  Zenodo DOI) and cite it from the paper.
- Report **every** experimental parameter, including the
  tie-breaking rule when multiple edges have the same length.

A reader should be able to regenerate your main table by running
your code with the parameters you state, **and get numbers within
the statistical error you report**.

### 8.3 What *not* to do

- Do not claim a theoretical bound on the strength of experimental
  evidence alone. "We conjecture that …, supported by experiments
  in §8" is fine; "We show that …, as demonstrated in §8" is not.
- Do not present only the best-case instance. Report the worst
  instance you encountered, especially if the method fails on it.
- Do not use log-scale y-axes without saying so.
- Do not report "DGF is 10× faster" when the baseline is a naive
  implementation of greedy; compare against the best known
  implementation (BCFMS10 for greedy, ABBB15 for linear-space
  greedy).

### 8.4 Table vs plot

- Use a **table** when exact numbers matter (e.g. you want to claim
  "DGF produces 0.97× the edges of greedy"). Tables are dense and
  reviewer-friendly when the number of configurations is small (≤ 12).
- Use a **plot** when the shape of the dependence matters (edges
  vs. $n$, weight vs. $t$). Always label axes, include units, and
  use distinguishable markers (not just colors — the paper will be
  printed in black and white).

---

## 9. Related work

### 9.1 Where it goes

Two locations are standard:

- **Inside §1** (as §1.3 or §1.4): for a short paper (ESA 12 pages),
  or when your contribution is most clearly understood as a
  comparison to a small number of specific prior works.
- **As its own section near the end** (§9 or §10): for a longer
  paper, or when the prior landscape is rich enough to deserve a
  couple of pages.

The DGF paper uses the second pattern, with a subsection
"§9 Edge-minimality, filtering, and empirical comparisons". That is
appropriate because the landscape is large (greedy, leapfrog,
minimality, experimental studies).

### 9.2 How to write it

Group references by theme, not chronologically. Each theme is one
paragraph:

> **Greedy and its variants.** The greedy spanner is due to ADDJS93,
> with weight and sparsity bounds tightened in CDNS95, DNS95. Fast
> constructions: BCFMS10 (near-quadratic time), ABBB15 (linear
> space). Optimality: FS20 (existentially optimal), LS22
> (truly optimal), BLW19 (doubling metrics).
>
> **Experimental studies.** FG09 compared the main constructions
> on random and clustered point sets, finding greedy dominant on
> every quality metric except construction time; ABBB15 extended
> this to $10^6$ points.
>
> **Minimality and filtering.** The leapfrog property (CDNS95, DHN93,
> DNS95) implies minimality in a strong sense; every leapfrog edge
> set is edge-minimal, but the converse fails. Sigurd–Zachariasen
> SZ04 gave an ILP-based exact algorithm for minimum-weight
> $t$-spanners.

This is the right *register* for related work: pointer-dense, fair,
and organized by conceptual thread.

### 9.3 How much to cite

A SoCG paper has 30–50 references; a SODA paper has 40–70. If you
cite 15, you are under-grounded. If you cite 200, you are showing
off and some reviewer will say so. The right number is **enough that
no reader in the area is surprised by a missing citation, and no
citation is there just to pad**.

### 9.4 The golden rule: cite work you want to argue with

If someone has a paper whose result is close to yours, **cite it and
explain the difference**. Do not hope no one notices. Reviewers
*always* notice, and the review will say so. Example:

> Sigurd and Zachariasen SZ04 solve the *minimum-weight* $t$-spanner
> problem exactly via ILP; our goal is different: we want an
> algorithm that runs in polynomial time and whose output is
> provably minimal, even if not minimum-weight. The two are related
> but not the same: every minimum-weight $t$-spanner is minimal,
> but not conversely.

This paragraph preempts a reviewer who would otherwise write "why
don't you compare to SZ04?" in the report.

---

## 10. Conclusion, open problems, acknowledgments

### 10.1 Conclusion

The conclusion is short — usually half a page to a page — and does
three things:

1. **Summarize the contribution** in one paragraph, at a higher
   level than the abstract. "We introduced …; the main technical
   content was …; experiments suggest …"
2. **Pose open problems**, ideally phrased as concrete conjectures
   or directions. "Can the sparsity of every minimal $t$-spanner
   be shown to be $O(n)$?" is a sharper open problem than "future
   work could investigate sparsity".
3. **Optionally, briefly discuss limitations** — things your method
   does *not* do that a reader might want.

### 10.2 Open problems

This is where most readers actually *finish* the paper. A good open
problem is:

- **Concrete**: states a specific question, not "it would be
  interesting to study …".
- **Open**: not already solved in an obscure paper you forgot to
  cite.
- **Within reach**: something a reader might plausibly attack.
- **Flagged for importance**: "The most natural open question is
  …" — tell the reader which one you think is hardest.

For DGF the obvious one is:

> The main open question is whether Conjectures
> \ref{conj:dgf-edges}, \ref{conj:dgf-weight} hold. We know by FS20
> that the greedy spanner is existentially optimal up to a constant;
> it is natural to ask whether *every* minimal $t$-spanner has the
> same sparsity and weight guarantees up to a (possibly larger)
> constant.

### 10.3 Acknowledgments

Short. Name your grant (ISF, BSF, NSF, ERC), thank collaborators who
did not make authorship, thank anonymous reviewers in the journal
version. Do not thank your cat.

---

## 11. The appendix question

Conferences in this community allow appendices, with a strict
convention: the appendix **may not be required reading** for the
committee. A reviewer must be able to accept the paper based on the
main body alone. In practice this means:

- All theorem **statements** go in the main body.
- Lemma and theorem **proofs** may go in the appendix, if the main
  body contains a proof sketch that would convince an expert.
- Additional experiments may go in the appendix.
- Completely independent results should be *excluded*, not
  appendixed.

For SoCG and ESA the appendix is standard; for SODA and STOC
appendices are allowed but reviewers are explicitly told "you are
not required to read the appendix", so anything essential *must* be
in the 15–20 page main body.

For the journal version, there is no appendix — everything goes in
the body, and the paper grows to 30–50 pages.

---

## 12. Writing style: clarity, precision, voice

This is the section most authors skip. Don't.

### 12.1 Precision over elegance

A theory paper is read slowly, often twice. Sentences that are
*almost correct* are worse than sentences that are blunt but
correct.

Bad: "DGF removes edges to make the spanner small."
Better: "DGF removes every edge whose removal keeps the graph a
$t$-spanner, processing edges in order of decreasing length."

### 12.2 Active voice, but impersonal

The default voice in CS theory is **first-person-plural active**:
"We show …", "We prove …", "We conjecture …". Not:

- "It is shown that …" (passive, evasive).
- "The author shows that …" (third-person; only in single-author
  thesis-style writing).
- "I show that …" (first-person singular; only in some cover
  letters and blog posts).

Algorithms and theorems use the impersonal **descriptive
present**: "Algorithm 1 sorts the edges in non-ascending order. It
then iterates over the sorted list …". Not "Algorithm 1 will sort
…" and not "Algorithm 1 sorted …".

### 12.3 Tense

- **Results (yours or others')**: present tense. "BCFMS10 show
  that the greedy spanner can be computed in $O(n^2 \log n)$
  time." — note "show", not "showed".
- **History**: past tense. "In 1993, Althöfer et al. introduced the
  greedy spanner."
- **Our paper's structure**: present tense. "In §4 we prove …".

### 12.4 Word economy

A theory paper is not a novel. Every sentence carries a theorem, a
definition, or a pointer. Ruthlessly delete:

- "It should be noted that …" — just state the thing.
- "In this paper we …" — usually the "in this paper" is redundant.
- "Very", "quite", "rather" — vague intensifiers.
- "Obviously", "clearly", "trivially" — if it really is obvious,
  you don't need to say so; if it isn't, the reviewer will resent
  you.
- "As we shall see below" — `\cref{...}` does this more
  precisely.

### 12.5 Words that have specific meanings

| Word | Use for |
|---|---|
| *Theorem* | A main result, proved, of independent interest. |
| *Lemma* | A technical step used to prove a theorem. |
| *Proposition* | A mid-weight result; some authors use this as a junior theorem. |
| *Corollary* | Immediate consequence of a theorem or lemma. |
| *Observation* | A short, easy fact stated for reference. |
| *Claim* | A tiny sub-assertion inside a proof. |
| *Conjecture* | A statement the author believes but cannot prove. |
| *Remark* | Contextual note; not used later in the paper. |

Do not call a lemma a theorem to make it sound important. Do not
call a theorem a lemma to sound modest.

Similarly:

- *Running time* = asymptotic time in a given model; different from
  *wall-clock time* (what your experiments measure).
- *Optimal* without qualification means "matches a lower bound";
  otherwise say "best known" or "most efficient".
- *Trivial* means "following immediately from the definitions", not
  "easy enough that I don't want to write it".

### 12.6 Hedging

Avoid weasel hedges ("to some extent", "in a certain sense",
"arguably"). If you need to hedge a claim, do it precisely:

Bad: "DGF is roughly as efficient as greedy."
Good: "DGF and greedy both run in $O(n^2 \cdot T_{\mathrm{APSP}})$
time in the worst case; on random inputs, the constants differ by a
factor of 1.2 in our experiments (§8)."

---

## 13. Mathematical notation and typography

### 13.1 Core conventions

- **Variables in math mode**: always `$n$`, never `n`, in prose.
- **Functions are upright if standard**: `\log`, `\exp`, `\min`,
  `\max`, `\deg`, `\rank`. Use `\operatorname{...}` or pre-defined
  macros for custom ones (`\operatorname{wt}`, `\operatorname{MST}`,
  `\operatorname{diam}`).
- **Sets with named elements**: `P = \{p_1, \dots, p_n\}`, not
  `P = \{p_1, ..., p_n\}` (three dots `\dots` is context-aware).
- **Absolute value / norm disambiguation**: `|pq|` for Euclidean
  distance is idiomatic in CG; `\|v\|` for vector norm; $|S|$ for
  set cardinality.
- **Graph distance**: `\delta_G(p,q)` or `d_G(p,q)` are both
  standard; pick one and stick with it.
- **Complexity notation**: `$O(n^2 \log n)$` with a space before
  $\log$, not `O(n^2\log n)`. Use `$\Theta$` and `$\Omega$` where
  they are meant, not as fancier-looking $O$'s.

### 13.2 Macros for your paper

Define at the top of the preamble the objects you use repeatedly:

```latex
\newcommand{\spanner}{t\text{-spanner}}
\newcommand{\wt}{\operatorname{wt}}
\newcommand{\MST}{\operatorname{MST}}
\newcommand{\APSP}{\operatorname{APSP}}
\DeclareMathOperator{\poly}{poly}
```

Then write `$\wt(\MST(P))$` consistently. If you change your mind
about the notation (say, $W(T)$ vs. $\wt(T)$), a single macro change
updates the whole paper. The current `dgf2.tex` writes
`\mathrm{wt}(\mathrm{MST}(P))` everywhere, which works but is
verbose.

### 13.3 Equations

- **Display** nontrivial equations with `\[ … \]` or `\begin{align}
  … \end{align}`.
- **Number** equations only if you reference them. Use
  `\begin{equation}\label{eq:foo}…\end{equation}` when needed and
  refer as `\cref{eq:foo}`.
- **Align** long equation chains by the relation symbol:

  ```latex
  \begin{align*}
    \wt(E_f) &\le \sum_{e \in E_f} |e| \\
             &\le t \cdot \wt(\MST(P)) \cdot \log n \\
             &= O(\wt(\MST(P))).
  \end{align*}
  ```

- **End with a period** if the equation ends the sentence, and with
  **no punctuation** otherwise. Equations are part of the sentence,
  not stand-alone objects.

---

## 14. Figures, tables, and algorithms blocks

### 14.1 Figures

- **Every figure has a caption that makes sense on its own.** A
  reader flipping through the paper should be able to understand
  the figure from the caption alone.
- **Use vector graphics (PDF / SVG / TikZ), not PNG/JPG**, unless
  the figure is a screenshot. Raster images pixelate in print.
- **Minimum font size in the figure = the caption font size.**
  Don't use 6pt axis labels when the body text is 10pt.
- **Label axes with units.** "time (s)" not "time"; "$n$ (number of
  points)" not "$n$".
- **Color should be supplementary.** Use distinct markers or line
  styles as well; reviewers print papers in black and white.
- **Put figures at the top of the page** (`\begin{figure}[t]`),
  except for the very first figure if it serves as a "graphical
  abstract".

### 14.2 Tables

Use `booktabs` (already loaded in `dgf2.tex`) and never `\hline`:

```latex
\begin{table}[t]
\centering
\begin{tabular}{lrrr}
\toprule
$n$ & greedy edges & DGF edges & ratio \\
\midrule
 500 & 1842 & 1803 & 0.979 \\
2000 & 7398 & 7120 & 0.962 \\
5000 &18591 &17834 & 0.959 \\
\bottomrule
\end{tabular}
\caption{Edge counts for greedy vs DGF at $t = 1.1$,
averaged over 100 uniform-random point sets in $[0,1]^2$.}
\label{tab:edges-t11}
\end{table}
```

Rules:

- Right-align numbers, left-align text.
- Decimal points aligned in a column (use `siunitx` for
  finer control).
- One row per logical observation.
- Caption above or below is fine; pick one and be consistent.

### 14.3 Algorithm blocks

Already covered in §7.1. Two additions:

- A good algorithm block is **readable without reading the body**.
  A reader should be able to trace through it with paper and pencil.
- The first algorithm block is the flagship one. If possible, make
  it fit on a single page *with* its caption and immediately
  following paragraph of explanation.

---

## 15. The revision and review cycle

### 15.1 Before submission

- **Put the paper down for 48 hours**, then reread. Most typos and
  many thinkos will jump out.
- **Have someone outside the project read the abstract and §1**.
  If they can't tell what the result is, rewrite.
- **Run `chktex` or `lacheck`**: finds mechanical LaTeX issues.
- **Compile the bibliography from scratch**: `rm *.aux *.bbl *.blg;
  pdflatex …; bibtex …; pdflatex …; pdflatex …`. Any citation
  warning is a bug.
- **Read the PDF on paper** (or at 100% zoom on a tablet). Things
  look different than on your editor screen.
- **Check page limit with margins**: the venue's `.cls` enforces
  this; do not hack it by shrinking fonts or margins.

### 15.2 During review

- You don't see reviews for most venues until the decision.
- For SODA / STOC / FOCS there is often a **rebuttal phase**: you
  get reviews and have 500–1000 words to respond. Use it to:
  - Correct factual mistakes in the reviews.
  - Clarify points the reviewer misunderstood.
  - **Not** to argue with the reviewer's taste.
  - **Not** to promise future work.

### 15.3 After reject

- Read every review carefully, including the hostile ones.
- 80% of every review contains a valid criticism, even if wrapped
  in unpleasant language.
- The next submission, to a different venue or a journal, is
  always better because of the reviews.

### 15.4 After accept

- You have a week or two to prepare the camera-ready. Use it:
  - Fix every typo in the reviews.
  - Rewrite the 2-3 paragraphs that reviewers flagged as confusing.
  - Tighten the bibliography (see `bibliography_guide.md`).
- Submit the arXiv version simultaneously with the camera-ready,
  not 6 months later.

### 15.5 After the conference: the journal version

Almost every top-tier conference paper gets a journal version:

- **Merge the appendix into the body.** No more "proof in appendix".
- **Add full proofs** of everything that had only a sketch.
- **Expand the related work** with anything published in the
  intervening months.
- **Update experiments** with more instances / more baselines if
  you have them.
- **New title is allowed but discouraged.** Usually just reuse the
  conference title.

---

## 16. SoCG vs SODA vs journals: concrete differences

| Axis | SoCG (LIPIcs) | SODA (SIAM) | Journal (*Algorithmica, SICOMP, DCG*) |
|---|---|---|---|
| Page limit | 15 + appendix | 20 + appendix | None |
| `.cls` file | `lipics-v2021.cls` | `soda.cls` or `acmart` | `article`, `svjour3`, `siamart` |
| Bib style | `plainurl` | `siamplain.bst` | venue-specific |
| Citation style | numeric `[12]` | numeric `[12]` | numeric or author-year |
| Author names in refs | first-last | **SMALL CAPS** last names | varies |
| Anonymization | **no** | **no** | no |
| Rebuttal | no | yes | author reply to referee reports |
| Timeline, submit → decision | 3 months | 3 months | 6–18 months |
| Typical reference count | 30–50 | 40–70 | 60–150 |
| Abstract length | 150–250 words | 150–250 words | 200–400 words |
| Appendix allowed | yes, reviewer-optional | yes, reviewer-optional | no (folded in) |

Practical note: **most SoCG papers that are good also fit SODA**,
and vice versa. Choose based on taste (SoCG is more geometric, SODA
is more combinatorial-optimization), paper length (SODA gives you
more pages), and timing.

---

## 17. Twenty mistakes that get papers desk-rejected or flamed

1. **Title makes no claim.** ("On some properties of …")
2. **Abstract doesn't state the result.** Motivation only.
3. **No comparison to the best prior result.** Reviewers always
   look for this.
4. **Result is stated only qualitatively** ("significantly faster")
   without a bound.
5. **A conjecture stated as a theorem.** Career-limiting.
6. **A theorem stated, but proof only "easy to see".**
7. **Overlapping with own prior work without disclosure.**
   Self-plagiarism gets papers desk-rejected.
8. **Missing a 20-year-old canonical citation.** (For spanners:
   ADDJS93, KG92, NS07.)
9. **Misattributing a result.** Double-check who proved what.
10. **Plots with missing axis labels or unlabelled curves.**
11. **Pseudocode with nameless variables or magic constants.**
12. **Experiments that aren't reproducible.** No seed, no code link,
    no parameter list.
13. **Claiming empirical evidence proves a theorem.** It doesn't.
14. **Exceeding the page limit by shrinking fonts or margins.**
    Automatic desk-reject.
15. **Anonymization failures** at double-blind venues: leaving your
    name in the PDF metadata, citing your own prior work as "in
    our previous paper …".
16. **Broken LaTeX warnings** in the final PDF (overfull boxes,
    missing references, `??`).
17. **"Submitted to X" in the bibliography** — either published
    (cite), on arXiv (cite), or don't cite.
18. **Inconsistent notation** across sections. Define once, use
    everywhere.
19. **Too-clever cross-referencing.** A paper that says "see
    Lemma 3.2" and Lemma 3.2 says "see Lemma 4.7" and Lemma 4.7
    says "see Lemma 3.2". Linearize it.
20. **Ending with "More work is needed"**. Replace with a concrete
    open question.

---

## 18. Final checklist

Run through this before every submission. It takes 10 minutes and
saves days.

- [ ] **Title** is short, concrete, and states the object.
- [ ] **Abstract** states object, gap, result, technique, and
      (if applicable) experiments, in 150–250 words.
- [ ] **Contribution paragraph** in §1 is bulleted, with quantitative
      comparison to the best prior result.
- [ ] **Technical overview paragraph** in §1 sketches the key idea
      in prose.
- [ ] **Related work** is grouped by theme, not by year, and names
      every canonical prior paper a reader in the area would expect.
- [ ] **Theorem, lemma, definition** environments share a counter
      and are labeled with type prefixes.
- [ ] **All `\cite{}` resolve** and all `\ref{}` / `\cref{}` resolve.
- [ ] **Bibliography** is generated by BibTeX from a `.bib` file,
      with DOIs/arXiv IDs on every entry (see `bibliography_guide.md`).
- [ ] **Algorithm blocks** have Input / Output declarations, named
      variables, and numbered lines.
- [ ] **Proofs** use the `proof` environment and end with `∎`.
- [ ] **Conjectures** are clearly labeled as such and are never
      called "theorems".
- [ ] **Experimental section** lists instance generator, seed,
      platform, measured quantities, and links to code.
- [ ] **Tables** use `booktabs` (`\toprule` / `\midrule` /
      `\bottomrule`), never `\hline`.
- [ ] **Figures** have captions that stand alone, labeled axes with
      units, and distinguishable markers in black-and-white.
- [ ] **Page count** is inside the venue's limit *without* font /
      margin tricks.
- [ ] **Anonymization** (if applicable) is complete: no author
      names in PDF metadata, no "as we showed in [7]" with [7] being
      your own paper.
- [ ] **`chktex` / `lacheck`** run clean.
- [ ] **PDF on paper** reads well.
- [ ] **A colleague outside the project** has read §1 and can state
      the result.
- [ ] **Open problems** are concrete questions, not vague directions.

---

## Appendix: a condensed checklist for the DGF paper specifically

Reading `dgf2.tex` with all of the above in mind, the concrete
editorial suggestions for this specific paper are:

1. **Title**: consider "Descending Greedy Filter: Light Spanners via
   Edge-Minimality" — adds a property-word.
2. **Abstract**: move the binary-search complexity result one
   sentence earlier so it doesn't sit under the experimental
   summary.
3. **§1 contribution paragraph**: bullet the four contributions
   (DGF definition, minimality theory, binary-search speedup,
   experiments), each with its quantitative headline.
4. **§1 technical overview paragraph**: add one — the current §1
   goes from motivation straight to "the paper is organized as
   follows" without telling the reader *why* DGF works.
5. **Section structure**: merge §3 and §6 into a single
   "Conjectures" section (either right after §2 or right after §5),
   to avoid the "def / conjecture / def / conjecture" alternation.
6. **Define macros** for `\wt`, `\MST`, `\APSP` in the preamble
   instead of writing `\mathrm{wt}(\mathrm{MST}(P))` everywhere.
7. **Pseudocode** in Algorithm 1 is good; tighten the inner
   "for $(r,s) \in P \times P$" to explicitly say "unordered pairs"
   to avoid a factor of 2 ambiguity.
8. **Bibliography**: convert to a `.bib` file per
   `bibliography_guide.md` §6.
9. **Related work** (currently §9): add a pointer to FS20 in the
   minimality paragraph — their existential-optimality result is
   the strongest prior evidence for the DGF conjectures.
10. **Add an open-problems section** at the end that states
    Conjectures 1–2 as the main questions, lists the empirical
    upper bounds you observe, and explicitly asks whether every
    minimal $t$-spanner in the plane has $O(n)$ edges — this is the
    single most striking question your paper raises.

