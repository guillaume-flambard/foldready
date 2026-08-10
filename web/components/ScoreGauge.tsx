"use client";

import { useEffect, useRef, useState } from "react";
import { GRADE_COLOR, type Grade } from "@/lib/data";

export function ScoreGauge({
  score,
  grade,
  caption = "Fold-Ready score",
  size = 260,
  className = "",
}: {
  score: number;
  grade: Grade;
  caption?: string;
  size?: number;
  className?: string;
}) {
  const arcRef = useRef<SVGPathElement>(null);
  const [display, setDisplay] = useState(0);
  const color = GRADE_COLOR[grade];

  useEffect(() => {
    const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    const rAF = requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        if (arcRef.current) {
          arcRef.current.style.strokeDashoffset = String(313 * (1 - score / 100));
        }
      });
    });
    if (reduced) {
      setDisplay(score);
      return () => cancelAnimationFrame(rAF);
    }
    setDisplay(0);
    const t0 = performance.now();
    let id = 0;
    const tick = (ts: number) => {
      const p = Math.min(1, (ts - t0) / 1100);
      setDisplay(Math.round(score * (1 - Math.pow(1 - p, 4))));
      if (p < 1) id = requestAnimationFrame(tick);
    };
    id = requestAnimationFrame(tick);
    return () => {
      cancelAnimationFrame(rAF);
      cancelAnimationFrame(id);
    };
  }, [score]);

  const height = Math.round(size * (142 / 260));
  return (
    <div className={`gauge ${className}`} style={{ width: size, height, ["--g" as string]: color }}>
      <svg viewBox="0 0 260 142" aria-hidden="true">
        <path className="track" d="M30,128 A100,100 0 0 1 230,128" />
        <path ref={arcRef} className="arc" d="M30,128 A100,100 0 0 1 230,128" />
      </svg>
      <div className="body">
        <span className="gchip" style={{ background: color }}>{grade}</span>
        <span className="val">{display}</span>
      </div>
      <span className="cap">{caption}</span>
    </div>
  );
}
