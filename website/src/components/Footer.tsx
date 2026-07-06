import { Github } from "lucide-react";
import { assets, links } from "../content";

export function Footer() {
  return (
    <footer className="border-t border-white/10 mt-20">
      <div className="max-w-7xl mx-auto px-6 py-12 flex flex-col md:flex-row items-center justify-between gap-6">
        <div className="flex items-center gap-3">
          <img
            src={assets.icon}
            alt="Battery Panic Icon"
            className="w-8 h-8 rounded-lg border border-brand-red/30"
          />
          <span className="font-display font-medium text-white/80">
            Battery Panic
          </span>
        </div>
        
        <div className="text-center text-sm text-white/40">
          <p>Developed by LeonTOfficial. Open source, local-first, and built for macOS.</p>
          <a
            href="https://discord.gg/JPjrw3ft"
            target="_blank"
            rel="noopener noreferrer"
            className="mt-1 inline-block hover:text-white"
          >
            Join the Battery Panic Discord
          </a>
        </div>

        <a
          href={links.github}
          target="_blank"
          rel="noopener noreferrer"
          className="text-white/40 hover:text-white transition-colors"
        >
          <Github className="w-5 h-5" />
          <span className="sr-only">GitHub</span>
        </a>
      </div>
    </footer>
  );
}
