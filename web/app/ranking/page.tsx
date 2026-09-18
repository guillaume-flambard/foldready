import type { Metadata } from "next";
import { RankingClient } from "./RankingClient";

export const metadata: Metadata = {
  title: "Historical source audits | FoldReady",
  description:
    "Archived pre-announcement source scores. These are not current iPhone Duo compatibility results.",
};

export default function RankingPage() {
  return <main className="wrap"><RankingClient /></main>;
}
