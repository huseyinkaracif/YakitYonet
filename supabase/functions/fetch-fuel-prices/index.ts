import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (_req) => {
  try {
    // 1. Petrol Ofisi'nden fiyat çek
    const formData = new FormData();
    formData.append("template", "1");
    formData.append("cityId", "06");
    formData.append("districtId", "");
    formData.append("isBp", "false");

    const response = await fetch("https://www.petrolofisi.com.tr/Fuel/Search", {
      method: "POST",
      body: formData,
    });

    if (!response.ok) {
      throw new Error(`Petrol Ofisi HTTP ${response.status}`);
    }

    const html = await response.text();

    // 2. js-counter span'larından fiyatları parse et
    // Sıra: Kurşunsuz 95 → benzin, Diesel → dizel, Otogaz → lpg
    const counterRegex = /class="scrollspy js-counter">\s*([\d.]+)\s*<\/span>/g;
    const matches: number[] = [];
    let match;
    while ((match = counterRegex.exec(html)) !== null) {
      matches.push(parseFloat(match[1]));
    }

    if (matches.length < 3) {
      throw new Error(
        `Parse failed: only ${matches.length} prices found. Site structure may have changed.`
      );
    }

    const benzin = matches[0];
    const dizel = matches[1];
    const lpg = matches[2];
    const elektrik = 15.90;

    // 3. Türkiye saatine göre bugünün tarihi (UTC+3)
    const now = new Date();
    const trOffset = 3 * 60 * 60 * 1000;
    const trDate = new Date(now.getTime() + trOffset);
    const dateStr = trDate.toISOString().split("T")[0]; // YYYY-MM-DD

    // 4. Supabase'e upsert
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { error } = await supabase
      .from("prices")
      .upsert(
        {
          date: dateStr,
          benzin,
          dizel,
          lpg,
          elektrik,
          updated_at: new Date().toISOString(),
        },
        { onConflict: "date" }
      );

    if (error) throw error;

    console.log(`fetch-fuel-prices: ${dateStr} benzin=${benzin} dizel=${dizel} lpg=${lpg}`);

    return new Response(
      JSON.stringify({ success: true, date: dateStr, benzin, dizel, lpg, elektrik }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("fetch-fuel-prices error:", err);
    return new Response(
      JSON.stringify({ success: false, error: String(err) }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
