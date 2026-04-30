type TaskManagerLike = {
  updateTask: (
    taskId: string,
    state: "completed" | "failed",
    artifacts?: Array<{ type: string; content: string }>,
    message?: string
  ) => unknown;
};

type StreamTaskLike = {
  id: string;
};

type StreamTaskResult = {
  artifacts: Array<{ type: string; content: string }>;
  metadata: Record<string, unknown>;
};

export async function executeA2ATaskWithState(
  tm: TaskManagerLike,
  task: StreamTaskLike,
  handler: (task: StreamTaskLike) => Promise<StreamTaskResult>
) {
  try {
    const result = await handler(task);
    tm.updateTask(task.id, "completed", result.artifacts);
    return result;
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    try {
      tm.updateTask(task.id, "failed", [{ type: "error", content: msg }], msg);
    } catch {
      // Task may already be terminal (e.g., cancelled). Preserve original error.
    }
    throw err;
  }
}
