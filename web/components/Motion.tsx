"use client";

import { useEffect } from "react";

export function PageMotion() {
  useEffect(() => {
    const doc = document.documentElement;
    doc.classList.add("fr");
    const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    if (!("IntersectionObserver" in window) || reduced) {
      document.querySelectorAll<HTMLElement>("[data-reveal]").forEach((el) => el.classList.add("in"));
      return;
    }
    const io = new IntersectionObserver(
      (entries) => {
        entries.forEach((en) => {
          if (en.isIntersecting) {
            en.target.classList.add("in");
            io.unobserve(en.target);
          }
        });
      },
      { threshold: 0.1, rootMargin: "0px 0px -6% 0px" }
    );
    document.querySelectorAll<HTMLElement>("[data-reveal]").forEach((el) => io.observe(el));
    return () => {
      doc.classList.remove("fr");
      io.disconnect();
    };
  }, []);
  return null;
}
