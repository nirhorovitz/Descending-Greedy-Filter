# How to Write a Related Work Section

A practical, in-depth guide to writing the **related work** section of
a SoCG / SODA / ESA / STOC-style theory paper. It complements
`paper_writing_guide.md` (which has a short §9 on related work) and
`bibliography_guide.md` (which covers *how* to format the citations,
not *which* to include).

This file is about the substance: which prior works to mention, in
what order, in what register, and how to use the section to position
your own contribution.

The running example is the related-work section of
`dgf2.tex` (the DGF spanner paper in this folder), which already has
a well-structured five-subsection related-work section and a strong
`references.bib`. References are stated as BibTeX keys (`BCFMS10`,
`FS16`, etc.) that resolve to entries in `references.bib`.

---

## Table of contents

1. [What the related work section is for](#1-what-the-related-work-section-is-for)
2. [Where it goes and how long it should be](#2-where-it-goes-and-how-long-it-should-be)
3. [Gathering the material: before you write](#3-gathering-the-material-before-you-write)
4. [Organizing the section: thematic, not chronological](#4-organizing-the-section-thematic-not-chronological)
5. [The opening paragraph: the map](#5-the-opening-paragraph-the-map)
6. [The body: one paragraph per theme](#6-the-body-one-paragraph-per-theme)
7. [How to describe a prior paper](#7-how-to-describe-a-prior-paper)
8. [Positioning your own work against prior work](#8-positioning-your-own-work-against-prior-work)
9. [Special cases](#9-special-cases)
10. [The "we differ" paragraph](#10-the-we-differ-paragraph)
11. [Self-citations, concurrent work, and courtesy](#11-self-citations-concurrent-work-and-courtesy)
12. [Twelve anti-patterns](#12-twelve-anti-patterns)
13. [Case study: the DGF paper's related-work section](#13-case-study-the-dgf-papers-related-work-section)
14. [A final checklist](#14-a-final-checklist)

---

## 1. What the related work section is for

Every well-written related work section does **three** things, in
this priority order:

1. **Position.** It tells the reader where your contribution lives
   in the landscape of prior results, so they can judge it fairly.
   *This is the primary function.* A paper without positioning
   reads like "we did something"; a paper with positioning reads
   like "we filled the gap between X and Y".
2. **Completeness.** It convinces the reader (and the reviewer)
   that you know the literature. Missing a 20-year-old canonical
   citation is the single most common reason for a hostile review,
   and "the authors seem unaware of [X]" kills far more papers
   than technical errors.
3. **Courtesy.** It credits the people whose results you build on
   or improve. The theory-CS community is small; authors notice
   whether their work is cited, cited correctly, and described
   fairly.

The related work section is **not** a tutorial on the area, and it
is **not** an encyclopedia. It does not need to cover everything —
it needs to cover the works that **locate your result**, the works
that **your reader will expect to see**, and the works that **you
actually use** technically.

A good test: if a reviewer says "the authors should also cite $X$",
they have either found a real omission (and you should add it) or
they have misunderstood the scope of the section (and the opening
paragraph should have been clearer about scope). Both are fixable;
one is a failure of completeness, the other is a failure of framing.

---

## 2. Where it goes and how long it should be

### 2.1 Two legitimate placements

- **Inside §1 (as §1.3 or §1.4 "Related work")**. Short, typically
  1–2 pages. Appropriate for 12-page ESA / shorter SODA papers, and
  when the prior landscape is compact.
- **As its own section near the end** (§5, §6, or a section right
  before Conclusion). Longer, 1–3 pages, with subsections.
  Appropriate for papers in a densely-studied area where the
  landscape deserves a real tour.

The DGF paper uses the second pattern, with five subsections
spanning ~2 pages of LIPIcs. That is the right choice: the spanner
literature is large enough that a compact §1 paragraph would leave
out too much, and the ideas your reader needs to compare against
(leapfrog, existential optimality, WSPD lightness) are each worth
their own paragraph.

A **third** placement, sometimes seen but discouraged, is a
mid-paper digression. Do not write: "§3 presents DGF. §4 is a
related-work section. §5 continues the analysis." Readers lose the
thread.

### 2.2 Length budget

Approximate budgets for each venue, assuming the related-work
section has its own number:

| Venue | Pages | Rough # of references |
|---|---|---|
| ESA / SoCG (12–15 pages) | 1–2 | 20–35 |
| SODA (20 pages) | 1.5–3 | 30–55 |
| STOC / FOCS (20–25 pages) | 1.5–2.5 | 25–50 |
| Journal (*Algorithmica*, *SICOMP*) | 2–4 | 50–100 |

When the related-work section lives *inside* the introduction,
halve these numbers for the section length, but do not cut the
citation count: dense citation is what makes it credible. Short and
citation-dense is better than long and citation-sparse.

### 2.3 The "dense but readable" principle

A well-written related-work paragraph has **roughly one citation
per sentence, sometimes two**. That is normal for this community.
It looks dense at first glance but reads naturally because the
citations are doing real work — each one anchors a specific claim.

If a paragraph has zero citations, it is not related work; it is
background. If a paragraph has seven citations and no structure,
it is a citation dump.

---

## 3. Gathering the material: before you write

### 3.1 Build a personal reading list first

Before you write a single sentence of the related-work section, you
should have **read** (not just skimmed) roughly 20–40 papers in the
area. These fall into four buckets:

1. **Canonical foundations** (5–10 papers). The classical papers
   that everyone cites. For spanners: `ADDJS93, KG92, Yao82,
   Clarkson87, Keil88, CK95, CDNS95, NS07`. Missing one of these
   is a red flag to reviewers.
2. **Direct predecessors** (3–8 papers). The papers your result
   is most directly compared to. For DGF: `BCFMS10, ABBB15, GLN02,
   FS16, BLW19, LS22`.
3. **Adjacent techniques** (5–10 papers). Different methods that
   attack the same or related problem. For DGF: `SZ04` (ILP),
   `Cai94` and `Kortsarz01` (hardness), `DHN93, DNS95, DN97`
   (leapfrog and light spanners).
4. **Empirical / systems papers** (2–5 papers), when your paper
   has experiments. For DGF: `FG09, ABBB15` as prior experimental
   comparisons.

### 3.2 For each paper, write a one-sentence summary

For every paper you plan to cite, write a single sentence that
captures **what it claims and why it matters for your paper**. Save
these sentences in a scratch file. Examples, for the DGF paper:

- `ADDJS93`: introduced the greedy spanner and the
  $(2k-1)$-spanner / $n^{1+1/k}$-edges trade-off.
- `CDNS95`: first $O(n)$-edges and $O(\wt(\MST))$-weight bound for
  the greedy $(1+\varepsilon)$-spanner in Euclidean space.
- `DHN93`: introduced the $t$-leapfrog property and the
  $O(\wt(\MST))$ weight bound in 3D.
- `BCFMS10`: $O(n^2 \log n)$ time for the exact greedy spanner.
- `FS16`: greedy is existentially (near-)optimal.
- `SZ04`: ILP-based exact computation of minimum-weight
  $t$-spanner (different objective from ours: minimum weight vs.
  edge-minimal).

This list is the skeleton of the related-work section. The writing
is then just the task of grouping the sentences by theme, adding
connective tissue, and stating how your paper relates to each group.

### 3.3 DBLP is your friend

When you search DBLP for an author in this community (e.g. Paz
Carmi, Michiel Smid), their publication list is itself a map of
the subfield. Click-through on a recent paper and look at its
reference list — you will find several papers you were not aware
of, and you can add them to your reading list.

Similarly, for any paper you cite, check which recent papers cite
*it* (Google Scholar's "Cited by" link). If a 2023 paper cites
`ADDJS93` and solves a problem close to yours, you need to know
about it.

### 3.4 Set a cutoff and stop

Related-work gathering can consume a month if you let it. Set a
cutoff: "I will stop adding new papers two weeks before the
deadline; new papers found after that go to the journal version or
a footnote." Otherwise the bibliography never stabilizes and the
paper never finishes.

---

## 4. Organizing the section: thematic, not chronological

The single most important structural decision is: **group by
theme, not by year**. A chronological related-work section reads
like a history lesson and forces the reader to reconstruct the
themes themselves; a thematic one reads like a map.

### 4.1 Identifying themes

A theme is a **question** that multiple papers answer differently.
Good themes for the DGF paper:

- "How do you *construct* a $t$-spanner?" → Greedy, Yao, $\Theta$,
  Delaunay, WSPD (each a construction family).
- "How *sparse / light* can a $t$-spanner be?" → Leapfrog,
  existential optimality, truly-optimal bounds.
- "How *fast* can you compute the greedy spanner?" → Near-quadratic
  time, linear space, approximate greedy.
- "What does *minimum* (vs *minimal*) $t$-spanner mean?" → NP-hardness,
  ILP, hardness of approximation.
- "What do we know *empirically*?" → Experimental comparisons.

Each theme becomes one subsection (or one dense paragraph, if the
section is short). The DGF paper's five subsections map exactly to
these five themes — and that is why the section reads well.

### 4.2 Within a theme, chronological is fine

Inside a single thematic paragraph, chronological order usually
works best: the reader learns how the sub-line evolved.

> Within a theme, it is natural to follow the chronology: Yao
> (1982) proposed the cone-based construction, Clarkson (1987)
> and Keil (1988) independently introduced the $\Theta$-graph
> variant, and Keil and Gutwin (1992) gave the first clean
> $t$-spanner analysis.

### 4.3 Order of themes

Order themes from **most relevant to your paper → least relevant**.
The reader's attention is highest at the start of the section;
spend it on the comparisons that matter most.

For DGF, the ordering "greedy + leapfrog → cone/Delaunay → WSPD/light
→ faster greedy → edge-minimality + empirical" is almost right.
One possible rearrangement: move **"Edge-minimality, filtering,
and empirical comparisons"** up to §Related-Work.2, because DGF's
contribution is primarily about edge-minimality and filtering; the
cone / Delaunay / WSPD paragraphs are context, not direct
competitors. That is a judgment call, and the current order is
defensible.

---

## 5. The opening paragraph: the map

The first paragraph of the related-work section has a specific job:
**telling the reader what the section covers, and how it is
organized**. This is 3–6 sentences, and it is where readers decide
whether to read the section linearly, skip to a specific paragraph,
or move on.

### 5.1 Ingredients

A good opening paragraph contains:

1. **A one-sentence statement of where your work sits.** "DGF sits
   at the intersection of constructive algorithms for geometric
   spanners and structural results on edge-minimal spanners."
2. **A short enumeration of the themes that follow.** "We discuss
   (i) the greedy spanner and the leapfrog property; (ii) cone-
   based and Delaunay constructions; (iii) lightness results via
   WSPD; (iv) faster greedy-spanner algorithms; and (v)
   edge-minimality, filtering, and empirical comparisons."
3. **A pointer to the survey or textbook** that covers the area as
   a whole. "A comprehensive reference is the monograph of
   Narasimhan and Smid~\cite{NS07}."

### 5.2 DGF opening paragraph, as written

The current DGF opening is:

> The Descending Greedy Filter (DGF) sits at the intersection of
> two lines of work on geometric spanners: *(i)* constructive
> algorithms that build small or light $t$-spanners directly
> (greedy, Yao, $\Theta$-graphs, WSPD-based, etc.), and
> *(ii)* structural properties characterizing when a $t$-spanner
> is sparse and/or light (the $t$-leapfrog property, existential
> optimality of greedy). DGF is closest in spirit to the classical
> greedy spanner---it produces an edge-minimal $t$-spanner by
> inspecting one edge at a time---but the *direction* of
> processing is reversed (descending instead of ascending), and
> the algorithm is naturally a *filter*: it can be applied to any
> $t$-spanner, not only the complete graph. A comprehensive
> reference for the whole area is the monograph of Narasimhan and
> Smid~\cite{NS07}.

This is a textbook-quality opening: it names the two lines, says
which is closer, names the key distinguishing feature (*direction*,
*filter*), and points at the canonical survey. The one tweak I
would make is to add an **explicit subsection roadmap** in the
last sentence, e.g.: "After reviewing the greedy spanner and its
structural theory (§\ref{subsec:greedy}), the cone-based and
Delaunay families (§\ref{subsec:cone}), WSPD and lightness
(§\ref{subsec:wspd}), faster greedy implementations
(§\ref{subsec:faster}), and edge-minimality and empirical work
(§\ref{subsec:minimality}), we discuss the specific prior results
that DGF improves on or diverges from." This turns the section
into a navigable map.

---

## 6. The body: one paragraph per theme

Each thematic paragraph has a stock structure:

1. **Lead sentence** that names the theme and its significance.
2. **Chronological or conceptual development** of 2–6 papers,
   each named with its authors and main contribution in one
   sentence.
3. **Connector to your work**: one or two sentences that state
   how *your* paper relates to this theme.

### 6.1 Lead sentence

The lead sentence must do two things: name the theme, and tell the
reader why it matters for your paper. Bad lead sentences:

- "Several papers have studied the greedy spanner." — vague.
- "The greedy spanner was introduced in 1993." — facts without
  framing.

Good lead sentence (from DGF):

> The greedy spanner was introduced by Althöfer, Das, Dobkin,
> Joseph and Soares~\cite{ADDJS93}, who sort the edges of a
> weighted graph in non-decreasing order and add an edge $(u,v)$
> to the spanner only when its current shortest-path distance
> exceeds $t \cdot |uv|$.

This one sentence gives the lead author, the citation, and the
defining algorithmic property — all of which set up the next
sentence, which will be about DGF's reversal.

### 6.2 Conceptual development

After the lead, you cite 2–6 papers. Each gets one sentence, and
each sentence should say what the paper *contributed*, not what it
is *about*.

Bad: "Chandra, Das, Narasimhan and Soares~\cite{CDNS95} is a paper
on spanners."
Good: "Chandra, Das, Narasimhan and Soares~\cite{CDNS95} gave the
first sparseness/weight bounds for greedy in Euclidean space,
showing that the greedy $(1+\varepsilon)$-spanner has $O(n)$ edges
and weight $O((1/\varepsilon)^d \cdot \wt(\MST))$."

Notice the difference: the second form states the **result**, not
the topic. This is the register of a theory-CS related-work
paragraph.

### 6.3 Connector to your work

End each thematic paragraph with one or two sentences that connect
the theme to your contribution. This is where positioning happens.

From the DGF paper:

> DGF is the natural reverse: instead of starting from the empty
> graph and inserting short edges first, DGF starts from a
> $t$-spanner and removes long edges first whenever the remaining
> subgraph is still a $t$-spanner. Both algorithms terminate at an
> edge-minimal $t$-spanner, but on the same input they generally
> produce *different* edge-minimal subgraphs.

This is doing heavy lifting: it names the algorithmic relationship
(reverse), identifies the **common** property (edge-minimality),
and flags the **point of divergence** (different outputs).

### 6.4 Paragraph length

Each thematic paragraph is 6–15 sentences. Less than 6 and the
theme is underdeveloped; more than 15 and the paragraph is too
large to scan — break it into two, or move some material into a
footnote or into a later subsection.

---

## 7. How to describe a prior paper

This is a surprisingly subtle craft, and it has strong conventions.

### 7.1 The first-mention template

The first time you cite a paper, use one of these two forms:

- **Author-led**: *"Bose, Carmi, Farshi, Maheshwari and
  Smid~\cite{BCFMS10} gave an $O(n^2 \log n)$-time algorithm for
  the greedy spanner."*
- **Result-led**: *"The greedy spanner can be computed in
  $O(n^2 \log n)$ time~\cite{BCFMS10}."*

**When to use which:**

- Author-led, when the authorship or priority is part of the point
  you are making. Use for canonical papers, direct predecessors,
  and papers where you will refer back to the same authors.
- Result-led, when the fact is more important than who proved it.
  Use for background knowledge and for bundling several results:
  *"The greedy spanner has $O(n)$ edges and weight
  $O(\wt(\MST))$ ~\cite{ADDJS93, CDNS95, DHN93, DNS95}."*

### 7.2 Author naming conventions

- **Up to three authors**: name all of them. *"Das, Heffernan and
  Narasimhan~\cite{DHN93} introduced the $t$-leapfrog property."*
- **Four or more authors**: first author + "et al." *"Alewijnse
  et~al.~\cite{ABBB15} gave an $O(n)$-space algorithm."*
- **The non-breaking tilde `~`** before `\cite{}` is essential; it
  prevents the citation from being pushed to a new line alone.
- **Diacritics must be preserved**: `Alth\"ofer`, `Ros\'en`,
  `Dujmovi\'c`. Omitting them is disrespectful and reviewers
  notice.

### 7.3 Subsequent mentions

After the first mention, you can use shorter forms:

- Re-cite with `et al.` even for two-author papers, if the context
  is clear: *"As noted above, Das and Narasimhan~\cite{DN97}
  gave..."* becomes *"Das and Narasimhan~\cite{DN97} later..."*
- Or refer by citation only: *"The $O(n)$-space variant
  of~\cite{ABBB15} scales to $10^6$ points."*

Mixing the two is fine, and is how most papers read naturally.

### 7.4 Verbs to use

Different verbs convey different levels of epistemic strength. Use
them deliberately:

| Verb | Meaning | Example |
|---|---|---|
| *proved* | Rigorous proof of a theorem. | "Filtser and Solomon~\cite{FS16} *proved* that greedy is existentially near-optimal." |
| *showed* | Neutral; proved, but without emphasis. | "Bose et al.~\cite{BCFMS10} *showed* an $O(n^2 \log n)$ algorithm." |
| *gave / presented / introduced* | Presented a new object or construction. | "Yao~\cite{Yao82} *introduced* the cone-based construction." |
| *observed / noted* | Stated without a deep proof; an easy but useful fact. | "Sigurd and Zachariasen~\cite{SZ04} *observed* that greedy is within a few percent of optimum in their experiments." |
| *conjectured* | Stated without proof. | "Filtser and Solomon~\cite{FS16} *conjectured* that the bound is tight up to constants." |
| *claimed* | Neutral-to-skeptical; use sparingly. | "\cite{X} *claimed* without proof that..." |

Never use: *"admitted"*, *"failed to prove"*, or any verb implying
an author weakness. Stay technical.

### 7.5 Naming the result

Whenever possible, use the **established name** of a result, not a
paraphrase. *"the $t$-leapfrog property"*, *"existential
optimality"*, *"the greedy spanner"* — these are terms of art.
Using "the property of~\cite{DHN93}" where you could write "the
$t$-leapfrog property" is a small thing that marks you as
unfamiliar with the area.

---

## 8. Positioning your own work against prior work

This is the part most students under-do. The related-work section
is not a list of other people's achievements; it is the **scaffold
against which your contribution is measured**. Every paragraph
should, directly or by implication, help the reader answer: *what
is new here?*

### 8.1 Three positioning strategies

**(a) Direct improvement.** You solve the same problem better than a
prior paper. The sentence form is: *"Bose et al.~\cite{BCFMS10} gave
an $O(n^2 \log n)$ algorithm; we give an $O(n^2)$ algorithm."*

**(b) Orthogonal axis.** You solve a slightly different problem,
along a different axis. *"Sigurd and Zachariasen~\cite{SZ04}
solve minimum-weight $t$-spanner exactly (no polynomial-time
guarantee); we solve edge-minimal $t$-spanner in polynomial
time."* DGF's positioning against SZ04 is exactly of this kind.

**(c) Conceptual generalization / dualization.** You show that a
prior result is an instance of a more general phenomenon, or is
dual to something else. *"ADDJS93's greedy spanner processes edges
ascending; DGF processes them descending. Both produce
edge-minimal $t$-spanners, but on different inputs the outputs
differ."* DGF's positioning against `ADDJS93` is of this kind.

### 8.2 Be specific with numbers

Positioning claims must be **quantitative whenever possible**.

Bad: "DGF is comparable to the greedy spanner."
Good: "In our experiments on random point sets in the unit
square, DGF produces 0.1–3% fewer edges and 0.1–5% lower total
weight than greedy, while matching the same stretch $t$."

Bad: "Our algorithm is faster."
Good: "Our binary-search variant uses $O(k \log m)$ APSP calls,
compared to $O(m)$ for naive DGF, where $k$ is the output edge
count and $m$ the input edge count."

### 8.3 Do not oversell

Reviewers are allergic to overclaims. If your experiments show 3%
improvement on a specific distribution, write "3% improvement on
uniform random point sets in the unit square", not "outperforms".
If you prove a conjecture only under an extra assumption, state
the assumption.

Specifically, **never** write in the related-work section: "our
algorithm is superior" / "our result is the strongest known" /
"our method outperforms all existing approaches". Let the numbers
speak.

### 8.4 Do not undersell

The reverse error — excessive modesty — is almost as bad. The
reader needs to know, clearly and specifically, what is new.
Sentences like *"This paper presents some observations about
minimal $t$-spanners"* or *"We extend some prior work"* are
unreviewable. Be direct.

---

## 9. Special cases

Several situations require extra care in the related-work section.
Handling them correctly marks a mature writer.

### 9.1 A very close competitor

If there exists a paper whose result is very close to yours, you
must:

1. **Cite it prominently** — not in a footnote, and not in a group
   of five.
2. **State the difference precisely**, in terms the reader can
   verify.
3. **Not hedge** — if you match it, say so; if you beat it, say
   by how much; if you are orthogonal, say along which axis.

Pattern:

> Our main theorem is closely related to a result of X and
> Y~\cite{XY23}. Specifically, \cite{XY23} prove [precise result]
> under [assumption], whereas our Theorem~N proves [precise
> result] under [weaker / different assumption]. The techniques
> differ: [one-sentence on their technique] versus [one-sentence
> on ours].

Do **not** bury a close competitor in a group cite or a footnote.
Reviewers always find it, and the paper looks dishonest.

### 9.2 A prior paper the reviewer will ask about

Sometimes you know a reviewer will ask *"why didn't you compare
against \cite{X}?"* — often because X is in the PC chair's group,
or X solves a problem that sounds like yours but actually isn't.
**Preempt the question** by addressing it explicitly:

> One might ask how our result compares to that of
> \cite{X}. \cite{X} addresses the superficially similar problem
> of [Z], but under [different objective / different model / ...],
> and so the results are not directly comparable. In particular,
> [one-sentence technical reason].

### 9.3 Concurrent / independent work

If a paper appeared on arXiv or was published very close in time
to yours, and reaches a similar result independently, the
standard form is:

> Concurrently and independently, X and Y~\cite{XY25} obtained
> [their result]. Their approach is based on [technique]; ours is
> based on [technique]. The two results are complementary: [one
> sentence of comparison].

Cite them graciously. "Concurrently and independently" is a term
of art that signals the reader this is not a priority dispute.

### 9.4 Older overlooked work

If a decades-old paper (1970s–1990s) anticipated part of your
result, do not hide it. Cite it with respect:

> The idea of processing edges in descending order appears
> implicitly in the reverse-delete algorithm for minimum spanning
> trees, which goes back at least to Kruskal (1956) and was
> analyzed by X~\cite{X}. Our algorithm can be viewed as a
> spanner-analogue of reverse-delete, with "connected" replaced by
> "$t$-spanner".

The DGF paper already does this correctly for reverse-delete and
for the leapfrog literature.

### 9.5 Negative results and failed attempts

If a prior paper tried to solve your problem and failed, or proved
a negative result, cite it carefully. Do **not** phrase it as
"\cite{X} failed to show Y"; phrase it neutrally: "\cite{X} proved
that Y is impossible for [model]", or "\cite{X} studied the same
problem and obtained [partial result]".

### 9.6 Textbooks and surveys

Cite the canonical textbook once, in the opening paragraph
("A comprehensive reference is ~\cite{NS07}"), and then re-cite
sparingly when you need a specific result for which the textbook is
the canonical pointer. Do not re-cite the textbook for every
standard fact; cite the primary source instead.

---

## 10. The "we differ" paragraph

For a SoCG/SODA paper, it is often useful to end the related-work
section with a short paragraph that **summarizes how your paper
differs from the closest prior work**, in one list of 3–5 bullets
or 3–5 sentences.

This paragraph is optional but very helpful for reviewers. It
reads like:

> In summary, our contribution differs from prior work in three
> ways:
>
> 1. Whereas BCFMS10 and ABBB15 compute the *specific* greedy
>    spanner, DGF produces an arbitrary *edge-minimal*
>    $t$-spanner; the conjectures in §3 assert that all such
>    outputs are sparse and light.
> 2. Whereas SZ04 solve the *minimum-weight* $t$-spanner (NP-hard,
>    no polynomial-time guarantee), our algorithm runs in
>    polynomial time and produces an edge-minimal output with
>    empirical weight close to SZ04's ILP optimum.
> 3. Whereas FS16's existential optimality applies only to
>    greedy, our conjectures (if proved) would extend the same
>    asymptotic guarantee to the entire class of edge-minimal
>    $t$-spanners.

This paragraph is where a PC member who is time-pressured can, in
30 seconds, understand exactly what your paper does. It is worth
writing it even if it feels redundant with the contribution bullets
in §1 — the two have different jobs: §1 bullets state what you did,
the "we differ" paragraph states how it compares.

---

## 11. Self-citations, concurrent work, and courtesy

### 11.1 Self-citations

Self-citations are **expected** when you extend your own prior work,
and are **suspicious** when they fill up the references section.

- **Good self-cite**: "This paper extends the conference version
  \cite{OurSoCG24} by adding full proofs and a new experimental
  comparison."
- **Good self-cite**: "Our earlier paper \cite{OurSODA22} introduced
  the descending-filter framework for matchings; here we adapt it
  to spanners."
- **Suspicious self-cite**: five of your own papers cited without
  any of them being technically load-bearing.

Rule of thumb: each self-citation should either (a) be a predecessor
your paper extends, (b) be a technical tool you use, or (c) be a
closely related parallel line of your own that the reader might
mistake for the current contribution. If it is none of those three,
remove it.

### 11.2 Double-blind venues

At double-blind venues (SODA, STOC, FOCS are single-blind; ESA and
SoCG are single-blind; CG:YRF is double-blind; many journals vary),
self-citation requires extra care:

- Cite your own prior work in the third person: "Jones and Smith
  \cite{JS21}" — **not** "in our prior work \cite{JS21}".
- Do **not** strip the self-citation: reviewers check, and a
  missing canonical self-cite looks worse than an acknowledged
  one.
- Cite your own arXiv preprints only if they are not trivially
  attributable to you (a paper with your name in the title
  defeats the anonymization).

### 11.3 Courtesy to the community

Some specific courtesies that cost nothing but matter:

- **Cite your advisor's work** when it is relevant, even if it is
  not strictly necessary. It is relevant more often than you
  think.
- **Cite women and underrepresented authors by full first name**
  at least once, rather than abbreviating. (The BibTeX `.bst`
  usually abbreviates, but the in-text mention "Glencora
  Borradaile, Hung Le and Christian Wulff-Nilsen~\cite{BLW19}
  proved..." can name all three the first time.)
- **Use the authors' own preferred diacritics and spellings**.
- **Cite the author version / conference + journal unified
  reference** — not just the conference (see
  `bibliography_guide.md` §3.2).

---

## 12. Twelve anti-patterns

| # | Anti-pattern | Fix |
|---|---|---|
| 1 | A chronological dump: "In 1982, Yao introduced..." "In 1988, Keil proposed..." | Group by theme; chronology only inside a theme. |
| 2 | Missing canonical citation. | Re-read the classics; use DBLP + textbook TOC to cross-check. |
| 3 | Citing only the conference version when a journal version exists. | Use the unified entry with the conference in `note`. See `bibliography_guide.md`. |
| 4 | Describing what a paper is "about" instead of what it proved. | State the **result**: theorem, bound, algorithm. |
| 5 | Long author name lists ("Bose, Carmi, Farshi, Maheshwari, Smid, ...") in flowing prose where it hurts reading. | Use "Bose et~al." after the first mention. |
| 6 | No positioning of own contribution — the section reads like a literature survey. | Every theme paragraph ends with a "how we relate" sentence. |
| 7 | "As we will see in §X, our algorithm is better" — salesmanship. | State differences factually; let the technical sections deliver. |
| 8 | Citation dump: `\cite{A, B, C, D, E, F, G}` with no structure. | Break into thematic groups, each with its own lead sentence. |
| 9 | Self-citation inflation. | Each self-cite must be technically load-bearing. |
| 10 | Citing textbook for everything. | Cite primary sources; textbook once, at the top. |
| 11 | Unfair characterization of a competitor. | Read their paper again; describe their result in their own terms. |
| 12 | Related-work section that is longer than the technical sections combined. | Trim to 1–3 pages; move extra material to a journal version. |

---

## 13. Case study: the DGF paper's related-work section

The current `§Related Work` in `dgf2.tex` is structurally strong.
Here is a detailed breakdown, section by section, with specific
suggestions.

### 13.1 Overall structure

- §Related-Work.0 (opening): maps the landscape (greedy, Yao,
  $\Theta$, WSPD) vs. structural (leapfrog, existential
  optimality), names the textbook `NS07`. **Good.**
- §Related-Work.1 "Greedy spanners and the leapfrog property":
  `ADDJS93, CDNS95, DHN93, DNS95, FS16` + framing of DGF as reverse.
  **Good.**
- §Related-Work.2 "Cone-based and Delaunay spanners": `Yao82,
  Clarkson87, Keil88, KG92, DFS90`. **Good.**
- §Related-Work.3 "WSPD and light spanners": `CK95, LL92, DNS95,
  DN97, BLW19, LS22`. **Good.**
- §Related-Work.4 "Faster greedy and approximate-greedy
  spanners": `GLN02, BCFMS10, ABBB15`, connector to binary-search
  variant. **Good.**
- §Related-Work.5 "Edge-minimality, filtering, and empirical
  comparisons": `Cai94, Kortsarz01, SZ04, DHN93, DNS95, FG09,
  ABBB15`. **Good.**

### 13.2 Specific strengths

- The opening paragraph distinguishes "constructive" from
  "structural" lines, which is the right coarse partition.
- Every subsection ends with a connector to DGF
  ("DGF is the natural reverse...", "running DGF on top of a Yao
  graph...", "Our recursive binary-search variant...").
- `FS16` (Filtser–Solomon existential optimality) is handled
  particularly well — it is positioned as both a prior result and
  as the target that the DGF conjectures would generalize.

### 13.3 Suggested refinements

1. **Add a "we differ" summary paragraph** (as in §10 above) at
   the very end of §Related Work, with 3–5 bullets that explicitly
   state how DGF diverges from `BCFMS10, ABBB15`, from `SZ04`, and
   from `FS16`. This gives a time-pressured PC member a 30-second
   executive summary.

2. **Promote the edge-minimality subsection**. Currently it is §5
   of 5, but edge-minimality is the central conceptual novelty of
   the paper. A reordering that puts it second (right after the
   greedy/leapfrog discussion) would make the paper's conceptual
   contribution more visible. This is a judgment call; the
   current order is also defensible because it preserves the
   "construction → structure" flow.

3. **Anchor `SZ04` more precisely**. The current sentence
   correctly identifies `SZ04` as a minimum-weight (not
   edge-minimal) algorithm, but does not highlight that the two
   objectives are genuinely different — a reviewer who reads
   quickly may assume they are the same. Add one sentence:
   > Note that minimum-weight and edge-minimal differ: every
   > minimum-weight $t$-spanner is edge-minimal, but the converse
   > fails, and a minimum-cardinality $t$-spanner need not be
   > edge-minimal either.

4. **Mention `NS07` Chapter 14** explicitly when you first
   mention the WSPD / leapfrog material — the textbook has a
   consolidated exposition that most readers will want to
   consult.

5. **Consider adding a sentence on concurrent/recent work** (if
   any exists) in the post-2022 literature. The current
   references stop at `LS22`; if something relevant appeared in
   2023–2025, mention it, even briefly.

6. **`Kortsarz01` context**. The current sentence is:
   > Kortsarz~\cite{Kortsarz01} gave hardness-of-approximation
   > results.
   This is slightly thin. Two more words — "factor-$\Omega(\log
   n)$ hardness" or "even approximating within any constant is
   hard" — would make it more useful.

These are small refinements, not restructurings. The section is
already well-organized and citation-dense; these changes would
push it from "good" to "excellent".

---

## 14. A final checklist

Run through this list after your first draft of the related-work
section and before every submission.

### 14.1 Structure

- [ ] Opening paragraph names the themes and points to the
      textbook / survey.
- [ ] Themes are conceptual, not chronological.
- [ ] Themes are ordered by relevance to your contribution.
- [ ] Each theme ends with a connector sentence to your paper.
- [ ] Optionally, a closing "we differ" paragraph with 3–5
      bullets.
- [ ] The section reads in 3–5 minutes; if not, tighten.

### 14.2 Content

- [ ] Every canonical paper a reader in the area expects is
      cited.
- [ ] Every cited paper is the journal version when one exists.
- [ ] Every prior paper described by **result**, not topic.
- [ ] Every prior paper's authors are named correctly on first
      mention (full names, diacritics, up to three listed).
- [ ] Quantitative comparisons are **specific numbers**, not
      "comparable" / "faster" / "better".
- [ ] No overclaims ("we outperform"); no underclaims ("some
      observations").
- [ ] Close competitors are addressed in a dedicated paragraph,
      not buried.
- [ ] Concurrent / independent work, if any, is credited in the
      standard form.
- [ ] Self-citations are either predecessor, tool, or
      parallel-line; never filler.
- [ ] At double-blind venues, self-citations are anonymized ("in
      the work of Jones and Smith \cite{}" not "in our prior work
      \cite{}").

### 14.3 Style

- [ ] Author names use `\cite{}` preceded by `~` (non-breaking
      space).
- [ ] Four or more authors: use "et~al.\~\cite{}" after first
      mention.
- [ ] Verbs are deliberate (*proved*, *showed*, *gave*,
      *observed*, *conjectured*, *claimed*).
- [ ] Named results use the established name ("the $t$-leapfrog
      property", not "the property of \cite{}").
- [ ] Diacritics preserved in author names.
- [ ] Related-work length matches venue budget (§2.2).
- [ ] No `\hline`, no mid-paragraph citation dumps, no "we see
      that ...".

### 14.4 Cross-checks

- [ ] Every `\cite{Key}` resolves; `bibtex` produces zero
      warnings.
- [ ] Every reference in `references.bib` is actually cited (no
      orphans).
- [ ] Bibliography follows `bibliography_guide.md`.
- [ ] A colleague outside the immediate project reads the
      related-work section and, afterwards, can name the three
      or four closest competitors and how your paper differs from
      each.

If the last checkbox holds, the related-work section is doing its
primary job — **positioning your contribution** — and you are
ready to submit.

