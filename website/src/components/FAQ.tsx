import { motion } from "motion/react";

const faqs = [
  {
    q: <>Is Battery Panic <span className="text-brand-green">free</span>?</>,
    a: <>Yes, it is completely <span className="text-brand-green font-medium">free</span> and open-source. You can review the full codebase, contribute, or build it yourself from GitHub.</>
  },
  {
    q: "Will this app drain my battery faster?",
    a: "Not at all. Battery Panic is written natively for macOS using Swift. It relies on the operating system's built-in power management APIs, meaning it consumes virtually zero CPU cycles while idling in your menu bar."
  },
  {
    q: "How do I customize the warnings?",
    a: "Click the Battery Panic icon in your macOS menu bar and select 'Settings'. From there, you can adjust the panic threshold percentage, toggle sounds, and modify the intensity of the visual overlay."
  },
  {
    q: "Does Battery Panic support charging reminders?",
    a: "Yes. You can enable a charging reminder and choose a percentage between 50% and 100%. The reminder appears once per charging session."
  },
  {
    q: "Why can macOS block the first launch?",
    a: "Battery Panic is open source and currently distributed outside the Mac App Store. If macOS blocks it once, open Privacy & Security, scroll down, and approve Battery Panic with Open Anyway."
  },
  {
    q: "How do updates work?",
    a: "Battery Panic includes Sparkle update support. After installing a supported release, you can use Check for Updates from the menu bar app."
  }
];

export function FAQ() {
  return (
    <section id="faq" className="py-32 px-6 relative z-10">
      <div className="max-w-4xl mx-auto">
        <div className="text-center mb-20">
          <h2 className="font-display font-bold text-4xl md:text-5xl text-white mb-6">
            Frequently Asked Questions
          </h2>
        </div>

        <div className="space-y-6">
          {faqs.map((faq, index) => (
            <motion.div
              key={index}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, margin: "-100px" }}
              transition={{ duration: 0.5, delay: index * 0.1 }}
              className="bg-white/5 border border-white/10 rounded-2xl p-8"
            >
              <h3 className="font-display font-bold text-xl text-white mb-4">{faq.q}</h3>
              <p className="text-white/60 leading-relaxed font-light">{faq.a}</p>
            </motion.div>
          ))}
        </div>

      </div>
    </section>
  );
}
