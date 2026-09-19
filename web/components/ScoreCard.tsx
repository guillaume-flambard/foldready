import { CHECK_LABELS, GRADE_COLOR, type AppScore, type Grade, type Checks } from "@/lib/data";

export function SegBar({ score, color = "var(--blue)" }: { score: number; color?: string }) {
  const on = Math.max(0, Math.min(10, Math.round(score / 10)));
  return (
    <span className="segs">
      {Array.from({ length: 10 }).map((_, i) => (
        <span key={i} className={"seg" + (i < on ? " on" : "")} style={{ ["--c" as string]: color }} />
      ))}
    </span>
  );
}

export function CheckBar({
  label,
  score,
  weight,
  color = "var(--blue)",
}: {
  label: string;
  score: number;
  weight?: string;
  color?: string;
}) {
  return (
    <div className="cbar">
      <span className="lbl">{label}</span>
      <SegBar score={score} color={color} />
      <span className="val" style={{ color: score >= 70 ? "var(--green)" : score >= 40 ? "var(--gD)" : "var(--gF)" }}>
        {score}
      </span>
      {weight && <span className="wt">{weight}</span>}
    </div>
  );
}

export function GradeChip({ grade }: { grade: Grade }) {
  return <span className={`gchip ${grade.toLowerCase()}`}>{grade}</span>;
}

export function SeverityChip({ severity }: { severity: string }) {
  const key = severity.toLowerCase();
  const cls = key === "critical" ? "sev-b" : key === "major" ? "sev-m" : "sev-n";
  return (
    <span className={`chip ${cls}`}>
      <span className="dot" />
      {severity}
    </span>
  );
}

export function WeakChips({ app }: { app: AppScore }) {
  const val = (k: keyof Checks) => app.checks[k] ?? 100;
  const weak = (Object.keys(app.checks) as (keyof Checks)[])
    .filter((k) => val(k) < 70)
    .sort((a, b) => val(a) - val(b))
    .slice(0, 3);
  if (weak.length === 0) return <span className="chip ready">no displayed check below 70; untested</span>;
  return (
    <>
      {weak.map((k) => (
        <span key={k} className="chip weak">
          {CHECK_LABELS[k]} <b className="mono">{val(k)}</b>
        </span>
      ))}
    </>
  );
}

export function ScoreCard({ app, rank }: { app: AppScore; rank: number }) {
  const color = GRADE_COLOR[app.grade];
  const blocking = app.blockers.filter((b) => b.stopsLaunch);
  return (
    <article className="scard">
      <span className="rank">{String(rank).padStart(2, "0")}</span>
      <div className="top">
        <span className="num" style={{ color }}>{app.score}</span>
        <div>
          <h3>{app.name}</h3>
          <p className="sub">{app.uiFiles} UI files · {app.findingCount} findings</p>
        </div>
      </div>
      <div className="stats">
        <span>Heuristic risk<b>{app.risk}</b></span>
        <span>Unvalidated estimate<b>{app.hours}h</b></span>
        <span style={{ marginLeft: "auto" }}><GradeChip grade={app.grade} /></span>
      </div>
      {blocking.length > 0 && (
        <p className="blockline">Potential lifecycle signal; confirm target and SDK: {blocking.map((b) => b.title.toLowerCase()).join(", ")}</p>
      )}
      <div className="checks"><WeakChips app={app} /></div>
      <a className="go" href={`/report/${app.slug}`}>Full Fold-Ready report</a>
    </article>
  );
}
