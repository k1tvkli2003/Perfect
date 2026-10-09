const CONTRACT_VERSION = 1;
// Local-first rule: chat runs on the per-device `opencode serve` runtime with
// the pinned opencode/muse-spark-1.3-contributor-free model. This edge
// function is sync/receipt only (apply_proposal) and never calls a model.
// No provider key, chat model, or chat-completions URL belongs here.
const PROMPT_VERSION = "perfect-local-v1";
const AGENT_SCHEMA_VERSION = "agent-plan-v1";
const MAX_REQUEST_BYTES = 8 * 1024 * 1024 + 256000;

type JsonObject = Record<string, unknown>;

type AuthenticatedUser = {
  id: string;
};

type AgentProposalItem = {
  id: string;
  kind: "one_off_task" | "recurring_task" | "habit" | "project";
  title: string;
  payload: JsonObject;
};

type AgentProposal = {
  submission_id: string;
  title: string;
  summary: string;
  items: AgentProposalItem[];
  requires_confirmation: true;
};

class AgentError extends Error {
  constructor(
    readonly code: string,
    message: string,
    readonly status: number,
    readonly retryable = false,
  ) {
    super(message);
  }
}

const corsHeaders = {
  "access-control-allow-origin": "*",
  "access-control-allow-headers":
    "authorization, apikey, content-type, x-client-info",
  "access-control-allow-methods": "POST, OPTIONS",
};

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return errorResponse(
      new AgentError("method_not_allowed", "Only POST is supported.", 405),
    );
  }

  const startedAt = Date.now();
  try {
    const environment = readEnvironment();
    const authorization = readAuthorization(request);
    const user = await authenticateOwner(environment, authorization);
    const body = await readJsonBody(request);
    assertContract(body);

    const operationId = requiredUuid(body.operation_id, "operation_id");
    const action = optionalString(body.action, 40) ?? "apply_proposal";
    if (action !== "apply_proposal") {
      throw new AgentError(
        "unsupported_action",
        "This edge function only applies confirmed proposals. Chat runs on the device-local runtime.",
        400,
      );
    }
    {
      const conversationId = requiredUuid(
        body.conversation_id,
        "conversation_id",
      );
      const proposal = validateProposal(body.proposal);
      const sourceMessageId = await requirePersistedProposal(
        environment,
        authorization,
        conversationId,
        proposal,
      );
      const receipt = await applyProposal(
        environment,
        authorization,
        proposal,
      );
      const message = assistantMessage(
        `انجام شد؛ ${proposal.items.length} مورد به‌صورت «پیشنهاد ایجنت» وارد Perfect! شد و از مسیر همگام‌سازی روی دستگاه‌ها دیده می‌شود.`,
        derivedUuid(operationId, 0xa2),
      );
      const historySynced = await persistAppliedProposal(
        environment,
        authorization,
        {
          operationId,
          conversationId,
          sourceMessageId,
          assistant: message,
          proposal,
          applyResult: requiredObject(receipt, "apply result"),
        },
      );
      return jsonResponse({
        schema_version: CONTRACT_VERSION,
        operation_id: operationId,
        conversation_id: conversationId,
        message,
        apply_result: receipt,
        history_synced: historySynced,
        telemetry: telemetry(null, Date.now() - startedAt),
      });
    }
  } catch (error) {
    return errorResponse(normalizeError(error));
  }
});

function readEnvironment() {
  const supabaseUrl = requiredEnvironment("SUPABASE_URL").replace(/\/+$/, "");
  const supabaseKey = (
    Deno.env.get("SUPABASE_ANON_KEY") ??
      Deno.env.get("SUPABASE_PUBLISHABLE_KEY") ??
      ""
  ).trim();
  if (supabaseKey.length < 20) {
    throw new AgentError(
      "server_not_configured",
      "Perfect AI is not configured on the server.",
      503,
      true,
    );
  }
  return {
    supabaseUrl,
    supabaseKey,
  };
}

function requiredEnvironment(name: string): string {
  const value = Deno.env.get(name)?.trim() ?? "";
  if (value.length === 0) {
    throw new AgentError(
      "server_not_configured",
      "Perfect AI is not configured on the server.",
      503,
      true,
    );
  }
  return value;
}

function readAuthorization(request: Request): string {
  const value = request.headers.get("authorization")?.trim() ?? "";
  if (!/^Bearer\s+\S+$/i.test(value)) {
    throw new AgentError(
      "authentication_required",
      "Sign in to use Perfect AI.",
      401,
    );
  }
  return value;
}

async function authenticateOwner(
  environment: ReturnType<typeof readEnvironment>,
  authorization: string,
): Promise<AuthenticatedUser> {
  const response = await fetchWithTimeout(
    `${environment.supabaseUrl}/auth/v1/user`,
    {
      headers: {
        authorization,
        apikey: environment.supabaseKey,
      },
    },
    10000,
  );
  if (!response.ok) {
    throw new AgentError(
      "authentication_required",
      "Your Perfect session needs to be refreshed.",
      401,
    );
  }
  const payload = await readBoundedJsonResponse(
    response,
    262144,
    "authentication response",
  );
  const id = typeof payload?.id === "string" ? payload.id : "";
  if (!isUuid(id)) {
    throw new AgentError(
      "authentication_required",
      "Your Perfect session is invalid.",
      401,
    );
  }
  return { id };
}

async function readJsonBody(request: Request): Promise<JsonObject> {
  const length = Number(request.headers.get("content-length") ?? "0");
  if (Number.isFinite(length) && length > MAX_REQUEST_BYTES) {
    throw new AgentError(
      "request_too_large",
      "This AI request is too large.",
      413,
    );
  }
  let raw: string;
  try {
    raw = await request.text();
  } catch {
    throw new AgentError(
      "invalid_json",
      "The AI request is not valid JSON.",
      400,
    );
  }
  if (new TextEncoder().encode(raw).byteLength > MAX_REQUEST_BYTES) {
    throw new AgentError(
      "request_too_large",
      "This AI request is too large.",
      413,
    );
  }
  let payload: unknown;
  try {
    payload = JSON.parse(raw);
  } catch {
    throw new AgentError(
      "invalid_json",
      "The AI request is not valid JSON.",
      400,
    );
  }
  return requiredObject(payload, "request");
}

function assertContract(body: JsonObject) {
  if (body.schema_version !== CONTRACT_VERSION) {
    throw new AgentError(
      "unsupported_schema",
      "Update Perfect! to use this AI contract.",
      400,
    );
  }
}

function validateProposal(value: unknown): AgentProposal {
  const proposal = requiredObject(value, "proposal");
  if (proposal.requires_confirmation !== true) {
    throw new AgentError(
      "confirmation_required",
      "Review and confirm this proposal before applying it.",
      409,
    );
  }
  const submissionId = requiredUuid(
    proposal.submission_id,
    "proposal submission_id",
  );
  const title = requiredString(proposal.title, 160, "proposal title");
  const summary = optionalString(proposal.summary, 4000) ?? "";
  if (!Array.isArray(proposal.items) || proposal.items.length < 1) {
    throw new AgentError(
      "invalid_proposal",
      "The proposal has no items.",
      400,
    );
  }
  if (proposal.items.length > 30) {
    throw new AgentError(
      "proposal_too_large",
      "Apply at most 30 proposed items at once.",
      422,
    );
  }
  const ids = new Set<string>();
  const items = proposal.items.map((raw, index): AgentProposalItem => {
    const item = requiredObject(raw, `proposal item ${index + 1}`);
    const id = requiredUuid(item.id, `proposal item ${index + 1} id`);
    if (ids.has(id)) {
      throw new AgentError(
        "invalid_proposal",
        "The proposal contains a duplicate item.",
        400,
      );
    }
    ids.add(id);
    const itemTitle = requiredString(
      item.title,
      160,
      `proposal item ${index + 1} title`,
    );
    const payload = requiredObjectOrEmpty(item.payload);
    if ("agent_proposal" in payload) {
      throw new AgentError(
        "invalid_proposal",
        "Agent review metadata is server-managed.",
        400,
      );
    }
    if (new TextEncoder().encode(JSON.stringify(payload)).byteLength > 20000) {
      throw new AgentError(
        "proposal_too_large",
        "One proposed item contains too much detail.",
        422,
      );
    }
    return {
      id,
      kind: requiredKind(item.kind),
      title: itemTitle,
      payload,
    };
  });
  return {
    submission_id: submissionId,
    title,
    summary,
    items,
    requires_confirmation: true,
  };
}

async function requirePersistedProposal(
  environment: ReturnType<typeof readEnvironment>,
  authorization: string,
  conversationId: string,
  proposal: AgentProposal,
): Promise<string> {
  const conversationQuery = new URLSearchParams({
    select: "id",
    id: `eq.${conversationId}`,
    status: "eq.active",
    deleted_at: "is.null",
    limit: "1",
  });
  const conversationResponse = await fetchWithTimeout(
    `${environment.supabaseUrl}/rest/v1/ai_conversations?${conversationQuery}`,
    {
      headers: {
        authorization,
        apikey: environment.supabaseKey,
        accept: "application/json",
      },
    },
    10000,
  );
  if (!conversationResponse.ok) {
    throw new AgentError(
      "confirmation_unavailable",
      "Perfect could not verify this proposal. Try again shortly.",
      503,
      true,
    );
  }
  const conversations = await readBoundedJsonResponse(
    conversationResponse,
    262144,
    "proposal conversation",
  );
  if (!Array.isArray(conversations) || conversations.length !== 1) {
    throw new AgentError(
      "confirmation_required",
      "This proposal belongs to a closed conversation. Ask Perfect AI to prepare it again.",
      409,
    );
  }

  const query = new URLSearchParams({
    select: "id,proposal",
    conversation_id: `eq.${conversationId}`,
    role: "eq.assistant",
    order: "created_at.desc",
    limit: "100",
  });
  const response = await fetchWithTimeout(
    `${environment.supabaseUrl}/rest/v1/ai_messages?${query}`,
    {
      headers: {
        authorization,
        apikey: environment.supabaseKey,
        accept: "application/json",
      },
    },
    10000,
  );
  if (!response.ok) {
    throw new AgentError(
      "confirmation_unavailable",
      "Perfect could not verify this proposal. Try again shortly.",
      503,
      true,
    );
  }
  const payload = await readBoundedJsonResponse(
    response,
    4 * 1024 * 1024,
    "proposal confirmation",
  );
  if (!Array.isArray(payload)) {
    throw new AgentError(
      "confirmation_unavailable",
      "Perfect could not verify this proposal. Try again shortly.",
      503,
      true,
    );
  }
  const expected = canonicalJson(proposal);
  for (const value of payload) {
    const message = requiredObjectOrNull(value);
    const id = typeof message?.id === "string" ? message.id : "";
    const storedProposal = requiredObjectOrNull(message?.proposal);
    if (
      isUuid(id) && storedProposal !== null &&
      canonicalJson(storedProposal) === expected
    ) {
      return id.toLowerCase();
    }
  }
  throw new AgentError(
    "confirmation_required",
    "This proposal changed or is no longer available. Ask Perfect AI to prepare it again.",
    409,
  );
}

async function applyProposal(
  environment: ReturnType<typeof readEnvironment>,
  authorization: string,
  proposal: AgentProposal,
): Promise<unknown> {
  const document = {
    schema_version: 1,
    submission_id: proposal.submission_id,
    agent_device_id: "253bd7ff-1448-4d21-a3bf-b69e55c46313",
    source: {
      agent: "Perfect AI Dock",
      model: "opencode/muse-spark-1.3-contributor-free",
      version: PROMPT_VERSION,
      run_id: proposal.submission_id,
    },
    plan: {
      title: proposal.title,
      summary: proposal.summary,
    },
    items: proposal.items,
  };
  const response = await fetchWithTimeout(
    `${environment.supabaseUrl}/rest/v1/rpc/submit_agent_plan`,
    {
      method: "POST",
      headers: {
        authorization,
        apikey: environment.supabaseKey,
        "content-type": "application/json",
      },
      body: JSON.stringify({ p_document: document }),
    },
    20000,
  );
  if (!response.ok) {
    if (response.status === 404) {
      throw new AgentError(
        "agent_plan_not_deployed",
        "The Perfect agent-plan migration is not deployed yet.",
        503,
        true,
      );
    }
    throw new AgentError(
      "proposal_apply_failed",
      "Perfect could not apply this proposal.",
      response.status >= 500 ? 503 : 422,
      response.status >= 500,
    );
  }
  return await readBoundedJsonResponse(
    response,
    4 * 1024 * 1024,
    "proposal receipt",
  );
}

async function persistAppliedProposal(
  environment: ReturnType<typeof readEnvironment>,
  authorization: string,
  input: {
    operationId: string;
    conversationId: string;
    sourceMessageId: string;
    assistant: ReturnType<typeof assistantMessage>;
    proposal: AgentProposal;
    applyResult: JsonObject;
  },
): Promise<boolean> {
  try {
    const conversationResponse = await callSupabaseRpc(
      environment,
      authorization,
      "upsert_ai_conversation",
      {
        p_conversation_id: input.conversationId,
        p_title: input.proposal.title,
        p_status: "active",
        p_retention_until: null,
        p_schema_version: 1,
      },
    );
    if (!conversationResponse.ok) return false;

    const messageResponse = await callSupabaseRpc(
      environment,
      authorization,
      "append_ai_message",
      {
        p_message: {
          schema_version: 1,
          message_id: input.assistant.id,
          conversation_id: input.conversationId,
          role: "assistant",
          status: "completed",
          content: input.assistant.text,
          proposal: input.proposal,
          result: input.applyResult,
          model: "opencode/muse-spark-1.3-contributor-free",
          prompt_version: PROMPT_VERSION,
        },
      },
    );
    if (!messageResponse.ok) return false;

    const auditResponse = await callSupabaseRpc(
      environment,
      authorization,
      "record_ai_action_result",
      {
        p_operation: {
          schema_version: 1,
          operation_id: input.operationId,
          idempotency_key: input.operationId,
          conversation_id: input.conversationId,
          message_id: input.sourceMessageId,
          status: "applied",
          proposal: input.proposal,
          result: input.applyResult,
          applied_submission_id: input.proposal.submission_id,
        },
      },
    );
    return auditResponse.ok;
  } catch {
    return false;
  }
}

function callSupabaseRpc(
  environment: ReturnType<typeof readEnvironment>,
  authorization: string,
  rpc: string,
  body: JsonObject,
) {
  return fetchWithTimeout(
    `${environment.supabaseUrl}/rest/v1/rpc/${rpc}`,
    {
      method: "POST",
      headers: {
        authorization,
        apikey: environment.supabaseKey,
        "content-type": "application/json",
      },
      body: JSON.stringify(body),
    },
    8000,
  );
}


function canonicalJson(value: unknown): string {
  if (Array.isArray(value)) {
    return `[${value.map(canonicalJson).join(",")}]`;
  }
  if (value !== null && typeof value === "object") {
    const object = value as JsonObject;
    return `{${
      Object.keys(object)
        .sort()
        .map((key) => `${JSON.stringify(key)}:${canonicalJson(object[key])}`)
        .join(",")
    }}`;
  }
  return JSON.stringify(value) ?? "null";
}

function derivedUuid(source: string, discriminator: number): string {
  const compact = source.replaceAll("-", "").toLowerCase();
  if (!/^[0-9a-f]{32}$/.test(compact)) return crypto.randomUUID();
  const bytes = Array.from(
    { length: 16 },
    (_, index) => Number.parseInt(compact.slice(index * 2, index * 2 + 2), 16),
  );
  bytes[15] ^= discriminator;
  bytes[6] = (bytes[6] & 0x0f) | 0x50;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  const hex = bytes.map((value) => value.toString(16).padStart(2, "0")).join(
    "",
  );
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${
    hex.slice(16, 20)
  }-${hex.slice(20)}`;
}

function assistantMessage(text: string, id: string = crypto.randomUUID()) {
  return {
    id,
    role: "assistant" as const,
    text,
    created_at: new Date().toISOString(),
  };
}

function telemetry(
  requestId: string | null,
  latencyMs: number,
) {
  return {
    request_id: requestId,
    model: "opencode/muse-spark-1.3-contributor-free",
    prompt_version: PROMPT_VERSION,
    schema_version: AGENT_SCHEMA_VERSION,
    latency_ms: latencyMs,
  };
}

async function readBoundedJsonResponse(
  response: Response,
  maximumBytes: number,
  label: string,
): Promise<any> {
  let raw: string;
  try {
    raw = await response.text();
  } catch {
    throw new AgentError(
      "invalid_remote_response",
      `Perfect received an unreadable ${label}.`,
      502,
      true,
    );
  }
  if (new TextEncoder().encode(raw).byteLength > maximumBytes) {
    throw new AgentError(
      "remote_response_too_large",
      `Perfect received an oversized ${label}.`,
      502,
      true,
    );
  }
  try {
    return JSON.parse(raw);
  } catch {
    throw new AgentError(
      "invalid_remote_response",
      `Perfect received an invalid ${label}.`,
      502,
      true,
    );
  }
}

async function fetchWithTimeout(
  input: string,
  init: RequestInit,
  timeoutMs: number,
) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    return await fetch(input, { ...init, signal: controller.signal });
  } catch (error) {
    if (error instanceof DOMException && error.name === "AbortError") {
      throw new AgentError(
        "ai_timeout",
        "Perfect AI took too long. Your message is still here—try again.",
        504,
        true,
      );
    }
    throw new AgentError(
      "network_unavailable",
      "Perfect AI could not reach its server.",
      503,
      true,
    );
  } finally {
    clearTimeout(timer);
  }
}

function normalizeError(error: unknown): AgentError {
  if (error instanceof AgentError) return error;
  return new AgentError(
    "internal_error",
    "Perfect AI hit an unexpected problem.",
    500,
    true,
  );
}

function errorResponse(error: AgentError) {
  return jsonResponse(
    {
      schema_version: CONTRACT_VERSION,
      error: {
        code: error.code,
        message: error.message,
        retryable: error.retryable,
      },
    },
    error.status,
  );
}

function jsonResponse(value: unknown, status = 200) {
  return new Response(JSON.stringify(value), {
    status,
    headers: {
      ...corsHeaders,
      "content-type": "application/json; charset=utf-8",
      "cache-control": "no-store",
    },
  });
}

function requiredObject(value: unknown, label: string): JsonObject {
  if (value == null || typeof value !== "object" || Array.isArray(value)) {
    throw new AgentError(
      "invalid_request",
      `${label} must be a JSON object.`,
      400,
    );
  }
  return { ...(value as JsonObject) };
}

function requiredObjectOrNull(value: unknown): JsonObject | null {
  return value != null && typeof value === "object" && !Array.isArray(value)
    ? value as JsonObject
    : null;
}

function requiredObjectOrEmpty(value: unknown): JsonObject {
  return value == null ? {} : requiredObject(value, "payload");
}

function requiredString(value: unknown, max: number, label: string): string {
  if (typeof value !== "string") {
    throw new AgentError(
      "invalid_request",
      `${label} must be text.`,
      400,
    );
  }
  const normalized = value.trim();
  if (normalized.length < 1 || normalized.length > max) {
    throw new AgentError(
      "invalid_request",
      `${label} must contain 1 to ${max} characters.`,
      400,
    );
  }
  return normalized;
}

function optionalString(value: unknown, max: number): string | null {
  if (value == null) return null;
  if (typeof value !== "string") {
    throw new AgentError("invalid_request", "Expected text.", 400);
  }
  const normalized = value.trim();
  if (normalized.length === 0) return null;
  if (normalized.length > max) {
    throw new AgentError("invalid_request", "Text is too long.", 400);
  }
  return normalized;
}


function requiredUuid(value: unknown, label: string): string {
  if (typeof value !== "string" || !isUuid(value)) {
    throw new AgentError(
      "invalid_request",
      `${label} must be a UUID.`,
      400,
    );
  }
  return value.toLowerCase();
}


function isUuid(value: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
    .test(value);
}

function requiredKind(value: unknown): AgentProposalItem["kind"] {
  if (
    value !== "one_off_task" && value !== "recurring_task" &&
    value !== "habit" && value !== "project"
  ) {
    throw new AgentError(
      "invalid_tool_proposal",
      "Perfect AI returned an unsupported planner item.",
      502,
      true,
    );
  }
  return value;
}

