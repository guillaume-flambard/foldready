"use client";

import { useMemo, useState } from "react";
import { APPS, type Grade } from "@/lib/data";
import { ScoreCard } from "@/components/ScoreCard";

type SortKey = "score" | "hours" | "name";
type Filter = "all" | Grade;

const GRADES: { g: Grade; label: string }[] = [
  { g: "A", label: "ready · featured-grade" },
  { g: "B", label: "good · some polish needed" },
  { g: "C", label: "functional · not at home" },
  { g: "D", label: "visibly squeezed" },
  { g: "F", label: "needs a real port" },
];

export function RankingClient() {
  const [sort, setSort] = useState<SortKey>("score");
  const [filter, setFilter] = useState<Filter>("all");

  const list = useMemo(() => {
    const filtered = APPS.filter((a) => filter === "all" || a.grade === filter);
    const sorted = [...filtered];
    if (sort === "score") sorted.sort((a, b) => b.score - a.score);
    else if (sort === "hours") sorted.sort((a, b) => a.hours - b.hours);
    else sorted.sort((a, b) => a.name.localeCompare(b.name));
    return sorted;
  }, [sort, filter]);

  return (
    <>
      <div className="head">
        <span className="kicker">Independent index · 7.8in inner display</span>
        <h1>Fold-Ready Index</h1>
        <p className="lede">
          Parallel View keeps every iOS app running on the iPhone Fold — these scores
          measure how good it will look. The index audits well-known open-source apps so
          you can see the difference a few hours of porting makes.
        </p>
        <div className="legend">
          {GRADES.map(({ g }) => (
            <span key={g}><b className="g" style={{ color: `var(--g${g})` }}>{g}</b> {g === "A" ? "ready · featured-grade" : g === "B" ? "good · some polish needed" : g === "C" ? "functional · not at home" : g === "D" ? "visibly squeezed" : "needs a real port"}</span>
          ))}
        </div>
        <p className="meta">
          <span>{list.length} app{list.length === 1 ? "" : "s"} audited</span>
          <span>static + captured-layout · updated with the FoldReady CLI</span>
        </p>
      </div>

      <div className="toolbar">
        <label htmlFor="sort">Sort</label>
        <select className="sort" id="sort" value={sort} onChange={(e) => setSort(e.target.value as SortKey)}>
          <option value="score">Score · high to low</option>
          <option value="hours">Port hours · low to high</option>
          <option value="name">Name · A to Z</option>
        </select>
        <div className="fchips" role="group" aria-label="Filter by grade">
          <button type="button" className="fc" aria-pressed={filter === "all"} onClick={() => setFilter("all")}>All</button>
          {(["A", "B", "C"] as Grade[]).map((g) => (
            <button key={g} type="button" className="fc" aria-pressed={filter === g} onClick={() => setFilter(g)}>
              <span className="g" style={{ color: `var(--g${g})` }}>{g}</span>
            </button>
          ))}
        </div>
        <span className="count">{list.length} / {APPS.length}</span>
      </div>

      <div className="grid">
        {list.map((a, i) => (
          <ScoreCard key={a.slug} app={a} rank={i + 1} />
        ))}
      </div>

      <section className="cta">
        <div>
          <h2>Get your app scored</h2>
          <p>
            A static + pixel audit of your iOS source tree: 7 checks against the iOS 27
            foldable requirements, a captured-layout pass, and an hours estimate for the port.
          </p>
        </div>
        <a className="btn btn-pri" href="/#pricing">Get your app scored</a>
      </section>
    </>
  );
}
