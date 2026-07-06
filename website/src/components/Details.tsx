import { motion } from "motion/react";
import { BatteryCharging, BellRing, Clock3, Gauge, RefreshCw, Volume2 } from "lucide-react";

const details = [
  {
    icon: Gauge,
    title: "Custom low-battery threshold",
    text: "Choose the exact percentage where Battery Panic should step in. The default is 10%.",
  },
  {
    icon: BatteryCharging,
    title: "Charging reminder",
    text: "Get a short blue-green reminder when your Mac reaches your chosen charging percentage.",
  },
  {
    icon: BellRing,
    title: "Critical 2% mode",
    text: "At 2% or below, Battery Panic switches to stronger wording, stronger glow, and urgent alarm behavior.",
  },
  {
    icon: Volume2,
    title: "Sound alerts",
    text: "Use the original Battery Panic siren or macOS system warning sounds, with behavior tuned for real alerts.",
  },
  {
    icon: Clock3,
    title: "Temporary pause",
    text: "Pause alarms for 30 minutes when you need quiet, without turning protection off forever.",
  },
  {
    icon: RefreshCw,
    title: "Built-in updates",
    text: "Sparkle update support lets installed users check for new versions directly from the menu bar.",
  },
];

export function Details() {
  return (
    <section id="details" className="relative z-10 border-y border-white/5 bg-black/20 px-6 py-28">
      <div className="mx-auto max-w-7xl">
        <motion.div
          initial={{ opacity: 0, y: 24 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-120px" }}
          transition={{ duration: 0.7 }}
          className="mb-16 max-w-3xl"
        >
          <p className="mb-4 text-sm font-bold uppercase tracking-[0.28em] text-brand-teal">
            App details
          </p>
          <h2 className="font-display text-4xl font-bold tracking-tight text-white md:text-5xl">
            More than a normal notification.
          </h2>
          <p className="mt-5 text-lg font-light leading-relaxed text-white/60">
            Battery Panic combines menu bar status, pulsing overlays, warning sounds, charging
            reminders, and update support in one small native macOS app.
          </p>
        </motion.div>

        <div className="grid grid-cols-1 gap-5 md:grid-cols-2 lg:grid-cols-3">
          {details.map((item, index) => (
            <motion.article
              key={item.title}
              initial={{ opacity: 0, y: 22 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, margin: "-100px" }}
              transition={{ duration: 0.55, delay: index * 0.06 }}
              className="rounded-[1.4rem] border border-white/10 bg-white/[0.035] p-7 transition-all duration-300 hover:-translate-y-1 hover:border-white/20 hover:bg-white/[0.055]"
            >
              <div className="mb-5 flex h-12 w-12 items-center justify-center rounded-2xl border border-white/10 bg-white/[0.05] text-brand-teal">
                <item.icon className="h-6 w-6" />
              </div>
              <h3 className="font-display text-xl font-bold text-white">
                {item.title === "Critical 2% mode" ? (
                  <>
                    Critical <span className="text-brand-red">2%</span> mode
                  </>
                ) : (
                  item.title
                )}
              </h3>
              <p className="mt-3 leading-relaxed text-white/55">{item.text}</p>
            </motion.article>
          ))}
        </div>
      </div>
    </section>
  );
}
