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
        <span className="kicker">Independent index · contract v5</span>
        <h1>Source audits of twenty iOS apps</h1>
        <p className="lede">Each app is audited from its own source tree by the current scanner. These are source signals, not runtime verdicts: no app here was run on iPhone Duo.</p>
        <p className="spec">Scores rose across the board when the contract moved to v5, and the rise is mostly a change of shape rather than a change in the apps. Adaptive geometry stopped penalising an app that reads no size classes at all, and two new checks added this release (interface idiom and interface orientation) score high for most trees because few branch on the device idiom. Read a score here as a rough summary, never as a compatibility claim.</p>
        <p className="spec">{BLOCKED_APPS.length} of {APPS.length} source trees still show a lifecycle signal that could stop an app launching once it is built against the iOS 27 SDK. That is a source signal, not an observed launch failure; SDK and build configuration are not resolved from source.</p>
        <div className="legend">
          {GRADES.map((g) => (
            <span key={g}><b className="g" style={{ color: `var(--g${g})` }}>{g}</b> {GRADE_MEANING[g]}</span>
          ))}
        </div>
        <p className="meta">
          <span>{list.length} app{list.length === 1 ? "" : "s"} audited</span>
          <span>result contract v5 · regenerate with Scripts/generate-index.py</span>
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
            A static audit of your iOS source tree: the blocking facts first, then the
            weighted checks of contract v5 against the iOS 27 adaptivity requirements, with
            an hours estimate.
          </p>
        </div>
        <a className="btn btn-pri" href={href("/get-scored")}>Get your app scored</a>
      </section>
    </>
  );
}
