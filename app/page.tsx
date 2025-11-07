import Image from "next/image";

export default function Home() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-zinc-50 font-sans dark:bg-black">
      <main className="flex min-h-screen w-full max-w-3xl flex-col items-center justify-between py-32 px-16 bg-white dark:bg-black sm:items-start">
        <div className="flex flex-col items-center gap-6 text-center sm:items-start sm:text-left">
          <h1 className="max-w-xs text-3xl font-semibold leading-10 tracking-tight text-black dark:text-zinc-50">
            ZedWx - Zambian Weather
          </h1>
          <p className="max-w-md text-lg leading-8 text-zinc-600 dark:text-zinc-400">
            Zambian weather is generally warm and tropical, with distinct wet and dry seasons. The rainy season typically runs from November to April, bringing heavy showers and thunderstorms, while the dry season from May to October is characterized by clear skies and cooler nights. Regional variations exist, with the northern and northwestern provinces receiving more rainfall, and southern areas experiencing hotter, drier conditions.
          </p>
          <p>Overall, Zambia's climate supports diverse ecosystems and agricultural activities.</p>
        </div>
        <div className="flex flex-col gap-4 text-base font-medium sm:flex-row">
          
        </div>
      </main>
    </div>
  );
}
