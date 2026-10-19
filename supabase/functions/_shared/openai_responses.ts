/** OpenAI Responses API helper (vision + JSON). Key stays server-side only. */

function buildInput(userText: string, imageDataUrl?: string) {
  const content: Array<Record<string, unknown>> = [
    { type: "input_text", text: userText },
  ];
  if (imageDataUrl) {
    content.push({
      type: "input_image",
      image_url: imageDataUrl,
      detail: "high",
    });
  }
  return [{ role: "user", content }];
}

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
      input: buildInput(args.userText, args.imageDataUrl),
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

/**
 * Stream Responses API JSON text. Yields `{ delta, full }` as output text grows.
 * Caller parses partial JSON for progressive UI.
 */
export async function* responsesJsonTextStream(args: {
  instructions: string;
  userText: string;
  imageDataUrl?: string;
  model?: string;
  temperature?: number;
  signal?: AbortSignal;
}): AsyncGenerator<{ delta: string; full: string }, string, void> {
  const apiKey = Deno.env.get("OPENAI_API_KEY");
  if (!apiKey) {
    throw new Error("OPENAI_API_KEY is not configured");
  }

  const model = args.model ?? "gpt-4o-mini";
  const response = await fetch("https://api.openai.com/v1/responses", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model,
      temperature: args.temperature ?? 0.75,
      stream: true,
      instructions: args.instructions,
      input: buildInput(args.userText, args.imageDataUrl),
      text: { format: { type: "json_object" } },
    }),
    signal: args.signal,
  });

  if (!response.ok) {
    const errText = (await response.text()).slice(0, 180);
    throw new Error(`OpenAI error ${response.status}: ${errText}`);
  }
  if (!response.body) {
    throw new Error("Empty OpenAI stream");
  }

  const reader = response.body.getReader();
  const decoder = new TextDecoder();
  let buffer = "";
  let full = "";

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    buffer += decoder.decode(value, { stream: true });
    const parts = buffer.split("\n");
    buffer = parts.pop() ?? "";

    for (const line of parts) {
      const trimmed = line.trim();
      if (!trimmed.startsWith("data:")) continue;
      const payload = trimmed.slice(5).trim();
      if (!payload || payload === "[DONE]") continue;
      let event: Record<string, unknown>;
      try {
        event = JSON.parse(payload) as Record<string, unknown>;
      } catch {
        continue;
      }
      const type = String(event.type ?? "");
      let delta = "";
      if (type === "response.output_text.delta" && typeof event.delta === "string") {
        delta = event.delta;
      } else if (
        type === "response.content_part.delta" &&
        event.delta &&
        typeof event.delta === "object" &&
        typeof (event.delta as Record<string, unknown>).text === "string"
      ) {
        delta = String((event.delta as Record<string, unknown>).text);
      }
      if (!delta) continue;
      full += delta;
      yield { delta, full };
    }
  }

  if (!full.trim()) {
    throw new Error("Empty OpenAI stream");
  }
  return full;
}

/** Pull incomplete JSON string fields for progressive reply cards. */
export function extractPartialReplyFields(raw: string): {
  natural: string;
  playful: string;
  latestIncoming: string;
} {
  return {
    natural: readPartialJsonString(raw, "natural") ?? "",
    playful: readPartialJsonString(raw, "playful") ?? "",
    latestIncoming: readPartialJsonString(raw, "latest_incoming") ?? "",
  };
}

function readPartialJsonString(raw: string, key: string): string | null {
  const marker = `"${key}"`;
  const keyIdx = raw.indexOf(marker);
  if (keyIdx < 0) return null;
  const afterKey = raw.slice(keyIdx + marker.length);
  const colon = afterKey.indexOf(":");
  if (colon < 0) return null;
  let i = colon + 1;
  while (i < afterKey.length && /\s/.test(afterKey[i]!)) i++;
  if (afterKey[i] !== '"') return null;
  i++;
  let out = "";
  while (i < afterKey.length) {
    const ch = afterKey[i]!;
    if (ch === "\\") {
      const next = afterKey[i + 1];
      if (next == null) break;
      if (next === "n") out += "\n";
      else if (next === "t") out += "\t";
      else if (next === '"') out += '"';
      else if (next === "\\") out += "\\";
      else out += next;
      i += 2;
      continue;
    }
    if (ch === '"') break;
    out += ch;
    i++;
  }
  return out;
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
