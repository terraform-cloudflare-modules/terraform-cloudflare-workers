import { DurableObject } from "cloudflare:workers";

export class Counter extends DurableObject {
  async fetch() {
    const count = (await this.ctx.storage.get("count") ?? 0) + 1;
    await this.ctx.storage.put("count", count);
    return new Response(String(count));
  }
}

export default {
  async fetch(request, env) {
    if (new URL(request.url).pathname.startsWith("/api/")) {
      return env.COUNTER.get(env.COUNTER.idFromName("shared")).fetch(request);
    }
    return env.ASSETS.fetch(request);
  },
  async scheduled(_event, env) {
    // Read shared configuration without overwriting Terraform-owned KV entries.
    console.log(await env.CONFIG.get("features"));
  },
};
