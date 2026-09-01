import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";
import { Type } from "typebox";

type PlanStatus = "pending" | "in_progress" | "completed";

interface PlanItem {
  step: string;
  status: PlanStatus;
}

interface PlanDetails {
  explanation?: string;
  plan: PlanItem[];
}

const UpdatePlanSchema = Type.Object(
  {
    explanation: Type.Optional(
      Type.String({ description: "Optional explanation for why the plan changed." }),
    ),
    plan: Type.Array(
      Type.Object(
        {
          step: Type.String({ description: "A concise plan step." }),
          status: Type.Union([
            Type.Literal("pending"),
            Type.Literal("in_progress"),
            Type.Literal("completed"),
          ]),
        },
        { additionalProperties: false },
      ),
      { description: "The complete current plan, in execution order." },
    ),
  },
  { additionalProperties: false },
);

function renderPlan(plan: PlanItem[]): string {
  if (plan.length === 0) return "No plan";
  return plan
    .map((item) => {
      const marker = item.status === "completed" ? "[x]" : item.status === "in_progress" ? "[>]" : "[ ]";
      return `${marker} ${item.step}`;
    })
    .join("\n");
}

export default function codexWorkflow(pi: ExtensionAPI): void {
  let current: PlanDetails = { plan: [] };

  const restore = (ctx: ExtensionContext) => {
    current = { plan: [] };
    for (const entry of ctx.sessionManager.getBranch()) {
      if (entry.type !== "message") continue;
      const message = entry.message;
      if (message.role !== "toolResult" || message.toolName !== "update_plan") continue;
      const details = message.details as PlanDetails | undefined;
      if (details) current = details;
    }
  };

  pi.on("session_start", async (_event, ctx) => restore(ctx));
  pi.on("session_tree", async (_event, ctx) => restore(ctx));

  pi.registerTool({
    name: "update_plan",
    label: "Update Plan",
    description:
      "Update the session plan. Provide the complete plan. Exactly one step may be in_progress. Do not use this tool in Plan mode.",
    parameters: UpdatePlanSchema,
    async execute(_toolCallId, params) {
      const plan = params.plan.map((item) => ({ step: item.step.trim(), status: item.status }));
      if (plan.some((item) => item.step.length === 0)) {
        return { isError: true, content: [{ type: "text", text: "Plan steps must be non-empty." }] };
      }
      if (plan.filter((item) => item.status === "in_progress").length > 1) {
        return {
          isError: true,
          content: [{ type: "text", text: "At most one plan step may be in_progress." }],
        };
      }

      current = {
        plan,
        ...(params.explanation?.trim() ? { explanation: params.explanation.trim() } : {}),
      };
      return {
        content: [{ type: "text", text: "Plan updated" }],
        details: current,
      };
    },
    renderCall(_args, theme) {
      return new Text(theme.fg("toolTitle", theme.bold("update_plan")), 0, 0);
    },
    renderResult(result, { expanded }, theme) {
      const details = result.details as PlanDetails | undefined;
      if (!details) {
        const text = result.content.find((item) => item.type === "text");
        return new Text(text?.type === "text" ? text.text : "Plan update failed", 0, 0);
      }
      const completed = details.plan.filter((item) => item.status === "completed").length;
      const summary = theme.fg("success", `Plan updated (${completed}/${details.plan.length})`);
      return new Text(expanded ? `${summary}\n${renderPlan(details.plan)}` : summary, 0, 0);
    },
  });

  pi.registerCommand("codex-plan", {
    description: "Show the current Codex checklist",
    handler: async (_args, ctx) => {
      const plan = renderPlan(current.plan);
      if (ctx.hasUI) ctx.ui.notify(plan, "info");
    },
  });
}
