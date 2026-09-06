"use client";

import { useMemo, useState } from "react";
import { APPS, BLOCKED_APPS, GRADE_MEANING, type Grade } from "@/lib/data";
import { ScoreCard } from "@/components/ScoreCard";
import { href } from "@/lib/href";

type SortKey = "score" | "hours" | "name";
type Filter = "all" | Grade;

const GRADES: Grade[] = ["A", "B", "C", "D", "F"];

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
          Twenty well-known open-source iOS apps, audited with the FoldReady CLI. The score
          measures what an app does with a wide, resizable scene: sidebar navigation, layout
          that reflows, size classes instead of device checks, state that survives a resize.
          Every check cites the Apple source it is derived from, and the grade bands mean the
          same thing whenever the audit ran.
        </p>
        <p className="lede" style={{ marginTop: 12 }}>
          <b>{BLOCKED_APPS.length} of {APPS.length} do not launch at all</b> when built against
          the iOS 27 SDK: they have no UIScene lifecycle. That is reported before any score,
          because it is not a matter of degree.
        </p>
        <div className="legend">
          {GRADES.map((g) => (
            <span key={g}><b className="g" style={{ color: `var(--g${g})` }}>{g}</b> {GRADE_MEANING[g]}</span>
          ))}
        </div>
        <p className="meta">
          <span>{list.length} app{list.length === 1 ? "" : "s"} audited</span>
          <span>result contract v2 · regenerate with Scripts/generate-index.py</span>
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
          {(["A", "B", "C", "D", "F"] as Grade[]).map((g) => (
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
            A static audit of your iOS source tree: the blocking facts first, then four
            weighted checks against the iOS 27 adaptivity requirements, with an hours estimate.
          </p>
        </div>
        <a className="btn btn-pri" href={href("/get-scored")}>Get your app scored</a>
      </section>
    </>
  );
}
