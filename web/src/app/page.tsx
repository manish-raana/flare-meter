import { FAQ } from "@/components/sections/FAQ";
import { Features } from "@/components/sections/Features";
import { Footer } from "@/components/sections/Footer";
import { GuidesTeaser } from "@/components/sections/GuidesTeaser";
import { Hero } from "@/components/sections/Hero";
import { Nav } from "@/components/sections/Nav";
import { OpenSource } from "@/components/sections/OpenSource";
import { PrivacyFlow } from "@/components/sections/PrivacyFlow";
import { Setup } from "@/components/sections/Setup";
import { Story } from "@/components/sections/Story";
import { Ticker } from "@/components/sections/Ticker";
import { StructuredData } from "@/components/StructuredData";

export default function Home() {
  return (
    <>
      <StructuredData />
      <Nav />
      <main>
        <Hero />
        <Ticker />
        <Story />
        <Features />
        <Setup />
        <PrivacyFlow />
        <OpenSource />
        <FAQ />
        <GuidesTeaser />
      </main>
      <Footer />
    </>
  );
}
