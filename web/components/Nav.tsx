"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Mark } from "@/components/Mark";
import { useTheme } from "@/lib/theme";

function ThemeToggle() {
  const { theme, toggle } = useTheme();
  return (
    <button type="button" className="tgl" aria-pressed={theme === "light"} onClick={toggle}>
      <span>{theme === "light" ? "Dark" : "Light"}</span>
      <span className="knob" aria-hidden="true" />
    </button>
  );
}

const LINKS = [
  { href: "/ranking", label: "Index" },
  { href: "/components", label: "Design system" },
  { href: "/", label: "Pricing", anchor: "#pricing" },
];

export function Nav() {
  const pathname = usePathname();
  return (
    <nav className="nav wrap">
      <Link className="brand" href="/" aria-label="FoldReady home">
        <Mark size={40} />
        <span className="wordmark">foldready</span>
      </Link>
      <div className="links">
        {LINKS.map((l) => {
          const href = l.anchor && l.href === "/" ? "/#pricing" : l.href;
          const current = pathname === l.href;
          return (
            <Link key={l.label} href={href} aria-current={current ? "page" : undefined}>
              {l.label}
            </Link>
          );
        })}
      </div>
      <div className="right">
        <ThemeToggle />
        <Link className="btn btn-pri" href="/#pricing" style={{ padding: "11px 18px", fontSize: "14px" }}>
          Score my app
        </Link>
      </div>
    </nav>
  );
}
