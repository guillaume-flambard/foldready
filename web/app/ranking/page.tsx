import type { Metadata } from "next";
import { RankingClient } from "./RankingClient";

export const metadata: Metadata = {
  title: "Fold-Ready Index — every iOS app, scored for the iPhone Fold",
  description:
    "Independent Fold-Ready Scores for open-source iOS apps, measured for the 7.8in inner display of the iPhone Fold.",
};

export default function RankingPage() {
  return <main className="wrap"><RankingClient /></main>;
}
