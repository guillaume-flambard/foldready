"use client";

import { useState } from "react";

export function CopyButton({ text, label = "Copy", kind = "btn-sec" }: { text: string; label?: string; kind?: string }) {
  const [copied, setCopied] = useState(false);
  return (
    <button
      type="button"
      className={`btn ${kind}`}
      style={{ padding: "8px 14px", fontSize: 13 }}
      onClick={async () => {
        try {
          await navigator.clipboard.writeText(text);
          setCopied(true);
          setTimeout(() => setCopied(false), 1500);
        } catch {}
      }}
    >
      {copied ? "Copied" : label}
    </button>
  );
}
