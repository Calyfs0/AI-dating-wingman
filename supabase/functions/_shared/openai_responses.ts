/** OpenAI Responses API helper (vision + JSON). Key stays server-side only. */

export async function responsesJson(args: {
  instructions: string;
  userText: string;
  imageDataUrl?: string;
  model?: string;
  temperature?: number;
}): Promise<Record<string, unknown>> {
  const apiKey = Deno.env.get("OPENAI_API_KEY");
  if (!apiKey) {
    throw new Error("OPENAI_API_KEY is not configured");
  }

  const model = args.model ?? "gpt-4o-mini";
  const content: Array<Record<string, unknown>> = [
    { type: "input_text", text: args.userText },
  ];
  if (args.imageDataUrl) {
    content.push({
      type: "input_image",
      image_url: args.imageDataUrl,
      detail: "high",
    });
  }

  const response = await fetch("https://api.openai.com/v1/responses", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model,
      temperature: args.temperature ?? 0.75,
      instructions: args.instructions,
      input: [
        {
          role: "user",
          content,
        },
      ],
      text: { format: { type: "json_object" } },
    }),
  });

  if (!response.ok) {
    const errText = (await response.text()).slice(0, 180);
    throw new Error(`OpenAI error ${response.status}: ${errText}`);
  }

  const payload = await response.json();
  const text = extractOutputText(payload);
  if (!text) {
    throw new Error("Empty OpenAI response");
  }

  try {
    return JSON.parse(text) as Record<string, unknown>;
  } catch {
    throw new Error("Invalid JSON from OpenAI");
  }
}

function extractOutputText(payload: unknown): string | null {
  if (!payload || typeof payload !== "object") return null;
  const root = payload as Record<string, unknown>;

  if (typeof root.output_text === "string" && root.output_text.trim()) {
    return root.output_text.trim();
  }

  const output = root.output;
  if (!Array.isArray(output)) return null;

  for (const item of output) {
    if (!item || typeof item !== "object") continue;
    const content = (item as Record<string, unknown>).content;
    if (!Array.isArray(content)) continue;
    for (const part of content) {
      if (!part || typeof part !== "object") continue;
      const record = part as Record<string, unknown>;
      if (
        (record.type === "output_text" || record.type === "text") &&
        typeof record.text === "string" &&
        record.text.trim()
      ) {
        return record.text.trim();
      }
    }
  }

  return null;
}
