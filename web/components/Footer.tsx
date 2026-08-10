import { Mark } from "@/components/Mark";

export function Footer() {
  return (
    <footer className="foot wrap">
      <div className="foot-top">
        <Mark size={32} />
        <span className="wordmark">foldready</span>
        <span className="mono" style={{ marginLeft: "auto" }}>hello@foldready.com</span>
      </div>
    </footer>
  );
}
