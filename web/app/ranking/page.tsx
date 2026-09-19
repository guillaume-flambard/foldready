import type { Metadata } from "next";
import { RankingClient } from "./RankingClient";

export const metadata: Metadata = {
  title: "Source audits of twenty iOS apps | FoldReady",
  description:
    "Twenty open-source iOS apps audited from source under contract v5. Source signals, not iPhone Duo runtime verdicts.",
};

export default function RankingPage() {
  return <main className="wrap"><RankingClient /></main>;
}
