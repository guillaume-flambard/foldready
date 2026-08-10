const CHECKMARK = (
  <path d="M376 400 L388 412 L410 388" fill="none" stroke="#052E16" strokeWidth="10" strokeLinecap="round" strokeLinejoin="round" />
);

export function Mark({ size = 40, className = "mark" }: { size?: number; className?: string }) {
  return (
    <svg className={className} width={size} height={size} viewBox="0 0 512 512" role="img" aria-label="FoldReady mark">
      <rect width="512" height="512" rx="112" fill="#0F172A" />
      <rect x="104" y="96" width="304" height="320" rx="40" fill="#1E293B" />
      <rect x="120" y="112" width="272" height="288" rx="28" fill="#334155" />
      <rect x="120" y="112" width="136" height="288" rx="28" fill="#0F172A" />
      <rect x="128" y="120" width="120" height="272" rx="20" fill="#475569" />
      <rect x="264" y="112" width="128" height="288" rx="28" fill="#334155" />
      <rect x="272" y="120" width="112" height="272" rx="20" fill="#0EA5E9" />
      <rect x="248" y="96" width="16" height="320" fill="#0F172A" />
      <circle cx="392" cy="400" r="40" fill="#22C55E" />
      {CHECKMARK}
    </svg>
  );
}

export function CheckGlyph({ size = 15 }: { size?: number }) {
  return (
    <span className="ck">
      <svg width={size} height={size} viewBox="0 0 24 24" aria-hidden="true">
        <path d="M6 12.5 L10.2 16.5 L18 8" fill="none" stroke="#052E16" strokeWidth="3.4" strokeLinecap="round" strokeLinejoin="round" />
      </svg>
    </span>
  );
}
