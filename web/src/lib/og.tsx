import { readFile } from "node:fs/promises";
import { join } from "node:path";
import { ImageResponse } from "next/og";
import { shareImageSize } from "@/lib/metadata";
import { site } from "@/lib/site";

// Share cards for Open Graph and X, drawn with the site's colors and font. Served by app/og/[image]/route.tsx.

const assets = join(process.cwd(), "src/assets/og");
const background = "#0c0908";
const orange = "linear-gradient(135deg, #fcd34d 0%, #fb923c 45%, #ea580c 100%)";

async function png(path: string) {
  return `data:image/png;base64,${(await readFile(path)).toString("base64")}`;
}

async function render(card: React.ReactElement) {
  // Geist, subset to Latin without OpenType layout features: Satori measured words without kerning but drew them with
  // it, which left uneven gaps after words like "Workers".
  const [regular, semibold] = await Promise.all([
    readFile(join(assets, "Geist-Regular.ttf")),
    readFile(join(assets, "Geist-SemiBold.ttf")),
  ]);
  return new ImageResponse(card, {
    ...shareImageSize,
    fonts: [
      { name: "Geist", data: regular, weight: 400, style: "normal" },
      { name: "Geist", data: semibold, weight: 600, style: "normal" },
    ],
  });
}

function Frame({ children }: { children: React.ReactNode }) {
  return (
    <div
      style={{
        display: "flex",
        width: "100%",
        height: "100%",
        position: "relative",
        backgroundColor: background,
        backgroundImage:
          "radial-gradient(circle at 12% 0%, rgba(255,122,47,0.30), rgba(255,122,47,0) 55%), radial-gradient(circle at 100% 100%, rgba(255,90,31,0.14), rgba(255,90,31,0) 50%)",
        color: "#f7f1ec",
        fontFamily: "Geist",
      }}
    >
      {children}
    </div>
  );
}

function Brand({ icon, size }: { icon: string; size: number }) {
  return (
    <div style={{ display: "flex", alignItems: "center", gap: size * 0.3 }}>
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img src={icon} width={size} height={size} alt="" />
      <div style={{ fontSize: size * 0.56, fontWeight: 600, letterSpacing: -0.5 }}>{site.name}</div>
    </div>
  );
}

/** The home page card: the headline beside the large widget (cropped from docs/images/readme-widgets-dark.png). */
export async function homeCard() {
  const [icon, widget] = await Promise.all([png(join(process.cwd(), "public/icon.png")), png(join(assets, "widget.png"))]);
  const words = ["Know", "your", "Cloudflare", "limits", "before", "you", "hit", "them."];
  return render(
    <Frame>
      <div style={{ display: "flex", flexDirection: "column", justifyContent: "space-between", width: 690, padding: "60px 0 56px 72px" }}>
        <Brand icon={icon} size={52} />
        <div style={{ display: "flex", flexDirection: "column" }}>
          <div style={{ display: "flex", flexWrap: "wrap", fontSize: 60, fontWeight: 600, lineHeight: 1.06, letterSpacing: -2 }}>
            {words.map((w) => (
              <span
                key={w}
                style={
                  w === "limits"
                    ? { marginRight: 14, backgroundImage: orange, backgroundClip: "text", color: "transparent" }
                    : { marginRight: 14 }
                }
              >
                {w}
              </span>
            ))}
          </div>
          <div style={{ marginTop: 22, fontSize: 25, lineHeight: 1.4, color: "rgba(255,255,255,0.62)" }}>
            Workers, Durable Objects, KV, D1 and Workers AI usage in your Mac menu bar, against your plan.
          </div>
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: 18, fontSize: 22, color: "rgba(255,255,255,0.55)" }}>
          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: 10,
              padding: "8px 16px",
              borderRadius: 999,
              border: "1px solid rgba(255,255,255,0.14)",
              backgroundColor: "rgba(255,255,255,0.05)",
              color: "rgba(255,255,255,0.8)",
            }}
          >
            <div style={{ width: 9, height: 9, borderRadius: 9, backgroundColor: "#fb923c" }} />
            Free and open source
          </div>
          {new URL(site.url).host}
        </div>
      </div>
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img
        src={widget}
        width={410}
        height={430}
        alt=""
        style={{
          position: "absolute",
          right: 60,
          top: 100,
          borderRadius: 27,
          boxShadow: "0 30px 80px rgba(0,0,0,0.55), 0 0 0 1px rgba(255,255,255,0.06)",
        }}
      />
    </Frame>,
  );
}

/** A text page's card (guides and the rest): its title and description under the brand. */
export async function pageCard({ eyebrow, title, description, path }: { eyebrow: string; title: string; description: string; path: string }) {
  const icon = await png(join(process.cwd(), "public/icon.png"));
  return render(
    <Frame>
      {/* The app icon's usage ring, large and faint, bleeding off the right edge. */}
      <svg width="560" height="560" viewBox="0 0 560 560" style={{ position: "absolute", right: -170, top: 35 }}>
        <circle cx="280" cy="280" r="230" fill="none" stroke="rgba(255,255,255,0.05)" strokeWidth="44" />
        <circle
          cx="280"
          cy="280"
          r="230"
          fill="none"
          stroke="rgba(251,146,60,0.30)"
          strokeWidth="44"
          strokeLinecap="round"
          strokeDasharray={`${2 * Math.PI * 230 * 0.36} ${2 * Math.PI * 230}`}
          transform="rotate(-90 280 280)"
        />
      </svg>
      <div style={{ display: "flex", flexDirection: "column", justifyContent: "space-between", width: "100%", padding: "64px 72px 60px" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 20 }}>
          <Brand icon={icon} size={52} />
          <div
            style={{
              padding: "6px 16px",
              borderRadius: 999,
              border: "1px solid rgba(251,146,60,0.35)",
              backgroundColor: "rgba(251,146,60,0.10)",
              color: "#fdba74",
              fontSize: 21,
              fontWeight: 600,
            }}
          >
            {eyebrow}
          </div>
        </div>
        <div style={{ display: "flex", flexDirection: "column", maxWidth: 900 }}>
          <div style={{ fontSize: title.length > 40 ? 62 : 72, fontWeight: 600, lineHeight: 1.08, letterSpacing: -2.2 }}>{title}</div>
          <div style={{ marginTop: 24, fontSize: 27, lineHeight: 1.42, color: "rgba(255,255,255,0.6)" }}>{description}</div>
        </div>
        <div style={{ display: "flex", fontSize: 22, color: "rgba(255,255,255,0.5)" }}>
          {new URL(site.url).host}
          {path}
        </div>
      </div>
    </Frame>,
  );
}
