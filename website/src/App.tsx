import { Header } from "./components/Header";
import { Hero } from "./components/Hero";
import { Features } from "./components/Features";
import { HowItWorks } from "./components/HowItWorks";
import { InstallGuide } from "./components/InstallGuide";
import { Details } from "./components/Details";
import { PrivacySecurity } from "./components/PrivacySecurity";
import { FAQ } from "./components/FAQ";
import { CTA } from "./components/CTA";
import { Footer } from "./components/Footer";
import { DownloadPage } from "./pages/DownloadPage";
import { UpdatesPage } from "./pages/UpdatesPage";

type AppProps = {
  page?: "home" | "download" | "updates";
};

export default function App({ page = "home" }: AppProps) {
  const isHome = page === "home";

  return (
    <div className="min-h-screen font-sans selection:bg-brand-red/30 selection:text-white bg-brand-bg overflow-x-hidden">
      <Header />
      <main>
        {isHome && (
          <>
            <Hero />
            <Features />
            <Details />
            <HowItWorks />
            <InstallGuide />
            <PrivacySecurity />
            <FAQ />
            <CTA />
          </>
        )}
        {page === "download" && <DownloadPage />}
        {page === "updates" && <UpdatesPage />}
      </main>
      <Footer />
    </div>
  );
}
